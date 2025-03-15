import 'dart:io';
import 'package:ContraLoc/widget/chargement.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/pdf.dart';
import '../CREATION DE CONTRAT/mail.dart';
import '../../USERS/contrat_condition.dart';

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
      print('📋 Début de la génération du PDF de clôture');

      // Vérifier si l'utilisateur est un collaborateur
      print('👤 Vérification du rôle utilisateur...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      String targetUserId = user.uid;
      bool isCollaborateur = false;

      if (userData != null && userData['role'] == 'collaborateur') {
        isCollaborateur = true;
        final adminId = userData['adminId'];
        
        // Vérifier les permissions du collaborateur
        print('👥 Utilisateur collaborateur détecté, vérification des permissions...');
        final collabDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(user.uid)
            .get();

        final collabData = collabDoc.data();
        if (collabData != null && collabData['permissions'] != null) {
          if (collabData['permissions']['ecriture'] == true) {
            print('✅ Collaborateur avec permission d\'écriture');
            targetUserId = adminId;
          } else {
            print('❌ Collaborateur sans permission d\'écriture');
            throw Exception("Vous n'avez pas la permission de générer des PDF");
          }
        }
      } else {
        print('👤 Utilisateur admin');
      }

      // Récupérer les informations du client
      print('📄 Récupération des données client...');
      DocumentSnapshot clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('authentification')
          .doc(isCollaborateur ? user.uid : targetUserId)
          .get();

      // Récupérer la signature du contrat
      print('📄 Récupération des données du contrat...');
      DocumentSnapshot contratDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
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
      
      print('🏢 Informations entreprise récupérées:');
      print('   - Nom: $nomEntreprise');
      print('   - SIRET: ${siret.isNotEmpty ? siret : "Non renseigné"}');
      print('   - Logo: ${logoUrl.isNotEmpty ? "Présent" : "Non renseigné"}');

      // Récupérer la signature
      String? signatureBase64;
      if (contratDataComplete.containsKey('signature') && 
          contratDataComplete['signature'] is Map) {
        signatureBase64 = contratDataComplete['signature']['base64'];
      }

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

      print('✍️ État des signatures:');
      print('   - Signature aller: ${signatureAllerBase64 != null ? "Présente" : "Manquante"}');
      print('   - Signature retour: ${signatureRetourBase64 != null ? "Présente" : "Manquante"}');

      // Récupérer les données du véhicule
      print('🚗 Récupération des données du véhicule...');
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: contratData['immatriculation'])
          .get();

      final vehicleData = vehicleDoc.docs.isNotEmpty 
          ? vehicleDoc.docs.first.data() 
          : {};

      print('🚗 Données véhicule:');
      print('   - Immatriculation: ${contratData['immatriculation'] ?? "Non renseigné"}');
      print('   - Marque/Modèle: ${contratData['marque'] ?? ""} ${contratData['modele'] ?? ""}');

      // Générer le PDF de clôture
      print('📄 Génération du PDF en cours...');
      final pdfPath = await generatePdf(
        {
          'nom': (contratData['nom'] ?? '').toString(),
          'prenom': (contratData['prenom'] ?? '').toString(),
          'adresse': (contratData['adresse'] ?? '').toString(),
          'telephone': (contratData['telephone'] ?? '').toString(),
          'email': (contratData['email'] ?? '').toString(),
          'numeroPermis': (contratData['numeroPermis'] ?? '').toString(),
          'marque': (contratData['marque'] ?? '').toString(),
          'modele': (contratData['modele'] ?? '').toString(),
          'immatriculation': (contratData['immatriculation'] ?? '').toString(),
          'commentaire': (contratData['commentaire'] ?? '').toString(),
          'photos': contratData['photos'] ?? [],
          'signatureAller': signatureAllerBase64 ?? '',
          'signatureBase64': signatureBase64 ?? '',
          'signatureRetour': signatureRetourBase64 ?? '',
          
          // Nouveaux champs ajoutés
          'nettoyageInt': (contratData['nettoyageInt'] ?? '').toString(),
          'nettoyageExt': (contratData['nettoyageExt'] ?? '').toString(),
          'carburantManquant': (contratData['carburantManquant'] ?? '').toString(),
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
      );

      print('📄 PDF généré avec succès');

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Envoyer le PDF par email si un email est disponible
      if ((contratData['email'] ?? '').toString().isNotEmpty) {
        print('📧 Envoi du PDF par email à ${contratData['email']}...');
        await EmailService.sendEmailWithPdf(
          pdfPath: pdfPath,
          email: (contratData['email'] ?? '').toString(),
          marque: (contratData['marque'] ?? '').toString(),
          modele: (contratData['modele'] ?? '').toString(),
          context: context,
          prenom: (contratData['prenom'] ?? '').toString(),
          nom: (contratData['nom'] ?? '').toString(),
          nomEntreprise: nomEntreprise,
          adresse: adresse,
          telephone: telephone,
          logoUrl: logoUrl,
        );
        print('✅ PDF envoyé avec succès');
      } else {
        print("❌ Aucun email client n'a été trouvé. Pas d'envoi de PDF.");
      }

      print('✨ Processus de clôture terminé avec succès');

      // Mise à jour du statut du contrat
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('locations')
          .doc(contratId)
          .update({
        'status': 'restitue',
        'dateRestitution': FieldValue.serverTimestamp(),
        'pdfClotureSent': true,
      });

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