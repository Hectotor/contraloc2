import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'pdf_signa_cachet.dart';
import 'pdf_voiture.dart';
import 'pdf_info_contact.dart';

Future<pw.MemoryImage?> _loadImageFromFirebaseStorage(String logoUrl) async {
  try {
    // Télécharger les données de l'image
    final Uint8List? logoBytes = await FirebaseStorage.instance
        .refFromURL(logoUrl)
        .getData();
    
    if (logoBytes != null) {
      return pw.MemoryImage(logoBytes);
    }
  } catch (e) {
    print("Erreur de chargement du logo depuis Firebase Storage : $e");
  }
  return null;
}

Future<String> generatePdf(
  Map<String, dynamic> data,
  String dateFinEffectif,
  String kilometrageRetour,
  String commentaireRetour,
  List<File> photosRetour,
  String nomEntreprise,
  String logoUrl,
  String adresse,
  String telephone,
  String siret,
  String commentaireRetourData,
  String typeCarburant,
  String boiteVitesses,
  String vin,
  String assuranceNom,
  String assuranceNumero,
  String franchise,
  String kilometrageSupp,
  String rayures,
  String dateDebut,
  String dateFinTheorique,
  String dateFinEffectifData,
  String kilometrageDepart,
  String kilometrageAutorise,
  String pourcentageEssence,
  String typeLocation,
  String prixLocation, {
  required String condition,
  String? signatureBase64, // Signature aller
  String? signatureRetourBase64, // Signature retour
  String? signatureAllerBase64, // Nouvelle signature aller
}) async {
  final pdf = pw.Document();

  // Chargez les données des polices
  final font = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
  final boldData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
  final italicData = await rootBundle.load("assets/fonts/OpenSans-Italic.ttf");
  final scriptData = await rootBundle.load("assets/fonts/Pacifico-Regular.ttf");

  // Créez les objets `pw.Font`
  final ttf = pw.Font.ttf(font);
  final boldFont = pw.Font.ttf(boldData);
  final italicFont = pw.Font.ttf(italicData);
  final scriptFont = pw.Font.ttf(scriptData);

  // Charger le logo
  pw.MemoryImage? logoImage;
  if (logoUrl.isNotEmpty) {
    try {
      // Vérifier si c'est une URL Firebase Storage
      if (logoUrl.startsWith('https://firebasestorage.googleapis.com')) {
        logoImage = await _loadImageFromFirebaseStorage(logoUrl);
      } else {
        // Chemin local
        final logoBytes = await File(logoUrl).readAsBytes();
        logoImage = pw.MemoryImage(logoBytes);
      }
    } catch (e) {
      print("Erreur de chargement du logo : $e");
    }
  }

  // Fonctions utilitaires pour décoder les signatures
  pw.MemoryImage? _decodeBase64Signature(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    
    try {
      // Supprimer les en-têtes de données base64 si présents
      final base64Clean = base64String.contains(',') 
          ? base64String.split(',').last 
          : base64String;
      
      // Décoder la chaîne base64
      final Uint8List bytes = base64Decode(base64Clean);
      
      // Créer et retourner un MemoryImage
      return pw.MemoryImage(bytes);
    } catch (e) {
      print('Erreur de conversion base64 en image : $e');
      return null;
    }
  }

  // Convertir la signature base64 en image si disponible
  pw.MemoryImage? signatureImage;
  pw.MemoryImage? signatureRetourImage;

  // Nouvelle vérification pour data['signature_aller']
  if (data.containsKey('signature_aller') && 
      data['signature_aller'] is String && 
      data['signature_aller'].isNotEmpty) {
    signatureImage = _decodeBase64Signature(data['signature_aller']);
    signatureBase64 = data['signature_aller'];
  }

  // Vérification pour la signature de retour
  if (data.containsKey('signatureRetour') && 
      data['signatureRetour'] is String && 
      data['signatureRetour'].isNotEmpty) {
    signatureRetourImage = _decodeBase64Signature(data['signatureRetour']);
    signatureRetourBase64 = data['signatureRetour'];
  }

  // Vérification originale pour 'signature'
  if (data.containsKey('signature') && 
      data['signature'] is Map && 
      data['signature'].containsKey('base64') &&
      data['signature']['base64'] is String &&
      data['signature']['base64'].isNotEmpty) {
    signatureImage = _decodeBase64Signature(data['signature']['base64']);
    signatureBase64 = data['signature']['base64'];
  }

  // Vérification originale
  if (signatureBase64 != null && signatureBase64.isNotEmpty) {
    signatureImage = _decodeBase64Signature(signatureBase64);
  } else if (data.containsKey('signatureBase64') && 
             data['signatureBase64'] is String && 
             data['signatureBase64'].isNotEmpty) {
    signatureImage = _decodeBase64Signature(data['signatureBase64']);
  }

  // Vérification pour la signature aller
  if (data.containsKey('signatureAller') && 
      data['signatureAller'] is String && 
      data['signatureAller'].isNotEmpty) {
    signatureImage = _decodeBase64Signature(data['signatureAller']);
    signatureBase64 = data['signatureAller'];
  }

  // Nouvelle vérification pour signatureAllerBase64
  if (signatureAllerBase64 != null && signatureAllerBase64.isNotEmpty) {
    signatureImage = _decodeBase64Signature(signatureAllerBase64);
    signatureBase64 = signatureAllerBase64;
  }

  // Vérification pour la signature de retour
  if (data.containsKey('signatureRetourBase64') && 
      data['signatureRetourBase64'] is String && 
      data['signatureRetourBase64'].isNotEmpty) {
    signatureRetourImage = _decodeBase64Signature(data['signatureRetourBase64']);
  }

  // Convertir les photos de retour en bytes
  List<Uint8List> photosRetourBytes = [];
  for (var photoFile in photosRetour) {
    try {
      photosRetourBytes.add(await photoFile.readAsBytes());
    } catch (e) {
      print("Erreur de chargement d'une photo : $e");
    }
  }

  // Convertir les dates en DateTime
  DateTime? dateDebutParsed = tryParseDate(dateDebut);
  DateTime? dateFinTheoriqueParsed = tryParseDate(dateFinTheorique);
  DateTime? dateFinEffectifParsed = tryParseDate(dateFinEffectifData);

  // Calculer les durées en jours avec valeurs par défaut
  final dureeTheorique =
      calculateDurationInDays(dateDebutParsed, dateFinTheoriqueParsed) ?? 0;
  final dureeEffectif =
      calculateDurationInDays(dateDebutParsed, dateFinEffectifParsed) ?? 0;

  // Calculer le coût total théorique avec validation
  final prixLocationDouble = double.tryParse(prixLocation) ?? 0.0;
  final coutTotalTheorique = dureeTheorique > 0 && !prixLocationDouble.isNaN
      ? calculateTotalCost(dureeTheorique, prixLocationDouble)
      : 0.0;

  // Calculer le coût total effectif avec validation
  final coutTotal = dureeEffectif > 0 && !prixLocationDouble.isNaN
      ? calculateTotalCost(dureeEffectif, prixLocationDouble)
      : 0.0;

  // Charger les photos du véhicule à l'aller si disponibles
  List<Uint8List> photosAllerBytes = [];
  if (data['photos'] != null) {
    for (var photoUrl in data['photos']) {
      final photoBytes =
          (await NetworkAssetBundle(Uri.parse(photoUrl)).load(photoUrl))
              .buffer
              .asUint8List();
      // Compresser les photos
      final compressedPhoto = await FlutterImageCompress.compressWithList(
        photoBytes,
        minWidth: 800,
        minHeight: 800,
        quality: 75,
      );
      photosAllerBytes.add(compressedPhoto);
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (pw.Context context) {
        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Page ${context.pageNumber} sur ${context.pagesCount}',
                style: pw.TextStyle(font: ttf, fontSize: 10)),
          ],
        );
      },
      build: (pw.Context context) => [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  width: 50,
                  child: logoImage != null
                    ? pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        child: pw.Container(
                          height: 50,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      )
                    : pw.Container(),
                ),
                pw.Column(
                  children: [
                    pw.Text('CONTRAT DE LOCATION',
                        style: pw.TextStyle(
                          fontSize: 24,
                          font: boldFont,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center),
                    pw.Text(nomEntreprise,
                        style: pw.TextStyle(
                          fontSize: 18,
                          font: boldFont,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center),
                  ],
                ),
                pw.Container(width: 50),
              ],
            ),
            pw.SizedBox(height: 30),
            PdfInfoContactWidget.build(
              nomEntreprise: nomEntreprise,
              adresse: adresse,
              telephone: telephone,
              siret: siret,
              clientData: data,
              boldFont: boldFont,
              ttf: ttf,
              logoImage: logoImage, // Ajout du logoImage ici
            ),
            pw.SizedBox(height: 20),
            PdfVoitureWidget.build(
              data: data,
              typeCarburant: typeCarburant,
              boiteVitesses: boiteVitesses,
              assuranceNom: assuranceNom,
              assuranceNumero: assuranceNumero,
              franchise: franchise,
              dateDebut: dateDebut,
              dateFinTheorique: dateFinTheorique,
              dateFinEffectifData: dateFinEffectifData,
              kilometrageDepart: kilometrageDepart,
              kilometrageAutorise: kilometrageAutorise,
              kilometrageRetour: kilometrageRetour,
              kilometrageSupp: kilometrageSupp,
              typeLocation: typeLocation,
              pourcentageEssence: pourcentageEssence,
              dureeTheorique: dureeTheorique,
              dureeEffectif: dureeEffectif,
              prixLocation: prixLocation,
              prixRayures: rayures,
              coutTotalTheorique: coutTotalTheorique,
              coutTotal: coutTotal,
              boldFont: boldFont,
              ttf: ttf,
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              margin: const pw.EdgeInsets.only(
                  bottom: 40), // Ajout de la marge du bas
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.black),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Commentaires:',
                      style: pw.TextStyle(
                        fontSize: 18,
                        font: boldFont,
                        color: PdfColors.blue900,
                      )),
                  pw.Divider(color: PdfColors.black),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Aller:',
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    font: boldFont,
                                    color: PdfColors.black)),
                            pw.Text(data['commentaire'] ?? '',
                                style: pw.TextStyle(font: ttf)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Retour:',
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    font: boldFont,
                                    color: PdfColors.black)),
                            pw.Text(commentaireRetour,
                                style: pw.TextStyle(font: ttf)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],
        ),

        // Page 2: Conditions générales et signatures
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête Conditions Générales
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              margin: const pw.EdgeInsets.symmetric(vertical: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue900, width: 1),
              ),
              child: pw.Text(
                'CONDITIONS GÉNÉRALES',
                style: pw.TextStyle(
                  fontSize: 24,
                  font: boldFont,
                  color: PdfColors.blue900,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Conditions générales
            ...condition.split('\n').map((paragraph) {
              if (paragraph.trim().isEmpty) return pw.SizedBox(height: 10);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(
                  paragraph.trim(),
                  style: pw.TextStyle(font: ttf),
                  textAlign: pw.TextAlign.justify,
                ),
              );
            }).toList(),
            pw.SizedBox(height: 40), // Augmenté de 40 à 80
            SignaCachetWidget.build(
              logoImage: logoImage,
              nomEntreprise: nomEntreprise,
              adresse: adresse,
              telephone: telephone,
              siret: siret,
              nom: data['nom'],
              prenom: data['prenom'],
              boldFont: boldFont,
              italicFont: italicFont,
              scriptFont: scriptFont,
              dateFinEffectif: dateFinEffectifData, // Ajout du paramètre
              signatureImage: signatureImage, // Passer la signature
              signatureRetourImage: signatureRetourImage, // Passer la signature de retour
            ),
            pw.SizedBox(height: 80),
          ],
        ),

        // Page 3: Photos et documents
        // Page 4: Permis de conduire et photos du véhicule
        if (photosAllerBytes.isNotEmpty || photosRetourBytes.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (photosAllerBytes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('Photos du véhicule à l\'aller',
                    style: pw.TextStyle(fontSize: 18, font: boldFont)),
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: photosAllerBytes.map((photoBytes) {
                    return pw.Image(pw.MemoryImage(photoBytes),
                        width: 200, height: 200);
                  }).toList(),
                ),
              ],
              if (photosRetourBytes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('Photos du véhicule au retour',
                    style: pw.TextStyle(fontSize: 18, font: boldFont)),
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: photosRetourBytes.map((photoBytes) {
                    return pw.Image(pw.MemoryImage(photoBytes),
                        width: 200, height: 200);
                  }).toList(),
                ),
              ],
            ],
          ),
      ],
    ),
  );

  // Sauvegarder le PDF
  final directory = await getTemporaryDirectory();
  final path = '${directory.path}/contrat.pdf';
  final output = File(path);
  await output.writeAsBytes(await pdf.save());

  return path;
}

// Méthodes de calcul intégrées
DateTime? tryParseDate(String date) {
  print('Tentative de parsing de la date: "$date"');
  try {
    if (date.isEmpty) return null;

    // Format: "jour de la semaine jour mois à heure:minute"
    // Ex: "samedi 8 mars à 21:18"
    final regex = RegExp(r'.*?(\d+)\s+([\wé]+)\s+à\s+(\d+):(\d+)');
    final match = regex.firstMatch(date);
    
    if (match != null) {
      final jour = int.parse(match.group(1)!);
      final mois = _convertirMois(match.group(2)!);
      final heure = int.parse(match.group(3)!);
      final minute = int.parse(match.group(4)!);
      
      if (mois != null) {
        // Utiliser l'année courante car elle n'est pas dans le format
        final maintenant = DateTime.now();
        return DateTime(maintenant.year, mois, jour, heure, minute);
      }
    }
    
    return null;
  } catch (e) {
    print('Erreur de parsing finale: $e');
    return null;
  }
}

int? _convertirMois(String mois) {
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

int? calculateDurationInDays(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  return end.difference(start).inDays;
}

double calculateTotalCost(int days, double dailyRate) {
  if (days <= 0 || dailyRate <= 0) return 0.0;
  return days * dailyRate;
}