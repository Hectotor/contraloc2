import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'pdf_signa_cachet.dart';
import 'pdf_voiture.dart';
import 'pdf_info_contact.dart';

Future<String> generatePdf(
    Map<String, dynamic> data,
    String dateFinEffectif,
    String kilometrageRetour,
    String commentaireRetour,
    List<File>
        photosRetour, // This parameter can be removed if not used elsewhere
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
    String pourcentageEssence,
    String typeLocation,
    String prixLocation,
    {required String condition}) async {
  final pdf = pw.Document();

// Chargez les données des polices
  final font = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
  final boldData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
  final italicData = await rootBundle.load("assets/fonts/OpenSans-Italic.ttf");
  final scriptData = await rootBundle.load("assets/fonts/Pacifico-Regular.ttf");

// Créez les objets `pw.Font`
  final ttf = pw.Font.ttf(font);
  final scriptFont = pw.Font.ttf(font);
  final scriptdancing = pw.Font.ttf(scriptData); // Police Dancing Script
  final boldFont = pw.Font.ttf(boldData);
  final italicFont = pw.Font.ttf(italicData);

  // Charger le logo si disponible
  pw.ImageProvider? logoImage;
  if (logoUrl.isNotEmpty) {
    final logoBytes =
        (await NetworkAssetBundle(Uri.parse(logoUrl)).load(logoUrl))
            .buffer
            .asUint8List();
    // Compresser le logo
    final compressedLogo = await FlutterImageCompress.compressWithList(
      logoBytes,
      minWidth: 800,
      minHeight: 800,
      quality: 75,
    );
    logoImage = pw.MemoryImage(compressedLogo);
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

  // Charger les photos du véhicule au retour si disponibles
  List<Uint8List> photosRetourBytes = [];
  for (var photo in photosRetour) {
    final photoBytes = await photo.readAsBytes();
    // Compresser les photos
    final compressedPhoto = await FlutterImageCompress.compressWithList(
      photoBytes,
      minWidth: 800,
      minHeight: 800,
      quality: 75,
    );
    photosRetourBytes.add(compressedPhoto);
  }

  // Redimensionner les images avant de les inclure dans le PDF

  // Créer le document avec des pages multiples automatiquement
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
                if (logoImage != null)
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Container(
                      height: 50,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
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
                pw.SizedBox(width: 50),
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
              kilometrageRetour: kilometrageRetour,
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
              boldFont: boldFont,
              italicFont: italicFont,
              scriptFont: scriptFont,
              scriptdancing: scriptdancing,
              nom: data['nom'],
              prenom: data['prenom'],
              dateFinEffectif: dateFinEffectifData, // Ajout du paramètre
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
  try {
    return DateTime.parse(date);
  } catch (e) {
    return null;
  }
}

int? calculateDurationInDays(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  return end.difference(start).inDays;
}

double calculateTotalCost(int days, double dailyRate) {
  if (days <= 0 || dailyRate <= 0) return 0.0;
  return days * dailyRate;
}
