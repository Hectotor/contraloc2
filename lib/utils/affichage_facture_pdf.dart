import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'facture_pdf.dart';

class AffichageFacturePdf {
  static Future<void> genererEtAfficherFacturePdf({
    required BuildContext context,
    required String contratId,
    required Map<String, dynamic> contratData,
  }) async {
    try {
      // Récupérer les données de facture
      Map<String, dynamic> factureData = {
        'facturePrixLocation': contratData['facturePrixLocation'] ?? 0.0,
        'factureCaution': contratData['factureCaution'] ?? 0.0,
        'factureFraisNettoyageInterieur': contratData['factureFraisNettoyageInterieur'] ?? 0.0,
        'factureFraisNettoyageExterieur': contratData['factureFraisNettoyageExterieur'] ?? 0.0,
        'factureFraisCarburantManquant': contratData['factureFraisCarburantManquant'] ?? 0.0,
        'factureFraisRayuresDommages': contratData['factureFraisRayuresDommages'] ?? 0.0,
        'factureFraisAutre': contratData['factureFraisAutre'] ?? 0.0,
        'factureFraisKilometrique': contratData['factureFraisKilometrique'] ?? 0.0,
        'factureRemise': contratData['factureRemise'] ?? 0.0,
        'factureTotalFrais': contratData['factureTotalFrais'] ?? 0.0,
        'factureTypePaiement': contratData['factureTypePaiement'] ?? 'Carte bancaire',
        'dateFacture': contratData['dateFacture']?.toDate() ?? DateTime.now(),
        'factureId': contratData['factureId'] ?? '',
        'factureTVA': contratData['factureTVA'] ?? 'applicable',
      };

      // Générer le PDF avec FacturePdfGenerator
      final siretEntreprise = contratData['siretEntreprise'];
      final pdfPath = await FacturePdfGenerator.generateFacturePdf(
        data: contratData,
        factureData: factureData,
        logoUrl: contratData['logoUrl'] ?? '',
        nomEntreprise: contratData['nomEntreprise'] ?? '',
        adresse: contratData['adresseEntreprise'] ?? '',
        telephone: contratData['telephoneEntreprise'] ?? '',
        siret: siretEntreprise?.isNotEmpty == true ? siretEntreprise : '',
      );

      // Supprimer le fichier PDF existant s'il existe
      final appDir = await getApplicationDocumentsDirectory();
      final localPdfPath = '${appDir.path}/facture_${contratData['factureId']}.pdf';
      final localPdfFile = File(localPdfPath);
      if (await localPdfFile.exists()) {
        await localPdfFile.delete();
        print('Ancien PDF supprimé');
      }

      // Sauvegarder le nouveau PDF
      await File(pdfPath).copy(localPdfPath);
      print('Nouveau PDF sauvegardé: $localPdfPath');

      // Ouvrir le PDF
      await OpenFilex.open(localPdfPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération du PDF: $e')),
      );
    }
  }
}
