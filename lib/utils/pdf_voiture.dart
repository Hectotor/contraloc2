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
    required String kilometrageAutorise,
    required String kilometrageRetour,
    required String kilometrageSupp,
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
              kilometrageAutorise,
              kilometrageRetour,
              kilometrageSupp,
              typeLocation,
              pourcentageEssence,
              dureeTheorique,
              dureeEffectif,
              prixLocation,
              prixRayures,
              coutTotalTheorique,
              coutTotal,
              data['nettoyageInt'] ?? '',
              data['nettoyageExt'] ?? '',
              data['carburantManquant'] ?? '',
              data['caution'] ?? '', // Ajouter ce paramètre
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
      String kilometrageAutorise,
      String kilometrageRetour,
      String kilometrageSupp,
      String typeLocation,
      String pourcentageEssence,
      int dureeTheorique,
      int dureeEffectif,
      String prixLocation,
      String prixRayures,
      double? coutTotalTheorique,
      double? coutTotal,
      String nettoyageInt,
      String nettoyageExt,
      String carburantManquant,
      String caution, // Ajouter ce paramètre
      pw.Font ttf) {
    double calculateKmSupp() {
      try {
        double kmDepart = double.parse(kilometrageDepart);
        double kmAutorise = double.parse(kilometrageAutorise);
        double kmRetour = double.parse(kilometrageRetour);
        double prixKmSupp = double.parse(kilometrageSupp);
        
        // Calculer la distance maximale autorisée
        double distanceMax = kmDepart + kmAutorise;
        
        // Si le kilométrage de retour dépasse la distance maximale, calculer le coût supplémentaire
        if (kmRetour > distanceMax) {
          return (kmRetour - distanceMax) * prixKmSupp;
        } else {
          return 0.0; // Pas de coût supplémentaire si dans la limite
        }
      } catch (e) {
        return 0.0; // Gestion des erreurs
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Dates and Duration section
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Date de début: ${dateDebut.isEmpty ? '' : dateDebut}',
                style: pw.TextStyle(font: ttf)),
                pw.SizedBox(height: 5),
            pw.Text('Date de fin théorique: ${dateFinTheorique.isEmpty ? '' : dateFinTheorique}',
                style: pw.TextStyle(font: ttf)),
                pw.SizedBox(height: 5),
            pw.Text('Date de fin effectif: ${dateFinEffectifData.isEmpty ? '' : dateFinEffectifData}',
                style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Durée théorique: $dureeTheorique jours',
                    style: pw.TextStyle(font: ttf)),
                pw.Text('Durée effective: $dureeEffectif jours',
                    style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.SizedBox(height: 5),
          ],
        ),

        // Location Type and Basic Info
        pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Type de location: $typeLocation',
                    style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                pw.Text('Caution: $caution €',
                    style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.SizedBox(height: 5),
          ],
        ),

        // Kilométrage section
        pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Km de départ: $kilometrageDepart',
                    style: pw.TextStyle(font: ttf)),
                pw.Text('Km autorisé: $kilometrageAutorise',
                    style: pw.TextStyle(font: ttf)),
                pw.Text('Km de retour: $kilometrageRetour',
                    style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                  pw.Text('Prix Km supp: $kilometrageSupp €/km',
                      style: pw.TextStyle(font: ttf)),
                  pw.Text('Coût total km supp: ${calculateKmSupp().toStringAsFixed(2)} €',
                      style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.SizedBox(height: 5),
          ],
        ),

        // État du véhicule
        pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Niveau d\'essence: $pourcentageEssence%',
                    style: pw.TextStyle(font: ttf)),
                pw.Text('Prix Rayures/élement: $prixRayures €',
                    style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.SizedBox(height: 5),
          ],
        ),

        // Frais additionnels
        pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Frais de nettoyage intérieur: $nettoyageInt €',
                    style: pw.TextStyle(font: ttf)),
                pw.Text('Frais de nettoyage extérieur: $nettoyageExt €',
                    style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text('Carburant manquant: $carburantManquant €',
                        style: pw.TextStyle(font: ttf)),
                  ],
                ),
                pw.SizedBox(height: 5),
              ],
            ),
          ],
        ),

        // Prix et coûts (conditionnelle)
        if (typeLocation != "Gratuite") ...[
          pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Montant journalier: $prixLocation €',
                      style: pw.TextStyle(font: ttf)),
                  pw.Text('Coût total théorique: ${coutTotalTheorique?.isNaN ?? true ? '0.0' : coutTotalTheorique.toString()} €',
                      style: pw.TextStyle(font: ttf)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text('Coût total effectif: ${coutTotal?.isNaN ?? true ? '0.0' : coutTotal.toString()} €',
                          style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}