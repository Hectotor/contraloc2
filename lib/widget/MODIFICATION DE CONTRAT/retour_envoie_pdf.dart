import 'dart:io';
import 'package:ContraLoc/widget/chargement.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/pdf.dart';
import '../CREATION DE CONTRAT/mail.dart';
import '../../USERS/contrat_condition.dart';
import '../../services/collaborateur_util.dart'; // Importer CollaborateurUtil

class RetourEnvoiePdf {
  static Future<void> genererEtEnvoyerPdfCloture({
    required BuildContext context,
    required Map<String, dynamic> contratData,
    required String contratId,
    required String dateFinEffectif,
    required String kilometrageRetour,
    required String commentaireRetour,
    required List<File> photosRetour,
    String? signatureRetourBase64,
  }) async {
    // Afficher un dialogue de chargement personnalisé
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Chargement(
          message: "Préparation du PDF de clôture...",
        );
      },
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Fermer le dialogue de chargement
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté")),
      );
      return;
    }

    try {
      // Récupérer les informations du client
      DocumentSnapshot clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      // Récupérer la signature du contrat
      DocumentSnapshot contratDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(contratId)
          .get();

      // Utiliser des valeurs par défaut sécurisées
      Map<String, dynamic> clientData = clientDoc.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> contratDataComplete = contratDoc.data() as Map<String, dynamic>? ?? {};

      String? clientEmail = clientData['email'] as String?;
      clientEmail ??= '';
      String nomEntreprise = (clientData['nomEntreprise'] ?? 'Contraloc').toString();
      String adresse = (clientData['adresse'] ?? '').toString();
      String telephone = (clientData['telephone'] ?? '').toString();
      String logoUrl = (clientData['logoUrl'] ?? '').toString();
      String siret = (clientData['siret'] ?? '').toString();
      
      // Récupérer la signature
      String? signatureBase64;
      if (contratDataComplete.containsKey('signature') && 
          contratDataComplete['signature'] is Map) {
        signatureBase64 = contratDataComplete['signature']['base64'];
      }

      // Log pour le débogage
      print('Signature récupérée : ${signatureBase64 != null ? 'Présente' : 'Absente'}');

      // Récupérer les signatures aller et retour
      String? signatureAllerBase64;
      String? signatureRetourBase64;
      
      // Récupérer la signature aller
      if (contratDoc.exists) {
        // Essayer de récupérer la signature aller
        if (contratDataComplete.containsKey('signature_aller') && 
            contratDataComplete['signature_aller'] is String) {
          signatureAllerBase64 = contratDataComplete['signature_aller'];
        }
        
        // Essayer de récupérer la signature de retour
        if (contratDataComplete.containsKey('signature_retour') && 
            contratDataComplete['signature_retour'] is String) {
          signatureRetourBase64 = contratDataComplete['signature_retour'];
        }
      }

      // Log pour le débogage
      print('📝 Signature aller récupérée : ${signatureAllerBase64 != null ? 'Présente (${signatureAllerBase64.length} caractères)' : 'Absente'}');
      print('📝 Signature retour récupérée : ${signatureRetourBase64 != null ? 'Présente (${signatureRetourBase64.length} caractères)' : 'Absente'}');

      // Récupérer les données du véhicule
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: contratData['immatriculation'])
          .get();

      final vehicleData = vehicleDoc.docs.isNotEmpty 
          ? vehicleDoc.docs.first.data() 
          : {};

      // Générer le PDF de clôture
      final pdfPath = await generatePdf(
        {
          'nom': (contratData['nom'] ?? '').toString(),
          'prenom': (contratData['prenom'] ?? '').toString(),
          'adresse': (contratData['adresse'] ?? '').toString(),
          'telephone': (contratData['telephone'] ?? '').toString(),
          'email': (contratData['email'] ?? '').toString(),
          'numeroPermis': (contratData['numeroPermis'] ?? '').toString(),
          'immatriculationVehiculeClient': (contratData['immatriculationVehiculeClient'] ?? '').toString(),
          'kilometrageVehiculeClient': (contratData['kilometrageVehiculeClient'] ?? '').toString(),
          'marque': (contratData['marque'] ?? '').toString(),
          'modele': (contratData['modele'] ?? '').toString(),
          'immatriculation': (contratData['immatriculation'] ?? '').toString(),
          'commentaire': (contratData['commentaire'] ?? '').toString(),
          'photos': contratData['photos'] ?? [],
          'signatureAller': signatureAllerBase64 ?? '',
          'signatureBase64': signatureBase64 ?? '',
          'signatureRetour': signatureRetourBase64 ?? '',
          'contratId': (contratData['contratId'] ?? '').toString(),
          
          // Nouveaux champs ajoutés
          'nettoyageInt': (contratData['nettoyageInt'] ?? '').toString(),
          'nettoyageExt': (contratData['nettoyageExt'] ?? '').toString(),
          'pourcentageEssenceRetour': (contratData['pourcentageEssenceRetour'] ?? '').toString(),
          'carburantManquant': (contratData['carburantManquant'] ?? '').toString(),
          'prixRayures': (contratData['prixRayures'] ?? '').toString(),
          'caution': (contratData['caution'] ?? '').toString(),
          
          // Champs supplémentaires
          'pourcentageEssence': (contratData['pourcentageEssence'] ?? '0').toString(),
          'typeLocation': (contratData['typeLocation'] ?? '').toString(),
          'conditions': (contratData['conditions'] ?? ContratModifier.defaultContract).toString(),
        },
        dateFinEffectif,
        kilometrageRetour,
        commentaireRetour,
        photosRetour,
        nomEntreprise,
        logoUrl,
        adresse,
        telephone,
        siret,
        commentaireRetour,
        (contratData['typeCarburant'] ?? '').toString(),
        (contratData['boiteVitesses'] ?? '').toString(),
        (contratData['vin'] ?? '').toString(),
        (contratData['assuranceNom'] ?? '').toString(),
        (contratData['assuranceNumero'] ?? '').toString(),
        (contratData['franchise'] ?? '').toString(),
        (contratData['kilometrageSupp'] ?? '').toString(),
        (contratData['rayures'] ?? '').toString(),
        (contratData['dateDebut'] ?? '').toString(),
        (contratData['dateFinTheorique'] ?? '').toString(),
        (contratData['contratId'] ?? '').toString(),
        dateFinEffectif,
        (contratData['kilometrageDepart'] ?? '').toString(),
        (contratData['kilometrageAutorise'] ?? '').toString(),
        (contratData['pourcentageEssence'] ?? '0').toString(),
        (contratData['typeLocation'] ?? '').toString(),
        (vehicleData['prixLocation'] ?? contratData['prixLocation'] ?? '').toString(),
        condition: (contratData['conditions'] ?? ContratModifier.defaultContract).toString(),
        signatureBase64: signatureBase64 ?? '',
        signatureRetourBase64: signatureRetourBase64 ?? '',
        signatureAllerBase64: signatureAllerBase64 ?? '',
        nomCollaborateur: contratData['nomCollaborateur'] != null && contratData['prenomCollaborateur'] != null
            ? '${contratData['prenomCollaborateur']} ${contratData['nomCollaborateur']}'
            : null,
      );

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Envoyer le PDF par email si un email est disponible
      if ((contratData['email'] ?? '').toString().isNotEmpty) {
        await EmailService.sendClotureEmailWithPdf(
          pdfPath: pdfPath,
          email: (contratData['email'] ?? '').toString(),
          marque: (contratData['marque'] ?? '').toString(),
          modele: (contratData['modele'] ?? '').toString(),
          immatriculation: (contratData['immatriculation'] ?? '').toString(),
          context: context,
          prenom: (contratData['prenom'] ?? '').toString(),
          nom: (contratData['nom'] ?? '').toString(),
          nomEntreprise: nomEntreprise,
          adresse: adresse,
          telephone: telephone,
          logoUrl: logoUrl,
          kilometrageRetour: kilometrageRetour,
          dateFinEffectif: dateFinEffectif,
          commentaireRetour: commentaireRetour,
          nomCollaborateur: contratData['nomCollaborateur'],
          prenomCollaborateur: contratData['prenomCollaborateur'],
        );
      } else {
        print("Aucun email client n'a été trouvé. Pas d'envoi de PDF.");
      }

      // Récupérer les informations du statut du collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      final isCollaborateur = status['isCollaborateur'] == true;
      final adminId = status['adminId'];

      print('🔄 Mise à jour du statut du contrat - userId: $userId, isCollaborateur: $isCollaborateur, adminId: $adminId');

      // Mise à jour du statut du contrat
      try {
        if (isCollaborateur && adminId != null) {
          // Si c'est un collaborateur, utiliser la collection de l'admin
          await CollaborateurUtil.updateDocument(
            collection: 'locations',
            docId: contratId,
            data: {
              'status': 'restitue',
              'dateRestitution': FieldValue.serverTimestamp(),
              'pdfClotureSent': true,
            },
            useAdminId: true,
          );
          print('✅ Statut du contrat mis à jour dans la collection de l\'admin: $adminId');
        } else {
          // Si c'est un admin, utiliser sa propre collection
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('locations')
              .doc(contratId)
              .update({
            'status': 'restitue',
            'dateRestitution': FieldValue.serverTimestamp(),
            'pdfClotureSent': true,
          });
          print('✅ Statut du contrat mis à jour dans la collection de l\'utilisateur: $userId');
        }
      } catch (e) {
        print('❌ Erreur lors de la mise à jour du statut du contrat: $e');
        throw Exception('Erreur lors de la mise à jour du statut du contrat: $e');
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contrat clôturé"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Gestion des erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'envoi du PDF : $e"),
          backgroundColor: Colors.red,
        ),
      );
      
      // Log de l'erreur pour le débogage
      print("Erreur détaillée : $e");
    }
  }
}