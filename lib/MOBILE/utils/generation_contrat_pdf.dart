import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contrat_model.dart';
import '../widget/chargement.dart';
import '../utils/affichage_contrat_pdf.dart';
import '../widget/CREATION DE CONTRAT/mail.dart';
import '../widget/CREATION DE CONTRAT/popup_felicitation.dart';
import '../services/access_admin.dart';
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
    String? locationCasque,
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
    String? devisesLocation,
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

      // Récupérer les informations de l'entreprise via AccessAdmin
      print('Récupération des informations entreprise pour la génération du contrat PDF');
      final adminInfo = await AccessAdmin.getAdminInfo();
      
      if (adminInfo.isEmpty) {
        throw Exception(' Informations d\'entreprise non trouvées');
      }
      
      // Récupérer les données de l'utilisateur pour vérifier s'il est collaborateur
      final userDataDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      final String targetId;
      String? nomCollaborateurFinal = nomCollaborateur;
      String? prenomCollaborateurFinal = prenomCollaborateur;
      
      // Vérifier si le document existe avant d'accéder aux données
      if (userDataDoc.exists) {
        final userData = userDataDoc.data()!;
        final adminId = userData['adminId'];
        
        // Déterminer si l'utilisateur est un admin ou un collaborateur
        if (adminId == null) {
          // L'utilisateur est un admin, utiliser son propre ID
          targetId = user.uid;
          print(' Utilisateur administrateur détecté, utilisation de son propre ID: $targetId');
        } else {
          // L'utilisateur est un collaborateur, utiliser l'ID de son admin
          targetId = adminId;
          print(' Utilisateur collaborateur détecté, utilisation de l\'ID admin: $targetId');
        }

        // Récupérer les informations du collaborateur si ce n'est pas un admin
        if (adminId != null && (nomCollaborateur == null || prenomCollaborateur == null)) {
          try {
            print('Récupération des informations du collaborateur...');
            final collaborateurDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(GetOptions(source: Source.server));

            if (collaborateurDoc.exists) {
              final collaborateurData = collaborateurDoc.data()!;
              nomCollaborateurFinal = collaborateurData['nom'] ?? nomCollaborateur;
              prenomCollaborateurFinal = collaborateurData['prenom'] ?? prenomCollaborateur;
              print(' Informations collaborateur récupérées: $prenomCollaborateurFinal $nomCollaborateurFinal');
            }
          } catch (e) {
            print(' Erreur lors de la récupération des données collaborateur: $e');
          }
        }
      } else {
        // Document utilisateur non trouvé, mais nous avons déjà les informations d'entreprise via AccessAdmin
        print(' Document utilisateur non trouvé, utilisation de l\'ID utilisateur actuel');
        targetId = user.uid;
      }

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
        isCollaborateur: nomCollaborateurFinal != null,
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
        locationCasque: locationCasque,
        methodePaiement: methodePaiement,
        nomEntreprise: nomEntreprise,
        logoUrl: logoUrl,
        adresseEntreprise: adresseEntreprise,
        telephoneEntreprise: telephoneEntreprise,
        siretEntreprise: siretEntreprise,
        devisesLocation: devisesLocation,
        nomCollaborateur: nomCollaborateurFinal,
        prenomCollaborateur: prenomCollaborateurFinal,
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
      print('devisesLocation: ${contratModel.devisesLocation}');
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
      print('Admin ID: $targetId');
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
        throw Exception(' Erreur lors de la sauvegarde du contrat: $e');
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
          nomEntreprise: nomEntreprise,
          adresse: adresseEntreprise,
          telephone: telephoneEntreprise,
          logoUrl: logoUrl,
          sendCopyToAdmin: true,
          nomCollaborateur: nomCollaborateurFinal,
          prenomCollaborateur: prenomCollaborateurFinal,
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
