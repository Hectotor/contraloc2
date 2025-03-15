import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart'; // Importer la bibliothèque Intl pour utiliser DateFormat

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
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('INFORMATIONS DU VÉHICULE',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: PdfColors.blue900,
            )),
        pw.SizedBox(height: 5),
        _buildVehiculeInfo(data, typeCarburant, boiteVitesses, assuranceNom,
            assuranceNumero, franchise, ttf),
        pw.SizedBox(height: 15),
        pw.Text('INFORMATIONS DE LOCATION',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: PdfColors.blue900,
            )),
        pw.SizedBox(height: 5),
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
                style: pw.TextStyle(font: ttf, fontSize: 10)),
            pw.Text('Modèle: ${data['modele']}',
                style: pw.TextStyle(font: ttf, fontSize: 10)),
            pw.Text('Immat.: ${data['immatriculation']}',
                style: pw.TextStyle(font: ttf, fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Type carburant: $typeCarburant',
                style: pw.TextStyle(font: ttf, fontSize: 10)),
            pw.Text('Boîte: $boiteVitesses', style: pw.TextStyle(font: ttf, fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Assurance: $assuranceNom', style: pw.TextStyle(font: ttf, fontSize: 10)),
            pw.Text('N°: $assuranceNumero', style: pw.TextStyle(font: ttf, fontSize: 10)),
            pw.Text('Franchise: $franchise €', style: pw.TextStyle(font: ttf, fontSize: 10)),
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
      String caution,
      pw.Font ttf) {
    double calculateKmSupp() {
      try {
        if (kilometrageRetour.isEmpty || kilometrageDepart.isEmpty || kilometrageAutorise.isEmpty || kilometrageSupp.isEmpty) {
          return 0.0;
        }
        
        double kmRetour = double.parse(kilometrageRetour.replaceAll(' ', ''));
        double kmDepart = double.parse(kilometrageDepart.replaceAll(' ', ''));
        double kmAutorise = double.parse(kilometrageAutorise.replaceAll(' ', ''));
        double prixKmSupp = double.parse(kilometrageSupp.replaceAll(' ', ''));
        
        double kmParcourus = kmRetour - kmDepart;
        double kmSupplementaires = kmParcourus > kmAutorise ? kmParcourus - kmAutorise : 0;
        
        return kmSupplementaires * prixKmSupp;
      } catch (e) {
        return 0.0;
      }
    }
    
    double calculateKmParcourus() {
      try {
        if (kilometrageRetour.isEmpty || kilometrageDepart.isEmpty) {
          return 0.0;
        }
        
        double kmRetour = double.parse(kilometrageRetour.replaceAll(' ', ''));
        double kmDepart = double.parse(kilometrageDepart.replaceAll(' ', ''));
        
        return kmRetour - kmDepart;
      } catch (e) {
        return 0.0;
      }
    }
    
    double calculateCoutTotalTheorique() {
      try {
        if (prixLocation.isEmpty || dateDebut.isEmpty || dateFinTheorique.isEmpty) {
          return 0.0;
        }
        
        // Convertir les dates en objets DateTime en gérant différents formats possibles
        DateTime debut;
        DateTime finTheorique;
        
        try {
          // Essayer le format ISO (yyyy-MM-dd)
          debut = DateTime.parse(dateDebut);
          finTheorique = DateTime.parse(dateFinTheorique);
        } catch (e) {
          try {
            // Essayer le format français (dd/MM/yyyy)
            DateFormat dateFormat = DateFormat("dd/MM/yyyy");
            debut = dateFormat.parse(dateDebut);
            finTheorique = dateFormat.parse(dateFinTheorique);
          } catch (e) {
            try {
              // Essayer le format avec jour de la semaine (ex: "samedi 15 mars 2025")
              // Extraire les parties numériques de la date
              RegExp regExp = RegExp(r'(\d+)\s+(\w+)\s+(\d+)');
              
              Match? matchDebut = regExp.firstMatch(dateDebut);
              Match? matchFin = regExp.firstMatch(dateFinTheorique);
              
              if (matchDebut != null && matchFin != null) {
                // Convertir le mois en numéro
                Map<String, String> moisEnNumero = {
                  'janvier': '01', 'février': '02', 'mars': '03', 'avril': '04',
                  'mai': '05', 'juin': '06', 'juillet': '07', 'août': '08',
                  'septembre': '09', 'octobre': '10', 'novembre': '11', 'décembre': '12'
                };
                
                String jourDebut = matchDebut.group(1) ?? '';
                String moisDebutStr = matchDebut.group(2) ?? '';
                String anneeDebut = matchDebut.group(3) ?? '';
                
                String jourFin = matchFin.group(1) ?? '';
                String moisFinStr = matchFin.group(2) ?? '';
                String anneeFin = matchFin.group(3) ?? '';
                
                String moisDebutNum = moisEnNumero[moisDebutStr.toLowerCase()] ?? '';
                String moisFinNum = moisEnNumero[moisFinStr.toLowerCase()] ?? '';
                
                if (jourDebut.isNotEmpty && moisDebutNum.isNotEmpty && anneeDebut.isNotEmpty &&
                    jourFin.isNotEmpty && moisFinNum.isNotEmpty && anneeFin.isNotEmpty) {
                  // Formater en yyyy-MM-dd pour le parsing
                  String dateDebutFormatee = '$anneeDebut-$moisDebutNum-${jourDebut.padLeft(2, '0')}';
                  String dateFinFormatee = '$anneeFin-$moisFinNum-${jourFin.padLeft(2, '0')}';
                  
                  debut = DateTime.parse(dateDebutFormatee);
                  finTheorique = DateTime.parse(dateFinFormatee);
                } else {
                  throw Exception('Format de date invalide');
                }
              } else {
                throw Exception('Format de date non reconnu');
              }
            } catch (e) {
              // Si aucun format ne fonctionne, utiliser dureeTheorique
              if (prixLocation.isEmpty || dureeTheorique <= 0) {
                return 0.0;
              }
              
              double prixJournalier = double.parse(prixLocation.replaceAll(' ', ''));
              return prixJournalier * dureeTheorique;
            }
          }
        }
        
        // Calculer la différence en jours
        int differenceEnJours = finTheorique.difference(debut).inDays;
        
        // Si la différence est négative ou nulle, utiliser dureeTheorique comme fallback
        if (differenceEnJours <= 0) {
          differenceEnJours = dureeTheorique;
        }
        
        double prixJournalier = double.parse(prixLocation.replaceAll(' ', ''));
        return prixJournalier * differenceEnJours;
      } catch (e) {
        // En cas d'erreur, utiliser dureeTheorique comme fallback
        try {
          if (prixLocation.isEmpty || dureeTheorique <= 0) {
            return 0.0;
          }
          
          double prixJournalier = double.parse(prixLocation.replaceAll(' ', ''));
          return prixJournalier * dureeTheorique;
        } catch (e) {
          return 0.0;
        }
      }
    }
    
    double calculateCoutTotalEffectif() {
      try {
        if (prixLocation.isEmpty || dateDebut.isEmpty || dateFinEffectifData.isEmpty) {
          return 0.0;
        }
        
        // Convertir les dates en objets DateTime en gérant différents formats possibles
        DateTime debut;
        DateTime finEffective;
        
        try {
          // Essayer le format ISO (yyyy-MM-dd)
          debut = DateTime.parse(dateDebut);
          finEffective = DateTime.parse(dateFinEffectifData);
        } catch (e) {
          try {
            // Essayer le format français (dd/MM/yyyy)
            DateFormat dateFormat = DateFormat("dd/MM/yyyy");
            debut = dateFormat.parse(dateDebut);
            finEffective = dateFormat.parse(dateFinEffectifData);
          } catch (e) {
            try {
              // Essayer le format avec jour de la semaine (ex: "samedi 15 mars 2025")
              // Extraire les parties numériques de la date
              RegExp regExp = RegExp(r'(\d+)\s+(\w+)\s+(\d+)');
              
              Match? matchDebut = regExp.firstMatch(dateDebut);
              Match? matchFin = regExp.firstMatch(dateFinEffectifData);
              
              if (matchDebut != null && matchFin != null) {
                // Convertir le mois en numéro
                Map<String, String> moisEnNumero = {
                  'janvier': '01', 'février': '02', 'mars': '03', 'avril': '04',
                  'mai': '05', 'juin': '06', 'juillet': '07', 'août': '08',
                  'septembre': '09', 'octobre': '10', 'novembre': '11', 'décembre': '12'
                };
                
                String jourDebut = matchDebut.group(1) ?? '';
                String moisDebutStr = matchDebut.group(2) ?? '';
                String anneeDebut = matchDebut.group(3) ?? '';
                
                String jourFin = matchFin.group(1) ?? '';
                String moisFinStr = matchFin.group(2) ?? '';
                String anneeFin = matchFin.group(3) ?? '';
                
                String moisDebutNum = moisEnNumero[moisDebutStr.toLowerCase()] ?? '';
                String moisFinNum = moisEnNumero[moisFinStr.toLowerCase()] ?? '';
                
                if (jourDebut.isNotEmpty && moisDebutNum.isNotEmpty && anneeDebut.isNotEmpty &&
                    jourFin.isNotEmpty && moisFinNum.isNotEmpty && anneeFin.isNotEmpty) {
                  // Formater en yyyy-MM-dd pour le parsing
                  String dateDebutFormatee = '$anneeDebut-$moisDebutNum-${jourDebut.padLeft(2, '0')}';
                  String dateFinFormatee = '$anneeFin-$moisFinNum-${jourFin.padLeft(2, '0')}';
                  
                  debut = DateTime.parse(dateDebutFormatee);
                  finEffective = DateTime.parse(dateFinFormatee);
                } else {
                  throw Exception('Format de date invalide');
                }
              } else {
                throw Exception('Format de date non reconnu');
              }
            } catch (e) {
              // Si aucun format ne fonctionne, utiliser dureeEffectif
              if (prixLocation.isEmpty || dureeEffectif <= 0) {
                return 0.0;
              }
              
              double prixJournalier = double.parse(prixLocation.replaceAll(' ', ''));
              return prixJournalier * dureeEffectif;
            }
          }
        }
        
        // Calculer la différence en jours
        int differenceEnJours = finEffective.difference(debut).inDays;
        
        // Si la différence est négative ou nulle, utiliser dureeEffectif comme fallback
        if (differenceEnJours <= 0) {
          differenceEnJours = dureeEffectif;
        }
        
        double prixJournalier = double.parse(prixLocation.replaceAll(' ', ''));
        return prixJournalier * differenceEnJours;
      } catch (e) {
        // En cas d'erreur, utiliser dureeEffectif comme fallback
        try {
          if (prixLocation.isEmpty || dureeEffectif <= 0) {
            return 0.0;
          }
          
          double prixJournalier = double.parse(prixLocation.replaceAll(' ', ''));
          return prixJournalier * dureeEffectif;
        } catch (e) {
          return 0.0;
        }
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
                child: pw.Text('Type de location: $typeLocation',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    )),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('', 
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Caution: $caution €',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),

        // Dates et durée
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Date de début: ${dateDebut.isEmpty ? '' : dateDebut}',
                    style: pw.TextStyle(font: ttf, fontSize: 10)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Date de fin théorique: ${dateFinTheorique.isEmpty ? '' : dateFinTheorique}',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Date de fin effectif: ${dateFinEffectifData.isEmpty ? '' : dateFinEffectifData}',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),

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
                child: pw.Text('Montant journalier: ${typeLocation == "Gratuite" ? "0" : "$prixLocation"} €',
                    style: pw.TextStyle(font: ttf, fontSize: 10)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Coût total théorique: ${typeLocation == "Gratuite" ? "0" : calculateCoutTotalTheorique().toStringAsFixed(2)} €',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Coût total effectif: ${typeLocation == "Gratuite" ? "0" : calculateCoutTotalEffectif().toStringAsFixed(2)} €',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),

        // Kilométrage ligne 1
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Km de départ: $kilometrageDepart km',
                    style: pw.TextStyle(font: ttf, fontSize: 10)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Km parcourus: ${calculateKmParcourus().toStringAsFixed(0)} km',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Km de retour: $kilometrageRetour km',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        
        // Kilométrage ligne 2
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
                child: pw.Text('Distance autorisée: $kilometrageAutorise km',
                    style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Prix Km supp: $kilometrageSupp €/km',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Coût total km supp: ${calculateKmSupp().toStringAsFixed(2)} €',
                      style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),

        // État du véhicule
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Niveau d\'essence: $pourcentageEssence%',
                    style: pw.TextStyle(font: ttf, fontSize: 10)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('', 
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),

        // Frais supplémentaires
        pw.Text('Frais supplémentaires (si applicable)',
            style: pw.TextStyle(font: ttf, fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        
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
                child: pw.Text('Frais de nettoyage intérieur: $nettoyageInt €',
                    style: pw.TextStyle(font: ttf, fontSize: 10)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('', 
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Frais de nettoyage extérieur: $nettoyageExt €',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        
        // Frais supplémentaires ligne 2
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('Frais de carburant manquant: $carburantManquant €',
                    style: pw.TextStyle(font: ttf, fontSize: 10)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('', 
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Frais de rayures/dommages: $prixRayures €',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}