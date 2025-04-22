import 'package:contraloc/MOBILE/widget/chargement.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/affichage_contrat_pdf.dart';
import '../CREATION DE CONTRAT/mail.dart';
import '../../services/auth_util.dart'; // Importer AuthUtil
import '../../utils/pdf_upload_utils.dart'; // Importer la fonction utilitaire

class RetourEnvoiePdf {
  static Future<void> genererEtEnvoyerPdfCloture({
    required BuildContext context,
    required Map<String, dynamic> contratData,
    required String contratId,
    required String dateFinEffectif,
    required String kilometrageRetour,
    required String commentaireRetour,
    required String pourcentageEssenceRetour,
    String? signatureRetourBase64,
    bool dialogueDejaAffiche = false,
  }) async {
    // Afficher un dialogue de chargement personnalisé seulement si un dialogue n'est pas déjà affiché
    if (!dialogueDejaAffiche) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Chargement(
            message: "Préparation du PDF de clôture...",
          );
        },
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Fermer le dialogue de chargement seulement si c'est cette méthode qui l'a ouvert
      if (!dialogueDejaAffiche && context.mounted) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté")),
      );
      return;
    }

    try {
      // Ajouter les informations de retour aux données du contrat
      Map<String, dynamic> contratDataComplet = Map.from(contratData);
      contratDataComplet['dateFinEffectif'] = dateFinEffectif;
      contratDataComplet['kilometrageRetour'] = kilometrageRetour;
      contratDataComplet['commentaireRetour'] = commentaireRetour;
      contratDataComplet['pourcentageEssenceRetour'] = pourcentageEssenceRetour;
      contratDataComplet['signatureRetour'] = signatureRetourBase64;
      
      print('=== DEBUG DONNEES RETOUR ===');
      print('dateFinEffectif: $dateFinEffectif');
      print('kilometrageRetour: $kilometrageRetour');
      print('commentaireRetour: $commentaireRetour');
      print('pourcentageEssenceRetour: $pourcentageEssenceRetour');
      print('signatureRetour: ${signatureRetourBase64 != null ? "Présente" : "Absente"}');
      print('=== FIN DEBUG DONNEES RETOUR ===');

      // === Génération et upload du PDF du contrat (clôture) ===
      final pdfUrl = await generateAndUploadPdfAndSaveUrl(
        generatePdf: () async => await AffichageContratPdf.genererEtAfficherContratPdf(
          data: contratDataComplet,
          afficherPdf: false,
          contratId: contratId,
          context: context,
          signatureRetourBase64: signatureRetourBase64,
        ),
        userId: (await AuthUtil.getAuthData())['adminId'],
        contratId: contratId,
        context: context,
        firestoreData: contratDataComplet,
      );
      if (pdfUrl != null) {
        print('✅ PDF clôture généré, uploadé et url enregistrée: $pdfUrl');
      } else {
        print('❌ Erreur lors de la génération, upload ou sauvegarde du PDF de clôture');
      }
      // === Fin génération/upload PDF ===

      // Fermer le dialogue de chargement seulement si c'est cette méthode qui l'a ouvert
      if (!dialogueDejaAffiche && context.mounted) {
        Navigator.pop(context);
      }
      
      // Afficher un message de succès qui s'affiche brièvement
      if (context.mounted) {
        final snackBar = SnackBar(
          content: const Text("Contrat clôturé et envoyé"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2), // Afficher pendant 2 secondes
        );
        
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }

      // Envoyer le PDF par email si un email est disponible
      if ((contratData['email'] ?? '').toString().isNotEmpty) {
        try {
          await EmailService.sendClotureEmailWithPdf(
            pdfPath: await AffichageContratPdf.genererEtAfficherContratPdf(
              data: contratDataComplet,
              afficherPdf: false,
              contratId: contratId,
              context: context,
              signatureRetourBase64: signatureRetourBase64,
            ),
            email: (contratData['email'] ?? '').toString(),
            marque: (contratData['marque'] ?? '').toString(),
            modele: (contratData['modele'] ?? '').toString(),
            immatriculation: (contratData['immatriculation'] ?? '').toString(),
            context: context,
            prenom: (contratData['prenom'] ?? '').toString(),
            nom: (contratData['nom'] ?? '').toString(),
            nomEntreprise: contratData['nomEntreprise'] ?? 'Contraloc',
            logoUrl: contratData['logoUrl'] ?? '',
            adresse: contratData['adresseEntreprise'] ?? '',
            telephone: contratData['telephoneEntreprise'] ?? '',
            kilometrageRetour: kilometrageRetour,
            dateFinEffectif: dateFinEffectif,
            commentaireRetour: commentaireRetour,
            nomCollaborateur: contratData['nomCollaborateur'],
            prenomCollaborateur: contratData['prenomCollaborateur'],
            sendCopyToAdmin: true,
          );

          // Afficher un message de succès après l'envoi du PDF
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Contrat clôturé"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Afficher un message d'erreur si l'envoi échoue
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Erreur lors de l'envoi du PDF : $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
          print("Erreur détaillée : $e");
          return;
        }
      } else {
        print("Aucun email client n'a été trouvé. Pas d'envoi de PDF.");
      }

      // Mise à jour du statut du contrat
      try {
        // Utiliser AuthUtil pour obtenir l'ID cible et construire le chemin
        final authData = await AuthUtil.getAuthData();
        final targetId = authData['adminId'] as String;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .update({
          'status': 'restitue',
          'dateRestitution': FieldValue.serverTimestamp(),
          'pdfClotureSent': true,
          'dateFinEffectif': dateFinEffectif,
          'kilometrageRetour': kilometrageRetour,
          'commentaireRetour': commentaireRetour,
          'pourcentageEssenceRetour': pourcentageEssenceRetour,
          'signatureRetour': signatureRetourBase64,
        });
      } catch (e) {
        print('Erreur lors de la mise à jour du statut du contrat: $e');
        throw Exception('Erreur lors de la mise à jour du statut du contrat: $e');
      }

    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur seulement si c'est cette méthode qui l'a ouvert
      if (!dialogueDejaAffiche && context.mounted) {
        Navigator.pop(context);
      }

      // Gestion des erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la génération du PDF : $e"),
          backgroundColor: Colors.red,
        ),
      );
      print("Erreur détaillée : $e");
    }
  }
}