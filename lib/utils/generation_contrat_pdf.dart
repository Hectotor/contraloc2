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

      // Récupérer les données principales de l'utilisateur
      final userDataDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDataDoc.exists) {
        throw Exception('❌ Données utilisateur non trouvées');
      }

      final userData = userDataDoc.data()!;
      final adminId = userData['adminId'];
      
      if (adminId == null) {
        throw Exception('❌ ID administrateur non trouvé');
      }

      // Utiliser l'adminId comme cible
      final targetId = adminId;

      // Récupérer les données de l'admin
      final adminData = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .get(GetOptions(source: Source.server));

      if (!adminData.exists) {
        throw Exception('❌ Données administrateur non trouvées');
      }

      final adminDataMap = adminData.data()!;
      final nomEntreprise = adminDataMap['nomEntreprise'] ?? '';
      final logoUrl = adminDataMap['logoUrl'] ?? '';
      final adresseEntreprise = adminDataMap['adresse'] ?? '';
      final telephoneEntreprise = adminDataMap['telephone'] ?? '';
      final siretEntreprise = adminDataMap['siret'] ?? '';

      // Récupérer les informations du collaborateur
      final collaborateurData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      final collaborateurDataMap = collaborateurData.data()!;
      final nomCollaborateur = collaborateurDataMap['nom'] ?? '';
      final prenomCollaborateur = collaborateurDataMap['prenom'] ?? '';

      // Récupérer les conditions du contrat
      final conditionsData = await AccessCondition.getContractConditions();
      final conditionsText = conditionsData?['texte'] ?? ContratModifier.defaultContract;

      // Calculer le statut du contrat
      final now = DateTime.now();
      final dateDebutDateTime = DateTime.parse(dateDebut);
      final difference = dateDebutDateTime.difference(now).inDays;
      
      // Logs pour déboguer
      print('=== Calcul du statut ===');
      print('Date actuelle: $now');
      print('Date de début: $dateDebutDateTime');
      print('Différence en jours: $difference');
      
      final status = difference > 1 
          ? 'réservé'  // Si la date est dans plus de 24h
          : 'en_cours'; // Sinon, en_cours

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
        createdBy: user.uid,
        isCollaborateur: true,
        status: status,
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
      print('Admin ID: $adminId');
      print('Target ID: $targetId');
      print('Contrat ID: $contratId');
      print('=== Données du contrat ===');
      print(contratData);
      print('=== Structure de sauvegarde ===');
      print('Collection: users/$targetId/locations/$contratId');
      print('=== Fin des logs ===');

      try {
        // Sauvegarder dans la collection locations de l'admin
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .set(contratData, SetOptions(merge: true));

        print('=== Sauvegarde réussie ===');
        print('Sauvegardé dans: users/$targetId/locations/$contratId');

      } catch (e) {
        print('=== Erreur lors de la sauvegarde ===');
        print('Erreur: $e');
        print('Type de l\'erreur: ${e.runtimeType}');
        print('Message: ${e.toString()}');
        throw Exception('❌ Erreur lors de la sauvegarde du contrat: $e');
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
