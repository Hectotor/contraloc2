import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/contrat_model.dart';
import 'pdf_signa_cachet.dart';
import 'pdf_voiture.dart';
import 'pdf_info_contact.dart';

Future<pw.MemoryImage?> _loadImageFromFirebaseStorage(String logoUrl) async {
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

Future<String> generatePdf(
  ContratModel contratModel, {
  String? nomCollaborateur,
  pw.MemoryImage? signatureRetourImage,
}) async {
  // Obtenir les paramètres du PDF à partir du modèle de contrat
  final data = contratModel.toPdfParams();
  
  final pdf = pw.Document();

  // Charger les données des polices
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
  String logoUrl = contratModel.logoUrl ?? '';
  if (logoUrl.isNotEmpty) {
    try {
      // Vérifier si c'est une URL Firebase Storage
      if (logoUrl.startsWith('https://firebasestorage.googleapis.com') || 
          logoUrl.startsWith('https://storage.googleapis.com')) {
        logoImage = await _loadImageFromFirebaseStorage(logoUrl);
      } else if (logoUrl.startsWith('https://')) {
        // Autres URLs HTTPS
        try {
          final response = await NetworkAssetBundle(Uri.parse(logoUrl)).load(logoUrl);
          final bytes = response.buffer.asUint8List();
          logoImage = pw.MemoryImage(bytes);
        } catch (httpError) {
          print("Échec du chargement du logo via HTTP: $httpError");
        }
      } else {
        // Chemin local
        try {
          final logoBytes = await File(logoUrl).readAsBytes();
          logoImage = pw.MemoryImage(logoBytes);
        } catch (fileError) {
          print("Erreur de lecture du fichier logo local: $fileError");
        }
      }
    } catch (e) {
      print("Erreur de chargement du logo : $e");
    }
  }

  // Fonction pour décoder une signature en base64
  Uint8List? _decodeBase64Signature(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    
    try {
      // Vérifier si la chaîne commence par 'data:image'
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:image')) {
        cleanBase64 = base64String.split(',')[1];
      }
      
      // Décoder la chaîne base64
      return base64Decode(cleanBase64);
    } catch (e) {
      print("Erreur lors du décodage de la signature: $e");
      return null;
    }
  }

  // Décodage des signatures
  pw.MemoryImage? signatureImage;
  pw.MemoryImage? signatureRetourImage;
  
  // Utiliser signatureAllerBase64 en priorité, puis signatureBase64 si disponible
  final signatureAller = contratModel.signatureAller;
  if (signatureAller != null && signatureAller.isNotEmpty) {
    try {
      final signatureBytes = _decodeBase64Signature(signatureAller);
      if (signatureBytes != null) {
        signatureImage = pw.MemoryImage(signatureBytes);
      }
    } catch (e) {
      print("Erreur lors du décodage de la signature aller: $e");
    }
  }
  
  // Décodage de la signature retour
  final signatureRetour = contratModel.signatureRetour;
  if (signatureRetour != null && signatureRetour.isNotEmpty) {
    try {
      final signatureRetourBytes = _decodeBase64Signature(signatureRetour);
      if (signatureRetourBytes != null) {
        signatureRetourImage = pw.MemoryImage(signatureRetourBytes);
      }
    } catch (e) {
      print("Erreur lors du décodage de la signature retour: $e");
    }
  }

  // Convertir les photos de retour en bytes
  List<Uint8List> photosRetourBytes = [];
  // Note: nous n'avons pas de champ photosRetour dans ContratModel, 
  // donc nous utilisons une liste vide pour l'instant
  // for (var photoFile in contratModel.photosRetour ?? []) {
  //   try {
  //     photosRetourBytes.add(await photoFile.readAsBytes());
  //   } catch (e) {
  //     print("Erreur lors de la lecture de la photo de retour: $e");
  //   }
  // }

  // Convertir les dates en DateTime
  DateTime? dateDebutParsed = tryParseDate(contratModel.dateDebut ?? '');
  DateTime? dateFinTheoriqueParsed = tryParseDate(contratModel.dateFinTheorique ?? '');
  DateTime? dateFinEffectifParsed = tryParseDate(contratModel.dateRetour);

  // Calculer les durées en jours avec valeurs par défaut
  final dureeTheorique =
      calculateDurationInDays(dateDebutParsed, dateFinTheoriqueParsed) ?? 0;
  final dureeEffectif =
      calculateDurationInDays(dateDebutParsed, dateFinEffectifParsed) ?? 0;

  // Calculer le coût total théorique avec validation
  final prixLocationDouble = double.tryParse(contratModel.prixLocation ?? '0') ?? 0.0;
  final coutTotalTheorique = dureeTheorique > 0 && !prixLocationDouble.isNaN
      ? calculateTotalCost(dureeTheorique, prixLocationDouble)
      : null;

  // Calculer le coût total effectif avec validation
  final coutTotal = dureeEffectif > 0 && !prixLocationDouble.isNaN
      ? calculateTotalCost(dureeEffectif, prixLocationDouble)
      : null;

  // S'assurer que typeLocation est correctement défini
  final String typeLocationValue = contratModel.typeLocation ?? '';

  // S'assurer que la caution est correctement définie dans data
  if (!data.containsKey('caution') || data['caution'] == null) {
    data['caution'] = data.containsKey('caution') ? data['caution'] : '';
  }

  // Définir des valeurs par défaut si elles sont vides
  if (typeLocationValue.isEmpty) {
    data['typeLocation'] = ""; // Laisser vide pour que l'utilisateur choisisse
  }
  
  if (data['caution'].toString().isEmpty) {
    data['caution'] = "0";
  }
  // Charger les photos du véhicule à l'aller si disponibles
  List<Uint8List> photosAllerBytes = [];
  if (contratModel.photosUrls != null) {
    for (var photoUrl in contratModel.photosUrls!) {
      try {
        final photoBytes =
            (await NetworkAssetBundle(Uri.parse(photoUrl)).load(photoUrl))
                .buffer
                .asUint8List();
        
        // Compresser l'image si nécessaire
        final compressedBytes = await FlutterImageCompress.compressWithList(
          photoBytes,
          minHeight: 1024,
          minWidth: 1024,
          quality: 80,
        );
        
        photosAllerBytes.add(compressedBytes);
      } catch (e) {
        print("Erreur lors du chargement de la photo: $e");
      }
    }
  }

  // Utiliser l'ID du document comme contratId
  final contratId = contratModel.contratId ?? '';

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
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    alignment: pw.Alignment.centerLeft,
                    child: logoImage != null
                      ? pw.SizedBox(
                          width: 50,
                          child: pw.Container(
                            height: 50,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        )
                      : pw.Container(),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    children: [
                      pw.Text('CONTRAT DE LOCATION',
                          style: pw.TextStyle(
                            fontSize: 18,
                            font: boldFont,
                            color: PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center),
                      pw.Text(contratModel.nomEntreprise ?? '',
                          style: pw.TextStyle(
                            fontSize: 12,
                            font: boldFont,
                            color: PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('N° de contrat:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              font: boldFont,
                              color: PdfColors.black,
                            )),
                        pw.Text(contratId,
                            style: pw.TextStyle(
                              fontSize: 6,
                              color: PdfColors.black,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            PdfInfoContactWidget.build(
              nomEntreprise: contratModel.nomEntreprise ?? '',
              adresse: contratModel.adresseEntreprise ?? '',
              telephone: contratModel.telephoneEntreprise ?? '',
              siret: contratModel.siretEntreprise ?? '',
              clientData: data,
              boldFont: boldFont,
              ttf: ttf,
              logoImage: logoImage, // Ajout du logoImage ici
              nomCollaborateur: nomCollaborateur, // Ajout du nom du collaborateur
            ),
            pw.SizedBox(height: 20),
            PdfVoitureWidget.build(
              contrat: contratModel,
              selectedPaymentMethod: contratModel.methodePaiement ?? '',
              typeCarburant: contratModel.typeCarburant ?? '',
              boiteVitesses: contratModel.boiteVitesses ?? '',
              assuranceNom: contratModel.assuranceNom ?? '',
              assuranceNumero: contratModel.assuranceNumero ?? '',
              franchise: contratModel.franchise ?? '',
              dateDebut: contratModel.dateDebut ?? '',
              dateFinTheorique: contratModel.dateFinTheorique ?? '',
              dateFinEffectifData: contratModel.dateRetour ?? '',
              kilometrageDepart: contratModel.kilometrageDepart ?? '',
              kilometrageAutorise: contratModel.kilometrageAutorise ?? '',
              kilometrageRetour: contratModel.kilometrageRetour ?? '',
              kilometrageSupp: contratModel.kilometrageSupp ?? '',
              typeLocation: typeLocationValue,
              pourcentageEssence: contratModel.pourcentageEssence.toString(),
              dureeTheorique: dureeTheorique,
              dureeEffectif: dureeEffectif,
              prixLocation: contratModel.prixLocation ?? '',
              coutTotalTheorique: coutTotalTheorique,
              coutTotal: coutTotal,
              accompte: contratModel.accompte ?? '', // Ajout du paramètre accompte
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
                        fontSize: 12,
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
                                    fontSize: 12,
                                    font: boldFont,
                                    color: PdfColors.black)),
                            pw.Text(contratModel.commentaireAller ?? '',
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
                                    fontSize: 12,
                                    font: boldFont,
                                    color: PdfColors.black)),
                            pw.Text(contratModel.commentaireRetour ?? '',
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
                  const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              margin: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue900, width: 1),
              ),
              child: pw.Text(
                'CONDITIONS GÉNÉRALES',
                style: pw.TextStyle(
                  fontSize: 15,
                  font: boldFont,
                  color: PdfColors.blue900,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Conditions générales
            ...contratModel.conditions?.split('\n').map((paragraph) {
              if (paragraph.trim().isEmpty) return pw.SizedBox(height: 10);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(paragraph.trim(),
                    style: pw.TextStyle(fontSize: 7, font: ttf)),
              );
            }).toList() ?? [],
            pw.SizedBox(height: 20), // Augmenté de 40 à 80
            SignaCachetWidget.build(
              logoImage: logoImage,
              nomEntreprise: contratModel.nomEntreprise ?? '',
              adresse: contratModel.adresseEntreprise ?? '',
              telephone: contratModel.telephoneEntreprise ?? '',
              siret: contratModel.siretEntreprise ?? '',
              nom: data['nom'],
              prenom: data['prenom'],
              boldFont: boldFont,
              italicFont: italicFont,
              scriptFont: scriptFont,
              dateFinEffectif: contratModel.dateRetour, // Ajout du paramètre
              signatureImage: signatureImage, // Passer la signature
              signatureRetourImage: signatureRetourImage,
            ),
            pw.SizedBox(height: 10),
          ],
        ),
      ],
    ),
  );

  // Page 3: Photos et documents
  // Page 4: Permis de conduire et photos du véhicule
  if (photosAllerBytes.isNotEmpty || photosRetourBytes.isNotEmpty) {
    // Créer une page pour chaque groupe de photos
    final photosPerPage = 4; // Maximum 4 photos par page
    
    // Photos à l'aller
    if (photosAllerBytes.isNotEmpty) {
      for (var i = 0; i < photosAllerBytes.length; i += photosPerPage) {
        final pagePhotos = photosAllerBytes.skip(i).take(photosPerPage).toList();
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 20),
              pw.Text('Photos du véhicule à l\'aller',
                  style: pw.TextStyle(fontSize: 18, font: boldFont)),
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: pagePhotos.map((photoBytes) {
                  return pw.Image(pw.MemoryImage(photoBytes),
                      width: 150, // Réduit la taille pour plus de photos par page
                      height: 150);
                }).toList(),
              ),
            ];
          },
        ));
      }
    }

    // Photos au retour
    if (photosRetourBytes.isNotEmpty) {
      for (var i = 0; i < photosRetourBytes.length; i += photosPerPage) {
        final pagePhotos = photosRetourBytes.skip(i).take(photosPerPage).toList();
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 20),
              pw.Text('Photos du véhicule au retour',
                  style: pw.TextStyle(fontSize: 18, font: boldFont)),
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: pagePhotos.map((photoBytes) {
                  return pw.Image(pw.MemoryImage(photoBytes),
                      width: 150, // Réduit la taille pour plus de photos par page
                      height: 150);
                }).toList(),
              ),
            ];
          },
        ));
      }
    }
  }

  // Sauvegarder le PDF
  final directory = await getTemporaryDirectory();
  final path = '${directory.path}/contrat.pdf';
  final output = File(path);
  await output.writeAsBytes(await pdf.save());

  return path;
}

// Méthodes de calcul intégrées
DateTime? tryParseDate(String? date) {
  if (date == null || date.isEmpty) return null;
  
  print('Tentative de parsing de la date: "$date"');
  try {
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