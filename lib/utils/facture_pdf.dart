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

/// Classe utilitaire pour générer des PDF de facture
class FacturePdfGenerator {
  /// Génère un PDF de facture avec un design professionnel
  /// 
  /// Paramètres:
  /// - data: Les données du contrat
  /// - factureData: Les données spécifiques à la facture
  /// - logoUrl: L'URL du logo de l'entreprise
  /// - nomEntreprise: Le nom de l'entreprise
  /// - adresse: L'adresse de l'entreprise
  /// - telephone: Le numéro de téléphone de l'entreprise
  /// - siret: Le numéro SIRET de l'entreprise
  /// - iban: L'IBAN de l'entreprise (optionnel)
  /// - bic: Le BIC de l'entreprise (optionnel)
  static Future<String> generateFacturePdf({
    required Map<String, dynamic> data,
    required Map<String, dynamic> factureData,
    required String logoUrl,
    required String nomEntreprise,
    required String adresse,
    required String telephone,
    required String siret,
    String? iban,
    String? bic,
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

    // Récupérer les informations du client
    final nomClient = '${data['prenom']} ${data['nom']}';
    final adresseClient = data['adresse'] ?? '';
    final emailClient = data['email'] ?? '';
    final telephoneClient = data['telephone'] ?? '';

    // Récupérer les informations du véhicule
    final vehicule = '${data['marque']} ${data['modele']}';
    final immatriculation = data['immatriculation'] ?? '';
    
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
    final prixLocation = factureData['facturePrixLocation'] ?? 0.0;
    final fraisNettoyageInt = factureData['factureFraisNettoyageInterieur'] ?? 0.0;
    final fraisNettoyageExt = factureData['factureFraisNettoyageExterieur'] ?? 0.0;
    final fraisCarburant = factureData['factureFraisCarburantManquant'] ?? 0.0;
    final fraisRayures = factureData['factureFraisRayuresDommages'] ?? 0.0;
    final fraisAutre = factureData['factureFraisAutre'] ?? 0.0;
    final remise = factureData['factureRemise'] ?? 0.0;
    final caution = factureData['factureCaution'] ?? 0.0;
    
    // Calculer le total HT (sans TVA)
    final totalHT = prixLocation + fraisNettoyageInt + fraisNettoyageExt + 
                   fraisCarburant + fraisRayures + fraisAutre - remise;
    
    // Calculer la TVA (20%)
    final tauxTVA = 0.20;
    final montantTVA = totalHT * tauxTVA;
    
    // Calculer le total TTC
    final totalTTC = totalHT + montantTVA;
    
    // Générer le PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldFont,
          italic: italicFont,
        ),
        header: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Logo et informations de l'entreprise
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Image(logoImage, width: 120),
                  pw.SizedBox(height: 5),
                  pw.Text(nomEntreprise, style: pw.TextStyle(font: boldFont, fontSize: 14)),
                  pw.Text(adresse, style: pw.TextStyle(fontSize: 10)),
                  pw.Text('Tél: $telephone', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('SIRET: $siret', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              // Informations de la facture
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue800),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('FACTURE', style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.blue800)),
                    pw.SizedBox(height: 5),
                    pw.Text('N° $numeroFacture', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('Date: $dateFacture', style: pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 5),
              pw.Text(
                '$nomEntreprise - $adresse - SIRET: $siret',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
              if (iban != null && bic != null)
                pw.Text(
                  'IBAN: $iban - BIC: $bic',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Page ${context.pageNumber} sur ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
        build: (pw.Context context) => [
          // Informations du client
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FACTURER À:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                        pw.SizedBox(height: 5),
                        pw.Text(nomClient, style: pw.TextStyle(fontSize: 11)),
                        pw.Text(adresseClient, style: pw.TextStyle(fontSize: 10)),
                        if (emailClient.isNotEmpty) pw.Text('Email: $emailClient', style: pw.TextStyle(fontSize: 10)),
                        if (telephoneClient.isNotEmpty) pw.Text('Tél: $telephoneClient', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INFORMATIONS DE LOCATION:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                        pw.SizedBox(height: 5),
                        pw.Text('Véhicule: $vehicule', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('Immatriculation: $immatriculation', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('Période: du $dateDebut au $dateFin', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('Kilométrage: $kmDepart km → $kmRetour km ($kmParcourus km)', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Détail de la facture
          pw.SizedBox(height: 30),
          pw.Text('DÉTAIL DE LA FACTURE', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.blue800)),
          pw.SizedBox(height: 10),
          
          // Tableau des prestations
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // En-tête du tableau
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  _tableHeader('Description'),
                  _tableHeader('Quantité'),
                  _tableHeader('Prix unitaire'),
                  _tableHeader('Montant HT'),
                ],
              ),
              
              // Ligne pour le prix de location
              if (prixLocation > 0)
                _tableRow(
                  'Location véhicule $vehicule',
                  '1',
                  formatMonetaire.format(prixLocation),
                  formatMonetaire.format(prixLocation),
                ),
              
              // Ligne pour le nettoyage intérieur
              if (fraisNettoyageInt > 0)
                _tableRow(
                  'Frais de nettoyage intérieur',
                  '1',
                  formatMonetaire.format(fraisNettoyageInt),
                  formatMonetaire.format(fraisNettoyageInt),
                ),
              
              // Ligne pour le nettoyage extérieur
              if (fraisNettoyageExt > 0)
                _tableRow(
                  'Frais de nettoyage extérieur',
                  '1',
                  formatMonetaire.format(fraisNettoyageExt),
                  formatMonetaire.format(fraisNettoyageExt),
                ),
              
              // Ligne pour le carburant manquant
              if (fraisCarburant > 0)
                _tableRow(
                  'Frais de carburant manquant',
                  '1',
                  formatMonetaire.format(fraisCarburant),
                  formatMonetaire.format(fraisCarburant),
                ),
              
              // Ligne pour les rayures et dommages
              if (fraisRayures > 0)
                _tableRow(
                  'Frais pour rayures et dommages',
                  '1',
                  formatMonetaire.format(fraisRayures),
                  formatMonetaire.format(fraisRayures),
                ),
              
              // Ligne pour les autres frais
              if (fraisAutre > 0)
                _tableRow(
                  'Autres frais',
                  '1',
                  formatMonetaire.format(fraisAutre),
                  formatMonetaire.format(fraisAutre),
                ),
              
              // Ligne pour la remise
              if (remise > 0)
                _tableRow(
                  'Remise',
                  '1',
                  '-${formatMonetaire.format(remise)}',
                  '-${formatMonetaire.format(remise)}',
                ),
            ],
          ),
          
          // Récapitulatif des montants
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  _summaryRow('Total HT:', formatMonetaire.format(totalHT)),
                  _summaryRow('TVA (20%):', formatMonetaire.format(montantTVA)),
                  _summaryRow('Total TTC:', formatMonetaire.format(totalTTC), isTotal: true),
                  if (caution > 0)
                    pw.SizedBox(height: 10),
                  if (caution > 0)
                    _summaryRow('Caution restituée:', formatMonetaire.format(caution), isPositive: true),
                ],
              ),
            ),
          ),
          
          // Informations de paiement
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('INFORMATIONS DE PAIEMENT', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.SizedBox(height: 5),
                pw.Text('Mode de paiement: ${factureData['factureTypePaiement'] ?? "Non spécifié"}', style: pw.TextStyle(fontSize: 10)),
                if (iban != null && bic != null) ...[                  
                  pw.Text('IBAN: $iban', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('BIC: $bic', style: pw.TextStyle(fontSize: 10)),
                ],
                pw.SizedBox(height: 5),
                pw.Text('Facture payable à réception. Merci pour votre confiance.', style: pw.TextStyle(fontSize: 10, font: italicFont)),
              ],
            ),
          ),
          
