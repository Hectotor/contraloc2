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
    // Récupérer le type de location du map data, ou utiliser la valeur passée en paramètre
    final String typeLocationValue = data['typeLocation'] ?? typeLocation;
    final String typeLocationFinal = typeLocationValue.isEmpty ? "" : typeLocationValue;

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
                fontSize: 15,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.black),
          pw.SizedBox(height: 2), // Réduit la taille de l'espace
          pw.Text('Informations du Véhicule:',
              style: pw.TextStyle(fontSize: 12, font: boldFont)),
          _buildVehiculeInfo(data, typeCarburant, boiteVitesses, assuranceNom,
              assuranceNumero, franchise, ttf),
          pw.SizedBox(height: 10), // Réduit la taille de l'espace
          pw.Text('Détails de la Location:',
              style: pw.TextStyle(fontSize: 12, font: boldFont)),
          _buildLocationDetails(
              data,
              dateDebut,
              dateFinTheorique,
              dateFinEffectifData,
              kilometrageDepart,
              kilometrageAutorise,
              kilometrageRetour,
              kilometrageSupp,
              typeLocationFinal,
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
                style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.Text('Modèle: ${data['modele']}',
                style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.Text('Immat.: ${data['immatriculation']}',
                style: pw.TextStyle(font: ttf, fontSize: 9)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Type carburant: $typeCarburant',
                style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.Text('Boîte: $boiteVitesses', style: pw.TextStyle(font: ttf, fontSize: 9)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Assurance: $assuranceNom', style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.Text('N°: $assuranceNumero', style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.Text('Franchise: $franchise €', style: pw.TextStyle(font: ttf, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLocationDetails(
      Map<String, dynamic> data,
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
      pw.Font ttf) {
    
    // Utiliser directement les valeurs passées en paramètre, qui sont déjà traitées
    final String cautionValue = data['caution'] ?? '';
    final String typeLocationValue = typeLocation;

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

    double calculateKmParcourus() {
      try {
        double kmDepart = double.parse(kilometrageDepart);
        double kmRetour = double.parse(kilometrageRetour);
        return kmRetour - kmDepart;
      } catch (e) {
        return 0.0; // Gestion des erreurs
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Informations générales
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
          ),
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Type de location: $typeLocationValue',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    )),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('', 
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Caution: $cautionValue €',
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 2),

        // Dates et durée
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Date de début: ${dateDebut.isEmpty ? '' : dateDebut}',
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Date de fin théorique: ${dateFinTheorique.isEmpty ? '' : dateFinTheorique}',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Date de fin effectif: ${dateFinEffectifData.isEmpty ? '' : dateFinEffectifData}',
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 2),

        // Kilométrage ligne 1
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
          ),
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Km de départ: $kilometrageDepart km',
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Km parcourus: ${calculateKmParcourus().toStringAsFixed(0)} km',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Km de retour: $kilometrageRetour km',
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 2),
        
        // Kilométrage ligne 2
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Distance autorisée: $kilometrageAutorise km',
                    style: pw.TextStyle(font: ttf, fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Prix Km supp: $kilometrageSupp €/km',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Coût total km supp: ${calculateKmSupp().toStringAsFixed(2)} €',
                      style: pw.TextStyle(font: ttf, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 2),

        // Coût de la location
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
          ),
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Montant journalier: ${typeLocationValue == "Gratuite" ? "0" : "$prixLocation"} €',
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Coût total théorique: ${typeLocationValue == "Gratuite" ? "0" : calculateCoutTotalTheorique(dateDebut, dateFinTheorique, prixLocation).toStringAsFixed(2)} €',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Coût total effectif: ${typeLocationValue == "Gratuite" ? "0" : calculateCoutTotalEffectif(dateDebut, dateFinEffectifData, prixLocation).toStringAsFixed(2)} €',
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 2),

        // État du véhicule
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Niveau d\'essence: $pourcentageEssence%',
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('', 
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 2),

        // Frais supplémentaires
        pw.Text('Frais supplémentaires (si applicable)',
            style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        
        // Frais supplémentaires ligne 1
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
          ),
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Frais de nettoyage intérieur: ${data['nettoyageInt'] ?? ''} €',
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('', 
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Frais de nettoyage extérieur: ${data['nettoyageExt'] ?? ''} €',
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 2),
        
        // Frais supplémentaires ligne 2
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Frais de carburant manquant: ${data['carburantManquant'] ?? ''} €',
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('', 
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Frais de rayures/dommages: $prixRayures €',
                      style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}