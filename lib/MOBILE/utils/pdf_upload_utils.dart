import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Génère un PDF localement puis l'uploade dans Firebase Storage au chemin users/<userId>/locations/<contratId>/contrat.pdf
/// et enregistre l'URL dans Firestore sous le champ 'pdfUrl'.
/// Retourne l'URL du PDF uploadé si succès, sinon null.
Future<String?> generateAndUploadPdfAndSaveUrl({
  required Future<String> Function() generatePdf,
  required String userId,
  required String contratId,
  required BuildContext context,
  required Map<String, dynamic> firestoreData,
}) async {
  try {
    // Générer le PDF localement
    final pdfPath = await generatePdf();
    final file = File(pdfPath);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(userId)
        .child('locations')
        .child(contratId)
        .child('contrat.pdf');
    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    // Mettre à jour le document Firestore avec l'URL du PDF
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('locations')
        .doc(contratId)
        .update({'pdfUrl': downloadUrl});

    debugPrint('✅ PDF généré, uploadé (users/$userId/locations/$contratId/contrat.pdf) et url enregistrée: $downloadUrl');
    return downloadUrl;
  } catch (e) {
    debugPrint('❌ Erreur lors de la génération, upload ou sauvegarde du PDF: $e');
    return null;
  }
}
