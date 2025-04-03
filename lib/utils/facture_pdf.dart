import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pdf_info_contact.dart';

/// Classe utilitaire pour générer des PDF de facture
class FacturePdfGenerator {
  /// Génère un PDF de facture avec un design professionnel
    static Future<String> generateFacturePdf({
    required Map<String, dynamic> data,
    required Map<String, dynamic> factureData,
    required String logoUrl,
    required String nomEntreprise,
    required String adresse,
    required String telephone,
    required String siret,

  }) async {
    // Initialiser le format de date français
    await initializeDateFormatting('fr_FR', null);
    final formatDate = DateFormat('dd/MM/yyyy', 'fr_FR');
    final formatMonetaire = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    
    // Créer un nouveau document PDF
    final pdf = pw.Document();

    // Charger les polices
    final font = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final boldData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
    final italicData = await rootBundle.load("assets/fonts/OpenSans-Italic.ttf");

    // Créer les objets de police
    final ttf = pw.Font.ttf(font);
    final boldFont = pw.Font.ttf(boldData);
    final italicFont = pw.Font.ttf(italicData);

    // Charger le logo
    pw.MemoryImage? logoImage = await _loadImageFromFirebaseStorage(logoUrl);

    // Récupérer les informations du véhicule
    final vehicule = '${data['marque']} ${data['modele']} (${data['immatriculation'] ?? ''})';
    
    // Récupérer les dates du contrat
    final dateDebut = _formatDate(data['dateDebut']);
    final dateFin = _formatDate(data['dateFinEffectif'] ?? data['dateFinTheorique']);
    
    // Récupérer les informations de kilométrage
    final kmDepart = data['kilometrageDepart'] ?? '0';
    final kmRetour = data['kilometrageRetour'] ?? '0';
    final kmParcourus = _calculerKmParcourus(kmDepart, kmRetour);
    
    // Récupérer les informations de la facture
    final numeroFacture = 'F-${data['id']?.substring(0, 8) ?? DateTime.now().millisecondsSinceEpoch.toString()}';
    final dateFacture = factureData['dateFacture'] is Timestamp 
        ? formatDate.format((factureData['dateFacture'] as Timestamp).toDate())
        : formatDate.format(DateTime.now());
    
    // Récupérer les montants
    final prixLocation = factureData['facturePrixLocation'] != null ? double.tryParse(factureData['facturePrixLocation'].toString()) ?? 0.0 : 0.0;
    final fraisNettoyageInt = factureData['factureFraisNettoyageInterieur'] ?? 0.0;
    final fraisNettoyageExt = factureData['factureFraisNettoyageExterieur'] ?? 0.0;
    final fraisCarburant = factureData['factureFraisCarburantManquant'] ?? 0.0;
    final fraisRayures = factureData['factureFraisRayuresDommages'] ?? 0.0;
    final fraisAutre = factureData['factureFraisAutre'] ?? 0.0;
    final fraisKilometrique = factureData['factureFraisKilometrique'] != null ? double.tryParse(factureData['factureFraisKilometrique'].toString()) ?? 0.0 : 0.0;
    final remise = factureData['factureRemise'] ?? 0.0;
    final caution = factureData['factureCaution'] ?? 0.0;
    
    // Calculer le total HT (sans TVA)
    final totalHT = prixLocation + fraisNettoyageInt + fraisNettoyageExt + 
                   fraisCarburant + fraisRayures + fraisAutre + fraisKilometrique - remise;
    
    // Calculer la TVA (20%)
    final tauxTVA = 0.20;
    final montantTVA = totalHT * tauxTVA;
    
    // Calculer le total TTC
    final totalTTC = totalHT + montantTVA;
    
    // Générer le PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30), 
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (pw.Context context) => [
          // En-tête avec logo et informations de l'entreprise
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Logo et informations de l'entreprise
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo
                  logoImage != null
                    ? pw.Container(
                        height: 60,  
                        width: 120,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    : pw.Container(),
                  pw.SizedBox(height: 4),
                  // Informations de l'entreprise sous le logo
                  pw.Text(nomEntreprise, style: pw.TextStyle(fontSize: 10, font: boldFont)),
                  pw.Text(adresse, style: pw.TextStyle(fontSize: 8, font: ttf)),
                  pw.Text('Tél: $telephone', style: pw.TextStyle(fontSize: 8, font: ttf)),
                  pw.Text('SIRET: $siret', style: pw.TextStyle(fontSize: 8, font: ttf)),
                ],
              ),
              
              // Informations de facture (numéro et date) à droite
              pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('FACTURE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('N° $numeroFacture', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text('Date: $dateFacture', style: pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 10),  
          
          // Informations de contact (utilisant PdfInfoContactWidget)
          PdfInfoContactWidget.build(
            nomEntreprise: nomEntreprise,
            adresse: adresse,
            telephone: telephone,
            siret: siret,
            clientData: data,
            boldFont: boldFont,
            ttf: ttf,
            logoImage: null, // Pas besoin de logo ici car on l'a déjà affiché en haut
          ),
          
          pw.SizedBox(height: 6),  // Réduction de l'espacement
          
          // Détails de la location
          pw.Container(
            padding: const pw.EdgeInsets.all(8), 
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4), 
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Détails de la location', 
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4), 
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Véhicule: $vehicule', style: pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2), 
                          pw.Text('Du: $dateDebut', style: pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2), 
                          pw.Text('Au: $dateFin', style: pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Km départ: $kmDepart', style: pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2), 
                          pw.Text('Km retour: $kmRetour', style: pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2), 
                          pw.Text('Km parcourus: $kmParcourus', style: pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 8),  
          
          // Détails de la facture
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              // En-tête du tableau
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableHeader('Description'),
                  _tableHeader('Montant'),
                ],
              ),
              // Lignes du tableau
              _tableRow(
                'Location du véhicule $vehicule',
                formatMonetaire.format(prixLocation),
              ),
              if (fraisKilometrique > 0)
                _tableRow(
                  'Frais kilométriques',
                  formatMonetaire.format(fraisKilometrique),
                ),
              if (fraisNettoyageInt > 0)
                _tableRow(
                  'Nettoyage intérieur',
                  formatMonetaire.format(fraisNettoyageInt),
                ),
              if (fraisNettoyageExt > 0)
                _tableRow(
                  'Nettoyage extérieur',
                  formatMonetaire.format(fraisNettoyageExt),
                ),
              if (fraisCarburant > 0)
                _tableRow(
                  'Frais de carburant manquant',
                  formatMonetaire.format(fraisCarburant),
                ),
              if (fraisRayures > 0)
                _tableRow(
                  'Frais pour rayures/dommages',
                  formatMonetaire.format(fraisRayures),
                ),
              if (fraisAutre > 0)
                _tableRow(
                  'Autres frais',
                  formatMonetaire.format(fraisAutre),
                ),
              if (caution > 0)
                _tableRow(
                  'Caution',
                  formatMonetaire.format(caution),
                ),
            ],
          ),
          
          pw.SizedBox(height: 6),  
          
          // Récapitulatif
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 180,
              child: pw.Column(
                children: [
                  _summaryRow('Total HT', formatMonetaire.format(totalHT)),
                  _summaryRow('TVA (20%)', formatMonetaire.format(montantTVA)),
                  if (remise > 0)
                    _summaryRow('Remise', formatMonetaire.format(remise), isPositive: true),
                  _summaryRow('Total TTC', formatMonetaire.format(totalTTC), isTotal: true),
                ],
              ),
            ),
          ),
          
          pw.SizedBox(height: 10),  
          
          // Informations de paiement
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4), 
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Informations de paiement', 
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                pw.Text('Mode de paiement: ${factureData['factureTypePaiement'] ?? "Carte bancaire"}', 
                  style: pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
    
    // Sauvegarder le PDF dans un fichier temporaire
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/facture_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  /// Charge une image depuis Firebase Storage
  static Future<pw.MemoryImage?> _loadImageFromFirebaseStorage(String logoUrl) async {
    // Vérifier si l'URL est vide
    if (logoUrl.isEmpty) {
      print("URL du logo vide, aucun logo ne sera affiché");
      return null;
    }
    
    // Vérifier si l'URL a un format valide
    if (!logoUrl.startsWith('https://')) {
      print("URL du logo invalide (ne commence pas par https://): $logoUrl");
      return null;
    }
    
    // Essayer d'abord via HTTP pour éviter l'erreur d'autorisation Firebase
    try {
      final response = await NetworkAssetBundle(Uri.parse(logoUrl)).load(logoUrl);
      final bytes = response.buffer.asUint8List();
      return pw.MemoryImage(bytes);
    } catch (httpError) {
      print("Erreur lors du chargement du logo via HTTP: $httpError");
      
      // Si HTTP échoue, essayer via Firebase Storage
      try {
        final Uint8List? logoBytes = await FirebaseStorage.instance
            .refFromURL(logoUrl)
            .getData();
        
        if (logoBytes != null) {
          return pw.MemoryImage(logoBytes);
        }
      } catch (e) {
        print("Erreur lors du chargement du logo via Firebase Storage: $e");
      }
    }
    
    print("Impossible de charger le logo: $logoUrl");
    return null;
  }

  /// Crée un en-tête de tableau
  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3), 
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Crée une ligne de tableau
  static pw.TableRow _tableRow(String description, String amount) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(3), 
          child: pw.Text(description, style: pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(3), 
          child: pw.Text(amount, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  /// Crée une ligne de récapitulatif
  static pw.Widget _summaryRow(String label, String amount, {bool isTotal = false, bool isPositive = false}) {
    return pw.Container(
      decoration: isTotal ? pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
        color: PdfColors.blue50,
      ) : null,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 9,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isPositive ? PdfColors.green700 : null,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  /// Formate une date Timestamp en chaîne lisible
  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Non spécifié';
    
    final formatDate = DateFormat('dd/MM/yyyy', 'fr_FR');
    
    if (dateValue is Timestamp) {
      return formatDate.format(dateValue.toDate());
    } else if (dateValue is DateTime) {
      return formatDate.format(dateValue);
    } else if (dateValue is String) {
      // Essayer de parser la date si c'est une chaîne
      try {
        // Format: "jour de la semaine jour mois à heure:minute"
        // Ex: "samedi 8 mars à 21:18"
        final regex = RegExp(r'.*?\s(\d+)\s+([\wé]+).*');
        final match = regex.firstMatch(dateValue);
        
        if (match != null) {
          final jour = int.parse(match.group(1)!);
          final mois = _convertirMois(match.group(2)!);
          
          if (mois != null) {
            // Utiliser l'année courante car elle n'est pas dans le format
            final maintenant = DateTime.now();
            return formatDate.format(DateTime(maintenant.year, mois, jour));
          }
        }
        
        return dateValue;
      } catch (e) {
        return dateValue;
      }
    }
    
    return dateValue.toString();
  }

  /// Convertit un nom de mois en français en numéro de mois
  static int? _convertirMois(String mois) {
    final moisMap = {
      'janvier': 1,
      'février': 2, 'fevrier': 2,
      'mars': 3,
      'avril': 4,
      'mai': 5,
      'juin': 6,
      'juillet': 7,
      'août': 8, 'aout': 8,
      'septembre': 9,
      'octobre': 10,
      'novembre': 11,
      'décembre': 12, 'decembre': 12,
    };
    
    return moisMap[mois.toLowerCase()];
  }

  /// Calcule le nombre de kilomètres parcourus
  static String _calculerKmParcourus(String kmDepart, String kmRetour) {
    try {
      final depart = int.tryParse(kmDepart) ?? 0;
      final retour = int.tryParse(kmRetour) ?? 0;
      
      if (retour >= depart) {
        return (retour - depart).toString();
      } else {
        return '0';
      }
    } catch (e) {
      return '0';
    }
  }
}
