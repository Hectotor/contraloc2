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
        targetUserId = adminId;
        
        // Vérifier les permissions du collaborateur
        print('👥 Utilisateur collaborateur détecté, vérification des permissions...');
        
        // Récupérer l'ID du collaborateur depuis son document principal
        final collabId = userData['id'];
        print('   - Collab ID: $collabId');
        print('   - Admin ID: $adminId');

        // Vérifier les permissions du collaborateur - approche similaire à celle utilisée dans supp_contrat.dart
        DocumentSnapshot? collabDoc;
        Map<String, dynamic>? permissions;
        
        // 1. Essayer d'abord avec l'ID du collaborateur
        if (collabId != null) {
          print('🔍 Recherche du document collaborateur avec ID: $collabId');
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .where('id', isEqualTo: collabId)
              .limit(1)
              .get();
              
          if (querySnapshot.docs.isNotEmpty) {
            collabDoc = querySnapshot.docs.first;
            print('✅ Document collaborateur trouvé avec ID');
            
            // ignore: unnecessary_cast
            final collabData = collabDoc.data() as Map<String, dynamic>?;
            if (collabData != null && collabData['permissions'] != null) {
              permissions = collabData['permissions'];
            }
          } else {
            print('❌ Document collaborateur non trouvé avec ID');
          }
        }
        
        // 2. Si aucun document n'est trouvé avec l'ID, essayer avec l'UID
        if (permissions == null) {
          print('🔍 Recherche du document collaborateur avec UID: ${user.uid}');
          final collabDocByUid = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .doc(user.uid)
              .get();
              
          if (collabDocByUid.exists) {
            collabDoc = collabDocByUid;
            print('✅ Document collaborateur trouvé avec UID');
            
            // ignore: unnecessary_cast
            final collabData = collabDocByUid.data() as Map<String, dynamic>?;
            if (collabData != null && collabData['permissions'] != null) {
              permissions = collabData['permissions'];
            }
          } else {
            print('❌ Document collaborateur non trouvé même avec UID');
          }
        }
        
        // Vérifier les permissions
        if (permissions == null) {
          print('❌ Aucune permission trouvée pour le collaborateur');
          // Fermer le dialogue de chargement
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Permissions non trouvées pour générer le PDF"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        print('📋 Permissions collaborateur:');
        print('   - Lecture: ${permissions['lecture'] == true ? "✅" : "❌"}');
        print('   - Écriture: ${permissions['ecriture'] == true ? "✅" : "❌"}');
        
        // Vérifier si le collaborateur a la permission d'écriture
        if (!(permissions['ecriture'] == true)) {
          print('❌ Collaborateur sans permission d\'écriture');
          // Fermer le dialogue de chargement
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vous n'avez pas la permission de générer des PDF"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        print('✅ Collaborateur avec permission d\'écriture');
      } else {
        print('👤 Utilisateur admin');
      }

      // Récupérer les informations de l'entreprise depuis le document principal de l'admin
      print('📄 Récupération des données de l\'entreprise...');
      DocumentSnapshot adminDoc;
      try {
        adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .get();

        if (!adminDoc.exists) {
          print('⚠️ Document admin principal non trouvé, recherche dans authentification...');
          // Essayer de trouver les données dans la collection authentification
          final adminAuthDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('authentification')
              .doc(targetUserId)
              .get();
              
          if (adminAuthDoc.exists) {
            adminDoc = adminAuthDoc;
            print('✅ Document admin trouvé dans authentification');
          } else {
            print('❌ Document admin non trouvé même dans authentification');
            throw Exception('Données administrateur non trouvées');
          }
        }
      } catch (e) {
        print('❌ Erreur lors de la récupération des données admin: $e');
        
        // Créer un DocumentSnapshot factice
        adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc('default')
            .get();
            
        print('⚠️ Utilisation des données par défaut pour l\'entreprise');
      }

      final adminData = adminDoc.data() as Map<String, dynamic>? ?? {};

      // Récupérer les informations de l'entreprise
      String nomEntreprise = isCollaborateur ? adminData['nomEntreprise'] ?? 'Contraloc' : userData?['nomEntreprise'] ?? 'Contraloc';
      String adresse = isCollaborateur ? adminData['adresse'] ?? '' : userData?['adresse'] ?? '';
      String telephone = isCollaborateur ? adminData['telephone'] ?? '' : userData?['telephone'] ?? '';
      String logoUrl = isCollaborateur ? adminData['logoUrl'] ?? '' : userData?['logoUrl'] ?? '';
      String siret = isCollaborateur ? adminData['siret'] ?? '' : userData?['siret'] ?? '';
      
      print('🏢 Informations entreprise récupérées:');
      print('   - Nom: $nomEntreprise');
      print('   - SIRET: ${siret.isNotEmpty ? siret : "Non renseigné"}');
      print('   - Logo: ${logoUrl.isNotEmpty ? "Présent" : "Non renseigné"}');

      // Récupérer la signature du contrat
      print('📄 Récupération des données du contrat...');
      DocumentSnapshot contratDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('locations')
          .doc(contratId)
          .get();

      // Utiliser des valeurs par défaut sécurisées
      Map<String, dynamic> contratDataComplete = contratDoc.data() as Map<String, dynamic>? ?? {};

      String signatureBase64 = '';
      String? signatureAllerBase64;
      String? signatureRetourBase64;
      
      // Récupérer la signature
      if (contratDataComplete.containsKey('signature') && 
          contratDataComplete['signature'] is Map) {
        signatureBase64 = contratDataComplete['signature']['base64'] ?? '';
      }

      // Récupérer les signatures aller et retour
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

      // Récupérer les données du véhicule et du contrat
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

      // Fusionner les données du contrat avec les données du véhicule et de l'entreprise
      final mergedData = Map<String, dynamic>.from(contratData);
      mergedData.addAll({
        'typeCarburant': vehicleData['typeCarburant'] ?? contratData['typeCarburant'] ?? '',
        'boiteVitesses': vehicleData['boiteVitesses'] ?? contratData['boiteVitesses'] ?? '',
        'vin': vehicleData['vin'] ?? contratData['vin'] ?? '',
        'assuranceNom': vehicleData['assuranceNom'] ?? contratData['assuranceNom'] ?? '',
        'assuranceNumero': vehicleData['assuranceNumero'] ?? contratData['assuranceNumero'] ?? '',
        'franchise': vehicleData['franchise'] ?? contratData['franchise'] ?? '',
        'prixLocation': vehicleData['prixLocation'] ?? contratData['prixLocation'] ?? '',
        // Ajouter les informations de l'entreprise
        'nomEntreprise': nomEntreprise,
        'adresseEntreprise': adresse,
        'telephoneEntreprise': telephone,
        'siretEntreprise': siret,
        'logoUrl': logoUrl,
        // S'assurer que les informations client sont présentes
        'nom': contratData['nom'] ?? '',
        'prenom': contratData['prenom'] ?? '',
        'adresse': contratData['adresse'] ?? '',
        'telephone': contratData['telephone'] ?? '',
        'email': contratData['email'] ?? '',
        'numeroPermis': contratData['numeroPermis'] ?? '',
      });

      print('🚗 Données fusionnées:');
      print('   - Immatriculation: ${mergedData['immatriculation'] ?? "Non renseigné"}');
      print('   - Marque/Modèle: ${mergedData['marque'] ?? ""} ${mergedData['modele'] ?? ""}');
      print('   - Entreprise: ${mergedData['nomEntreprise']}');

      // Générer le PDF de clôture
      print('📄 Génération du PDF en cours...');
      final pdfPath = await generatePdf(
        mergedData,
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
        (mergedData['typeCarburant'] ?? '').toString(),
        (mergedData['boiteVitesses'] ?? '').toString(),
        (mergedData['vin'] ?? '').toString(),
        (mergedData['assuranceNom'] ?? '').toString(),
        (mergedData['assuranceNumero'] ?? '').toString(),
        (mergedData['franchise'] ?? '').toString(),
        (mergedData['kilometrageSupp'] ?? '').toString(),
        (mergedData['rayures'] ?? '').toString(),
        (mergedData['dateDebut'] ?? '').toString(),
        (mergedData['dateFinTheorique'] ?? '').toString(),
        dateFinEffectif,
        (mergedData['kilometrageDepart'] ?? '').toString(),
        (mergedData['kilometrageAutorise'] ?? '').toString(),
        (mergedData['pourcentageEssence'] ?? '0').toString(),
        (mergedData['typeLocation'] ?? '').toString(),
        (mergedData['prixLocation'] ?? '').toString(),
        condition: (mergedData['conditions'] ?? ContratModifier.defaultContract).toString(),
        signatureBase64: signatureBase64,
        signatureRetourBase64: signatureRetourBase64 ?? '',
        signatureAllerBase64: signatureAllerBase64 ?? '',
      );

      print('📄 PDF généré avec succès');

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Envoyer le PDF par email si un email est disponible
      if ((mergedData['email'] ?? '').toString().isNotEmpty) {
        print('📧 Envoi du PDF par email à ${mergedData['email']}...');
        try {
          await EmailService.sendEmailWithPdf(
            pdfPath: pdfPath,
            email: (mergedData['email'] ?? '').toString(),
            marque: (mergedData['marque'] ?? '').toString(),
            modele: (mergedData['modele'] ?? '').toString(),
            context: context,
            prenom: (mergedData['prenom'] ?? '').toString(),
            nom: (mergedData['nom'] ?? '').toString(),
            nomEntreprise: nomEntreprise,
            adresse: adresse,
            telephone: telephone,
            logoUrl: logoUrl,
          );
          print('✅ PDF envoyé avec succès');
        } catch (e) {
          print('⚠️ Erreur lors de l\'envoi du PDF par email: $e');
          // Ne pas bloquer le processus de clôture en cas d'erreur d'envoi d'email
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Erreur lors de l'envoi de l'email: $e"),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        print("ℹ️ Aucun email client n'a été trouvé. Pas d'envoi de PDF.");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aucune adresse email disponible pour l'envoi du PDF"),
              backgroundColor: Colors.orange,
            ),
          );
        }
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