          // Conditions générales
          pw.SizedBox(height: 30),
          pw.Text('CONDITIONS GÉNÉRALES', style: pw.TextStyle(font: boldFont, fontSize: 12)),
          pw.SizedBox(height: 5),
          pw.Text(
            'Cette facture est soumise à nos conditions générales de vente. ' +
            'Tout retard de paiement entraînera des pénalités calculées au taux légal en vigueur. ' +
            'Une indemnité forfaitaire de 40€ pour frais de recouvrement sera due en cas de retard de paiement.',
            style: pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    // Sauvegarder le PDF
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/facture_${data['id'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    final output = File(path);
    await output.writeAsBytes(await pdf.save());

    return path;
  }

  /// Charge une image depuis Firebase Storage
  static Future<pw.MemoryImage?> _loadImageFromFirebaseStorage(String logoUrl) async {
    // Vérifier si l'URL est valide
    if (logoUrl.isEmpty || !logoUrl.startsWith('https://')) {
      print("URL du logo invalide: $logoUrl");
      return null;
    }
    
    // Essayer d'abord via HTTP pour éviter l'erreur d'autorisation Firebase
    try {
      final response = await NetworkAssetBundle(Uri.parse(logoUrl)).load(logoUrl);
      final bytes = response.buffer.asUint8List();
      return pw.MemoryImage(bytes);
    } catch (httpError) {
      // Si HTTP échoue, essayer via Firebase Storage
      try {
        final Uint8List? logoBytes = await FirebaseStorage.instance
            .refFromURL(logoUrl)
            .getData();
        
        if (logoBytes != null) {
          return pw.MemoryImage(logoBytes);
        }
      } catch (e) {
        // Erreur silencieuse - nous avons déjà essayé HTTP
      }
    }
    
    print("Impossible de charger le logo: $logoUrl");
    return null;
  }

  /// Crée un en-tête de tableau
  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Crée une ligne de tableau
  static pw.TableRow _tableRow(String description, String quantity, String unitPrice, String amount) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(description),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(quantity, textAlign: pw.TextAlign.center),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(unitPrice, textAlign: pw.TextAlign.right),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(amount, textAlign: pw.TextAlign.right),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isPositive ? PdfColors.green700 : null,
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
