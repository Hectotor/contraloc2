import 'package:ContraLoc/widget/chargement.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/affichage_contrat_pdf.dart';
import '../CREATION DE CONTRAT/mail.dart';
import '../../services/collaborateur_util.dart';

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
      if (context.mounted) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté")),
      );
      return;
    }

    try {
      // Générer le PDF sans l'afficher
      final pdfPath = await AffichageContratPdf.genererEtAfficherContratPdf(
        context: context,
        data: contratData,
        contratId: contratId,
        signatureRetourBase64: signatureRetourBase64,
        afficherPdf: false, // Ne pas afficher le PDF
      );

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
        
        // Afficher un message de succès qui s'affiche brièvement
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
            pdfPath: pdfPath,
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
        final status = await CollaborateurUtil.checkCollaborateurStatus();
        final userId = status['userId'];
        final isCollaborateur = status['isCollaborateur'] == true;
        final adminId = status['adminId'];

        if (isCollaborateur && adminId != null) {
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
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('locations')
              .doc(contratId)
              .set({
            'status': 'restitue',
            'dateRestitution': FieldValue.serverTimestamp(),
            'pdfClotureSent': true,
          }, SetOptions(merge: true));
        }
      } catch (e) {
        print('Erreur lors de la mise à jour du statut du contrat: $e');
        throw Exception('Erreur lors de la mise à jour du statut du contrat: $e');
      }

    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (context.mounted) {
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