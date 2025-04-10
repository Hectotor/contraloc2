import 'package:ContraLoc/utils/affichage_contrat_pdf.dart';
import 'package:ContraLoc/widget/chargement.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/services/access_condition.dart';
import 'package:ContraLoc/models/contrat_model.dart';
import 'package:ContraLoc/USERS/contrat_condition.dart';
import '../widget/CREATION DE CONTRAT/mail.dart';
import '../widget/CREATION DE CONTRAT/popup_felicitation.dart';

class GenerationContratPdf {
  static Future<void> genererEtEnvoyerPdf({
    required BuildContext context,
    required String contratId,
    required String nom,
    required String prenom,
    required String adresse,
    required String telephone,
    required String email,
    required String numeroPermis,
    required String immatriculationVehiculeClient,
    required String kilometrageVehiculeClient,
    required String marque,
    required String modele,
    required String immatriculation,
    required String dateDebut,
    required String dateFinTheorique,
    required String kilometrageDepart,
    required String typeLocation,
    required int pourcentageEssence,
    required String commentaireAller,
    required List<String> photosUrls,
    required String signatureAller,
    required String vin,
    required String typeCarburant,
    required String boiteVitesses,
    required String assuranceNom,
    required String assuranceNumero,
    required String franchise,
    required String prixLocation,
    required String accompte,
    required String caution,
    required String nettoyageInt,
    required String nettoyageExt,
    required String pourcentageEssenceRetour,
    required String methodePaiement,
    String? permisRectoUrl,
    String? permisVersoUrl,
    String? photoVehiculeUrl,
  }) async {
    try {
      // Si les contrôleurs ne sont pas fournis, créer des instances par défaut
      // Récupérer les informations du loueur
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les données de l'utilisateur
      final authDataDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      if (!authDataDoc.exists) {
        throw Exception('Données authentification non trouvées');
      }

      final authData = authDataDoc.data()!;
      final isCollaborateur = authData['role'] == 'collaborateur';
      String targetId = user.uid;
      String? createdBy = user.uid;
      String? adminId = authData['adminId'];

      if (isCollaborateur && adminId != null) {
        targetId = adminId;
        createdBy = user.uid;
      }

      final loueurDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .get();

      if (!loueurDoc.exists) {
        throw Exception('Impossible de récupérer les informations du loueur');
      }

      final loueurData = loueurDoc.data()!;
      final nomEntreprise = loueurData['nomEntreprise'] ?? '';
      final logoUrl = loueurData['logoUrl'] ?? '';
      final adresseEntreprise = loueurData['adresse'] ?? '';
      final telephoneEntreprise = loueurData['telephone'] ?? '';
      final siretEntreprise = loueurData['siret'] ?? '';
      final nomCollaborateur = loueurData['nom'] ?? '';
      final prenomCollaborateur = loueurData['prenom'] ?? '';

      // Récupérer les conditions du contrat
      final conditionsData = await AccessCondition.getContractConditions();
      final conditionsText = conditionsData?['texte'] ?? ContratModifier.defaultContract;

      // Créer un contratModel avec les données fournies
      final contratModel = ContratModel(
        contratId: contratId,
        nom: nom,
        prenom: prenom,
        adresse: adresse,
        telephone: telephone,
        email: email,
        numeroPermis: numeroPermis,
        immatriculationVehiculeClient: immatriculationVehiculeClient,
        kilometrageVehiculeClient: kilometrageVehiculeClient,
        marque: marque,
        modele: modele,
        immatriculation: immatriculation,
        dateDebut: dateDebut,
        dateFinTheorique: dateFinTheorique,
        kilometrageDepart: kilometrageDepart,
        typeLocation: typeLocation,
        pourcentageEssence: pourcentageEssence,
        commentaireAller: commentaireAller,
        photosUrls: photosUrls,
        signatureAller: signatureAller,
        vin: vin,
        typeCarburant: typeCarburant,
        boiteVitesses: boiteVitesses,
        assuranceNom: assuranceNom,
        assuranceNumero: assuranceNumero,
        franchise: franchise,
        prixLocation: prixLocation,
        accompte: accompte,
        caution: caution,
        nettoyageInt: nettoyageInt,
        nettoyageExt: nettoyageExt,
        pourcentageEssenceRetour: pourcentageEssenceRetour,
        methodePaiement: methodePaiement,
        permisRectoUrl: permisRectoUrl,
        permisVersoUrl: permisVersoUrl,
        photoVehiculeUrl: photoVehiculeUrl,
        nomEntreprise: nomEntreprise,
        logoUrl: logoUrl,
        adresseEntreprise: adresseEntreprise,
        telephoneEntreprise: telephoneEntreprise,
        siretEntreprise: siretEntreprise,
        nomCollaborateur: nomCollaborateur,
        prenomCollaborateur: prenomCollaborateur,
        conditions: conditionsText,
        userId: user.uid,
        adminId: adminId,
        createdBy: createdBy,
        isCollaborateur: isCollaborateur,
        dateCreation: Timestamp.now(),
      );

      // Afficher le dialogue de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Chargement(message: 'Génération du contrat...');
        },
      );

      // Sauvegarder le contrat dans Firestore
      final contratData = contratModel.toFirestore();
      
      // Logs pour déboguer
      print('=== Début de la sauvegarde du contrat ===');
      print('User ID: ${user.uid}');
      print('Role: ${authData['role']}');
      print('Admin ID: $adminId');
      print('Target ID: $targetId');
      print('Contrat ID: $contratId');
      print('=== Données du contrat ===');
      print(contratData);
      print('=== Fin des logs ===');

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .set(contratData, SetOptions(merge: true));
      } catch (e) {
        print('Erreur lors de la sauvegarde: $e');
        throw Exception('Erreur lors de la sauvegarde du contrat: $e');
      }

      // Si un email est fourni, envoyer le PDF
      if (email.isNotEmpty) {
        await EmailService.sendEmailWithPdf(
          pdfPath: await AffichageContratPdf.genererEtAfficherContratPdf(
            context: context,
            data: contratData,
            contratId: contratId,
            afficherPdf: false,
          ),
          email: email,
          marque: marque,
          modele: modele,
          immatriculation: immatriculation,
          context: context,
          prenom: prenom,
          nom: nom,
          nomEntreprise: nomEntreprise,
          adresse: adresse,
          telephone: telephone,
          logoUrl: logoUrl,
          sendCopyToAdmin: true,
        );
      }

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher le popup de félicitation
      if (context.mounted) {
        await Popup.showSuccess(context, email: email);
      }

    } catch (e) {
      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher un message d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du contrat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
