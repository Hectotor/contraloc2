import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contrat_model.dart';
import '../widget/chargement.dart';
import '../utils/affichage_contrat_pdf.dart';
import '../widget/CREATION DE CONTRAT/mail.dart';
import '../widget/CREATION DE CONTRAT/popup_felicitation.dart';
import 'contract_utils.dart';

class GenerationContratPdf {
  static Future<void> genererEtEnvoyerPdf({
    required BuildContext context,
    required String contratId,
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? email,
    String? signatureAller,
    String? signatureRetour,
    String? photoVehiculeRetourUrl,
    String? vin,
    required String typeCarburant,
    required String boiteVitesses,
    String? assuranceNom,
    String? assuranceNumero,
    String? franchise,
    String? prixLocation,
    String? accompte,
    String? nettoyageInt,
    String? nettoyageExt,
    String? methodePaiement,
    String? numeroPermis,
    String? immatriculationVehiculeClient,
    String? kilometrageVehiculeClient,
    String? permisRecto,
    String? permisVerso,
    String? photoVehiculeUrl,
    String? dateDebut,
    String? dateFinTheorique,
    String? kilometrageDepart,
    String? typeLocation,
    int? pourcentageEssence,
    String? commentaireAller,
    List<String>? photosUrls,
    String? caution,
    String? carburantManquant,
    String? rayures,
    String? kilometrageAutorise,
    String? kilometrageSupp,
    String? nomEntreprise,
    String? logoUrl,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? siretEntreprise,
    String? nomCollaborateur,
    String? prenomCollaborateur,
    String? conditions,
    String? dateRetour,
    String? kilometrageRetour,
    String? marque,
    String? modele,
    String? immatriculation,
    String? pourcentageEssenceRetour,
    String? status,
    String? entrepriseClient,
    Timestamp? dateCreation,
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
      
      // Déterminer si l'utilisateur est un admin ou un collaborateur
      final String targetId;
      if (adminId == null) {
        // L'utilisateur est un admin, utiliser son propre ID
        targetId = user.uid;
      } else {
        // L'utilisateur est un collaborateur, utiliser l'ID de son admin
        targetId = adminId;
      }

      // Récupérer les données de l'admin
      final adminAuthDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('authentification')
          .doc(targetId)
          .get(GetOptions(source: Source.server));

      if (!adminAuthDoc.exists) {
        throw Exception('❌ Données administrateur non trouvées');
      }

      final adminDataMap = adminAuthDoc.data()!;
      final nomEntreprise = adminDataMap['nomEntreprise'] ?? 'Non défini';
      final logoUrl = adminDataMap['logoUrl'] ?? 'Non défini';
      final adresseEntreprise = adminDataMap['adresse'] ?? 'Non défini';
      final telephoneEntreprise = adminDataMap['telephone'] ?? 'Non défini';
      final siretEntreprise = adminDataMap['siret'] ?? 'Non défini';


      // Récupérer les informations du collaborateur
      final collaborateurData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      final collaborateurDataMap = collaborateurData.data()!;
      final nomCollaborateur = collaborateurDataMap['nom'] ?? '';
      final prenomCollaborateur = collaborateurDataMap['prenom'] ?? '';

      // Calculer le statut du contrat
      final status = ContractUtils.determineContractStatus(dateDebut);
      
      // Logs pour déboguer
      print('=== Calcul du statut ===');
      print('Date de début: $dateDebut');
      print('Statut déterminé: $status');

      // Créer le contratModel avec le statut calculé
      final contratModel = ContratModel(
        contratId: contratId,
        userId: user.uid,
        adminId: targetId,
        createdBy: user.uid,
        isCollaborateur: adminId != null,
        entrepriseClient: entrepriseClient,
        nom: nom,
        prenom: prenom,
        adresse: adresse,
        telephone: telephone,
        email: email,
        numeroPermis: numeroPermis,
        immatriculationVehiculeClient: immatriculationVehiculeClient,
        kilometrageVehiculeClient: kilometrageVehiculeClient,
        permisRectoUrl: permisRecto,
        permisVersoUrl: permisVerso,
        marque: marque,
        modele: modele,
        immatriculation: immatriculation,
        dateDebut: dateDebut,
        dateFinTheorique: dateFinTheorique,
        kilometrageDepart: kilometrageDepart,
        typeLocation: typeLocation,
        pourcentageEssence: pourcentageEssence ?? 50,
        commentaireAller: commentaireAller,
        photosUrls: photosUrls,
        signatureAller: signatureAller,
        vin: vin,
        typeCarburant: typeCarburant,
        boiteVitesses: boiteVitesses,
        assuranceNom: assuranceNom,
        assuranceNumero: assuranceNumero,
        kilometrageAutorise: kilometrageAutorise,
        kilometrageSupp: kilometrageSupp,
        carburantManquant: carburantManquant,
        rayures: rayures,
        franchise: franchise,
        prixLocation: prixLocation,
        accompte: accompte,
        caution: caution,
        nettoyageInt: nettoyageInt,
        nettoyageExt: nettoyageExt,
        methodePaiement: methodePaiement,
        nomEntreprise: nomEntreprise,
        logoUrl: logoUrl,
        adresseEntreprise: adresseEntreprise,
        telephoneEntreprise: telephoneEntreprise,
        siretEntreprise: siretEntreprise,
        nomCollaborateur: nomCollaborateur,
        prenomCollaborateur: prenomCollaborateur,
        conditions: conditions,
        dateRetour: dateRetour,
        signatureRetour: signatureRetour,
        kilometrageRetour: kilometrageRetour,
        pourcentageEssenceRetour: pourcentageEssenceRetour,
        status: status, // Utiliser le statut calculé
        dateCreation: Timestamp.now(),
      );

      // Vérifier si les données sont correctement passées au contratModel
      print('=== Vérification contratModel ===');
      print('nomEntreprise: ${contratModel.nomEntreprise}');
      print('logoUrl: ${contratModel.logoUrl}');
      print('adresseEntreprise: ${contratModel.adresseEntreprise}');
      print('telephoneEntreprise: ${contratModel.telephoneEntreprise}');
      print('siretEntreprise: ${contratModel.siretEntreprise}');
      print('nomCollaborateur: ${contratModel.nomCollaborateur}');
      print('prenomCollaborateur: ${contratModel.prenomCollaborateur}');
      print('conditions: ${contratModel.conditions}');
      print('=== Fin de la vérification contratModel ===');

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
      if (email != null && email.isNotEmpty) {
        await EmailService.sendEmailWithPdf(
          pdfPath: await AffichageContratPdf.genererEtAfficherContratPdf(
            data: contratData,
            afficherPdf: false,
            contratId: contratId, 
            context: context,
          ),
          context: context,
          email: email,
          marque: marque ?? '',
          modele: modele ?? '',
          immatriculation: immatriculation ?? '',
          prenom: prenom ?? '',
          nom: nom ?? '',
          nomEntreprise: nomEntreprise ?? '',
          adresse: adresseEntreprise,
          telephone: telephoneEntreprise,
          logoUrl: logoUrl ?? '',
          sendCopyToAdmin: true,
          nomCollaborateur: nomCollaborateur,
          prenomCollaborateur: prenomCollaborateur,
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
