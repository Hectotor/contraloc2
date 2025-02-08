import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/pdf.dart';
import '../CREATION DE CONTRAT/mail.dart';

class RetourEnvoiePdf {
  static Future<void> genererEtEnvoyerPdfCloture({
    required BuildContext context,
    required Map<String, dynamic> contratData,
    required String contratId,
    required String dateFinEffectif,
    required String kilometrageRetour,
    required String commentaireRetour,
    required List<File> photosRetour,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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

      String clientEmail = (clientData['email'] ?? '').toString();
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

      // Générer le PDF de clôture
      final pdfPath = await generatePdf(
        contratData,
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
        (contratData['pourcentageEssence'] ?? '').toString(),
        (contratData['typeLocation'] ?? '').toString(),
        (contratData['prixLocation'] ?? '').toString(),
        condition: 'Clôture de location',
        signatureBase64: signatureBase64, // Passer la signature
      );

      // Vérifier si un email est disponible avant d'envoyer
      if (clientEmail.isEmpty) {
        throw Exception("Aucun email client n'a été trouvé");
      }

      // Envoyer le PDF par email
      await EmailService.sendEmailWithPdf(
        pdfPath: pdfPath,
        email: clientEmail,
        marque: (contratData['marque'] ?? '').toString(),
        modele: (contratData['modele'] ?? '').toString(),
        context: context,
        prenom: (clientData['prenom'] ?? '').toString(),
        nom: (clientData['nom'] ?? '').toString(),
        nomEntreprise: nomEntreprise,
        adresse: adresse,
        telephone: telephone,
        logoUrl: logoUrl,
      );

      // Mise à jour du statut du contrat
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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
          content: Text("Contrat clôturé et PDF envoyé avec succès !"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
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
