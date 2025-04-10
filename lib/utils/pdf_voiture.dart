import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/contrat_model.dart';

class PdfVoitureWidget {
  static pw.Widget build({
    required ContratModel contrat,
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
    required double? coutTotalTheorique,
    required double? coutTotal,
    required String accompte,
    required String selectedPaymentMethod,
    required pw.Font boldFont,
    required pw.Font ttf,
  }) {
    // Récupérer le type de location du map data, ou utiliser la valeur passée en paramètre
    final String typeLocationValue = contrat.typeLocation ?? typeLocation;
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
          _buildVehiculeInfo(contrat, typeCarburant, boiteVitesses, assuranceNom,
              assuranceNumero, franchise, ttf),
          pw.SizedBox(height: 10), // Réduit la taille de l'espace
          pw.Text('Détails de la Location:',
              style: pw.TextStyle(fontSize: 12, font: boldFont)),
          _buildLocationDetails(
              contrat,
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
              coutTotalTheorique,
              coutTotal,
              accompte,
              selectedPaymentMethod,
              ttf),
        ],
      ),
    );
  }

  static pw.Widget _buildVehiculeInfo(
      ContratModel contrat,
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
            pw.Text('Marque: ${contrat.marque}',
                style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.Text('Modèle: ${contrat.modele}',
                style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.Text('Immat.: ${contrat.immatriculation}',
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
      ContratModel contrat,
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
      double? coutTotalTheorique,
      double? coutTotal,
      String accompte,
      String selectedPaymentMethod,
      pw.Font ttf) {
    
    // Utiliser directement les valeurs passées en paramètre, qui sont déjà traitées
    final String cautionValue = contrat.caution ?? '';
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
        // Vérifier si les chaînes de date sont vides
        if (dateDebutStr.isEmpty || dateFinTheoriqueStr.isEmpty) {
          return 0.0;
        }
        
        // Vérifier si le prix de location est valide
        double prixLocation;
        try {
          prixLocation = double.parse(prixLocationStr);
        } catch (e) {
          print('Erreur lors du parsing du prix de location: $e');
          return 0.0;
        }
        
        // Essayer de parser les dates avec différents formats
        DateTime dateDebut;
        DateTime dateFinTheorique;
        
        try {
          // Essayer d'abord avec le format complet
          DateFormat formatterComplet = DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR');
          dateDebut = formatterComplet.parse(dateDebutStr);
          dateFinTheorique = formatterComplet.parse(dateFinTheoriqueStr);
        } catch (e) {
          try {
            // Essayer avec un format sans heure
            DateFormat formatterSansHeure = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
            dateDebut = formatterSansHeure.parse(dateDebutStr);
            dateFinTheorique = formatterSansHeure.parse(dateFinTheoriqueStr);
          } catch (e) {
            try {
              // Essayer avec un format ISO
              dateDebut = DateTime.parse(dateDebutStr);
              dateFinTheorique = DateTime.parse(dateFinTheoriqueStr);
            } catch (e) {
              print('Erreur lors du parsing des dates: $e');
              return 0.0;
            }
          }
        }
        
        // Récupérer le type de location
        // Utiliser directement la variable typeLocationValue définie dans la méthode build
        
        // Afficher les dates et le type de location pour le débogage
        print('DEBUG - Date début brute: ${dateDebut.toString()}');
        print('DEBUG - Date fin brute: ${dateFinTheorique.toString()}');
        print('DEBUG - Type de location: $typeLocationValue');
        
        // Forcer le calcul en mode journalier pour le test
        // Calculer la différence en heures pour plus de précision
        int differenceEnHeures = dateFinTheorique.difference(dateDebut).inHours;
        
        // Calculer le nombre de jours facturés
        int joursFactures = 1; // Le premier jour est toujours facturé
        
        // Ajouter un jour pour chaque tranche de 24h complète
        if (differenceEnHeures >= 24) {
          joursFactures = 1 + (differenceEnHeures / 24).floor();
        }
        
        // Ajouter des logs pour le débogage
        print('Tentative de parsing de la date: "$dateDebutStr"');
        print('Tentative de parsing de la date: "$dateFinTheoriqueStr"');
        print('Date début: $dateDebut, Date fin: $dateFinTheorique');
        print('Différence en heures: $differenceEnHeures');
        print('Jours facturés (tranches de 24h): $joursFactures');
        print('Prix location: $prixLocation, Coût total: ${prixLocation * joursFactures}');
        
        // Forcer le retour du calcul journalier pour le test
        return prixLocation * joursFactures;
      } catch (e) {
        print('Erreur lors du calcul du coût total théorique: $e');
        return 0.0;
      }
    }

    double calculateCoutTotalEffectif(String dateDebutStr, String dateFinEffectifStr, String prixLocationStr) {
      try {
        // Vérifier si les chaînes de date sont vides
        if (dateDebutStr.isEmpty || dateFinEffectifStr.isEmpty) {
          return 0.0;
        }
        
        // Vérifier si le prix de location est valide
        double prixLocation;
        try {
          prixLocation = double.parse(prixLocationStr);
        } catch (e) {
          print('Erreur lors du parsing du prix de location: $e');
          return 0.0;
        }
        
        // Essayer de parser les dates avec différents formats
        DateTime dateDebut;
        DateTime dateFinEffectif;
        
        try {
          // Essayer d'abord avec le format complet
          DateFormat formatterComplet = DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR');
          dateDebut = formatterComplet.parse(dateDebutStr);
          dateFinEffectif = formatterComplet.parse(dateFinEffectifStr);
        } catch (e) {
          try {
            // Essayer avec un format sans heure
            DateFormat formatterSansHeure = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
            dateDebut = formatterSansHeure.parse(dateDebutStr);
            dateFinEffectif = formatterSansHeure.parse(dateFinEffectifStr);
          } catch (e) {
            try {
              // Essayer avec un format ISO
              dateDebut = DateTime.parse(dateDebutStr);
              dateFinEffectif = DateTime.parse(dateFinEffectifStr);
            } catch (e) {
              print('Erreur lors du parsing des dates: $e');
              return 0.0;
            }
          }
        }
        
        // Récupérer le type de location
        // Utiliser directement la variable typeLocationValue définie dans la méthode build
        
        // Afficher les dates et le type de location pour le débogage
        print('DEBUG - Date début brute: ${dateDebut.toString()}');
        print('DEBUG - Date fin brute: ${dateFinEffectif.toString()}');
        print('DEBUG - Type de location: $typeLocationValue');
        
        // Forcer le calcul en mode journalier pour le test
        // Calculer la différence en heures pour plus de précision
        int differenceEnHeures = dateFinEffectif.difference(dateDebut).inHours;
        
        // Calculer le nombre de jours facturés
        int joursFactures = 1; // Le premier jour est toujours facturé
        
        // Ajouter un jour pour chaque tranche de 24h complète
        if (differenceEnHeures >= 24) {
          joursFactures = 1 + (differenceEnHeures / 24).floor();
        }
        
        // Ajouter des logs pour le débogage
        print('Tentative de parsing de la date: "$dateDebutStr"');
        print('Tentative de parsing de la date: "$dateFinEffectifStr"');
        print('Date début: $dateDebut, Date fin: $dateFinEffectif');
        print('Différence en heures: $differenceEnHeures');
        print('Jours facturés (tranches de 24h): $joursFactures');
        print('Prix location: $prixLocation, Coût total: ${prixLocation * joursFactures}');
        
        // Forcer le retour du calcul journalier pour le test
        return prixLocation * joursFactures;
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
                  child: accompte.isNotEmpty
                    ? pw.Column(
                        children: [
                          pw.Text('Accompte: $accompte €', 
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                          pw.Text('Méthode de paiement: $selectedPaymentMethod', 
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                        ],
                      )
                    : pw.SizedBox(),
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
                child: pw.Text('Niveau d\'essence départ: $pourcentageEssence%',
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
              ),
              if (contrat.pourcentageEssenceRetour != null )
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Niveau d\'essence retour: ${contrat.pourcentageEssenceRetour}%',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(),
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
                child: pw.Text('Frais de nettoyage intérieur: ${contrat.nettoyageInt ?? ''} €',
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
                  child: pw.Text('Frais de nettoyage extérieur: ${contrat.nettoyageExt ?? ''} €',
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
                child: pw.Text('Frais de carburant manquant: ${contrat.carburantManquant ?? ''} €',
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
                  child: pw.Text('Frais de rayures/dommages: ${contrat.prixRayures ?? ''} €',
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