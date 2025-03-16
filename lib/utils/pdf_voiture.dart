import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

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
      padding: const pw.EdgeInsets.all(10), // Réduit le padding
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(5), // Réduit le borderRadius
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Conditions de la Location:',
              style: pw.TextStyle(
                fontSize: 16,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.black),
          pw.SizedBox(height: 5), // Réduit la taille de l'espace
          pw.Text('Informations du Véhicule:',
              style: pw.TextStyle(fontSize: 14, font: boldFont)),
          _buildVehiculeInfo(data, typeCarburant, boiteVitesses, assuranceNom,
              assuranceNumero, franchise, ttf),
          pw.SizedBox(height: 10), // Réduit la taille de l'espace
          pw.Text('Détails de la Location:',
              style: pw.TextStyle(fontSize: 14, font: boldFont)),
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
              data['caution'] ?? '',
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

    double calculateCoutTotalTheorique(String dateDebutStr, String dateFinTheoriqueStr, String prixLocationStr) {
      try {
        DateFormat formatter = DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR');
        DateTime dateDebut = formatter.parse(dateDebutStr);
        DateTime dateFinTheorique = formatter.parse(dateFinTheoriqueStr);
        double prixLocation = double.parse(prixLocationStr);
        return (dateFinTheorique.difference(dateDebut).inDays) * prixLocation;
      } catch (e) {
        print('Erreur lors du calcul du coût total théorique: $e');
        return 0.0;
      }
    }

    double calculateCoutTotalEffectif(String dateDebutStr, String dateFinEffectifStr, String prixLocationStr) {
      try {
        DateFormat formatter = DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR');
        DateTime dateDebut = formatter.parse(dateDebutStr);
        DateTime dateFinEffectif = formatter.parse(dateFinEffectifStr);
        double prixLocation = double.parse(prixLocationStr);
        return (dateFinEffectif.difference(dateDebut).inDays) * prixLocation;
      } catch (e) {
        print('Erreur lors du calcul du coût total effectif: $e');
        return 0.0;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text('Type de location : $typeLocation',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Caution : $caution €',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(''),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text('Date de début : ${dateDebut.isEmpty ? '' : dateDebut}',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Date de fin théorique : ${dateFinTheorique.isEmpty ? '' : dateFinTheorique}',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Date de fin effective : ${dateFinEffectifData.isEmpty ? '' : dateFinEffectifData}',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text('Montant journalier : ${typeLocation == 'Gratuite' ? '00.00' : '$prixLocation €'}',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Coût total théorique : ${calculateCoutTotalTheorique(dateDebut, dateFinTheorique, prixLocation).toStringAsFixed(2) ?? '00.00'} €',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Coût total effectif : ${calculateCoutTotalEffectif(dateDebut, dateFinEffectifData, prixLocation).toStringAsFixed(2) ?? '00.00'} €',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text('Km de départ : $kilometrageDepart km',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Km de retour : $kilometrageRetour km',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Distance autorisée : $kilometrageAutorise km',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text('Prix du km supplémentaire : $kilometrageSupp €/km',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Coût total km supp : ${calculateKmSupp().toStringAsFixed(2)} €',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Niveau d\'essence : $pourcentageEssence %',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Text('Frais supplémentaires (si applicable)',
            style: pw.TextStyle(font: ttf, fontSize: 10)),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text('Frais de nettoyage intérieur : ${nettoyageInt.isEmpty ? '0.00' : nettoyageInt} €',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Frais de nettoyage extérieur : ${nettoyageExt.isEmpty ? '0.00' : nettoyageExt} €',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Carburant manquant : ${carburantManquant.isEmpty ? '0.00' : carburantManquant} €',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text('Prix des rayures/dommages : $prixRayures €',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
            ),
          ],
        ),
      ],
    );
  }
}