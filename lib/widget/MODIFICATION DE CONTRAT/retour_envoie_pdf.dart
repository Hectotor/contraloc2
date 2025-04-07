import 'dart:io';
import 'package:ContraLoc/widget/chargement.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/pdf.dart';
import '../CREATION DE CONTRAT/mail.dart';
import '../../services/collaborateur_util.dart'; // Importer CollaborateurUtil
import '../../models/contrat_model.dart'; // Importer ContratModel

class RetourEnvoiePdf {
  static Future<void> genererEtEnvoyerPdfCloture({
    required BuildContext context,
    required Map<String, dynamic> contratData,
    required String contratId,
    required String dateFinEffectif,
    required String kilometrageRetour,
    required String commentaireRetour,
    required String pourcentageEssenceRetour,
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
      // Créer un contrat mis à jour avec les nouvelles données
      final contratMisAJour = ContratModel(
        contratId: contratId,
        userId: user.uid,
        dateRetour: dateFinEffectif,
        kilometrageRetour: kilometrageRetour,
        pourcentageEssenceRetour: int.parse(pourcentageEssenceRetour),
        signatureRetour: signatureRetourBase64,
        commentaireRetour: commentaireRetour, // Utiliser le champ commentaireRetour
      );

      // Générer le PDF de clôture en utilisant l'objet ContratModel
      final pdfPath = await generatePdf(
        contratMisAJour,
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
          nomEntreprise: contratData['nomEntreprise'] ?? 'Contraloc',
          logoUrl: contratData['logoUrl'] ?? '',
          adresse: contratData['adresseEntreprise'] ?? '',
          telephone: contratData['telephoneEntreprise'] ?? '',
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