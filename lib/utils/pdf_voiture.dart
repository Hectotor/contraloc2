import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfVoitureWidget {
  static pw.Widget build({
    required Map<String, dynamic> data,
    required String typeCarburant,
    required String boiteVitesses,
    required String assuranceNom,
    required String assuranceNumero,
    required String franchise,
    required String dateDebut,
    required String dateFinTheorique,
    required String dateFinEffectifData,
    required String kilometrageDepart,
    required String kilometrageRetour,
    required String typeLocation,
    required String pourcentageEssence,
    required int dureeTheorique,
    required int dureeEffectif,
    required String prixLocation,
    required String prixRayures,
    required double? coutTotalTheorique,
    required double? coutTotal,
    required pw.Font boldFont,
    required pw.Font ttf,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Conditions de la Location:',
              style: pw.TextStyle(
                fontSize: 18,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.black),
          pw.SizedBox(height: 10),
          pw.Text('Informations du Véhicule:',
              style: pw.TextStyle(fontSize: 16, font: boldFont)),
          _buildVehiculeInfo(data, typeCarburant, boiteVitesses, assuranceNom,
              assuranceNumero, franchise, ttf),
          pw.SizedBox(height: 15),
          pw.Text('Détails de la Location:',
              style: pw.TextStyle(fontSize: 16, font: boldFont)),
          _buildLocationDetails(
              dateDebut,
              dateFinTheorique,
              dateFinEffectifData,
              kilometrageDepart,
              kilometrageRetour,
              typeLocation,
              pourcentageEssence,
              dureeTheorique,
              dureeEffectif,
              prixLocation,
              prixRayures,
              coutTotalTheorique,
              coutTotal,
              ttf),
        ],
      ),
    );
  }

  static pw.Widget _buildVehiculeInfo(
      Map<String, dynamic> data,
      String typeCarburant,
      String boiteVitesses,
      String assuranceNom,
      String assuranceNumero,
      String franchise,
      pw.Font ttf) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Marque: ${data['marque']}',
                style: pw.TextStyle(font: ttf)),
            pw.Text('Modèle: ${data['modele']}',
                style: pw.TextStyle(font: ttf)),
            pw.Text('Immat.: ${data['immatriculation']}',
                style: pw.TextStyle(font: ttf)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Type carburant: $typeCarburant',
                style: pw.TextStyle(font: ttf)),
            pw.Text('Boîte: $boiteVitesses', style: pw.TextStyle(font: ttf)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Assurance: $assuranceNom', style: pw.TextStyle(font: ttf)),
            pw.Text('N°: $assuranceNumero', style: pw.TextStyle(font: ttf)),
            pw.Text('Franchise: $franchise €', style: pw.TextStyle(font: ttf)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLocationDetails(
      String dateDebut,
      String dateFinTheorique,
      String dateFinEffectifData,
      String kilometrageDepart,
      String kilometrageRetour,
      String typeLocation,
      String pourcentageEssence,
      int dureeTheorique,
      int dureeEffectif,
      String prixLocation,
      String prixRayures,
      double? coutTotalTheorique,
      double? coutTotal,
      pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start, // Ensure left alignment
      children: [
        pw.Text('Date de début: ${dateDebut.isEmpty ? '' : dateDebut}',
            style: pw.TextStyle(font: ttf)),
        pw.Text(
            'Date de fin théorique: ${dateFinTheorique.isEmpty ? '' : dateFinTheorique}',
            style: pw.TextStyle(font: ttf)),
        pw.Text(
            'Date de fin effectif: ${dateFinEffectifData.isEmpty ? '' : dateFinEffectifData}',
            style: pw.TextStyle(font: ttf)),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Kilométrage de départ: $kilometrageDepart',
                style: pw.TextStyle(font: ttf)),
            pw.Text('Kilométrage de retour: $kilometrageRetour',
                style: pw.TextStyle(font: ttf)),
            pw.Text('Niveau d\'essence: $pourcentageEssence%',
                style: pw.TextStyle(font: ttf)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Type de location: $typeLocation',
                style: pw.TextStyle(font: ttf)),
            pw.Text('Prix Rayures/élement: $prixRayures €',
                style: pw.TextStyle(font: ttf)), // Added line
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Durée théorique: $dureeTheorique jours',
                style: pw.TextStyle(font: ttf)),
            pw.Text('Durée effective: $dureeEffectif jours',
                style: pw.TextStyle(font: ttf)),
          ],
        ),
        if (typeLocation != "Gratuite") ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Montant journalier: $prixLocation €',
                  style: pw.TextStyle(font: ttf)),
              pw.Text(
                  'Coût total théorique: ${coutTotalTheorique?.isNaN ?? true ? '0.0' : coutTotalTheorique.toString()} €',
                  style: pw.TextStyle(font: ttf)),
              pw.Text(
                  'Coût effectif: ${coutTotal?.isNaN ?? true ? '0.0' : coutTotal.toString()} €',
                  style: pw.TextStyle(font: ttf)),
            ],
          ),
        ],
      ],
    );
  }
}
