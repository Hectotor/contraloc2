import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
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
        siret: siretEntreprise?.isNotEmpty == true ? siretEntreprise : null,
      );

      // Ouvrir le PDF
      await OpenFilex.open(pdfPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération du PDF: $e')),
      );
    }
  }
}
