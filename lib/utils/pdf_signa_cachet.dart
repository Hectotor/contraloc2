//import 'dart:math';

import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SignaCachetWidget {
  static pw.Widget build({
    required pw.ImageProvider? logoImage,
    required String nomEntreprise,
    required String adresse,
    required String telephone,
    required String siret,
    required String? nom,
    required String? prenom,
    required pw.Font boldFont,
    required pw.Font scriptFont,
    required pw.Font italicFont,
    required String? dateFinEffectif, // Ajout du paramètre
    String? signatureBase64, // Ancien paramètre
    pw.MemoryImage? signatureImage, // Nouveau paramètre
    pw.MemoryImage? signatureRetourImage, // Nouveau paramètre
  }) {
    // Log des informations de signature
    print('🔑 Paramètres de signature reçus :');
    print('📝 Signature Base64: ${signatureBase64 != null ? 'Présente (${signatureBase64.length} caractères)' : 'Absente'}');
    print('🖼️ Signature Image: ${signatureImage != null ? 'Présente' : 'Absente'}');
    print('🖼️ Signature Retour Image: ${signatureRetourImage != null ? 'Présente' : 'Absente'}');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.blue900),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'SIGNATURES',
            style: pw.TextStyle(
              fontSize: 20,
              font: boldFont,
              color: PdfColors.blue900,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.Divider(color: PdfColors.blue900),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildCachet(
                logoImage: logoImage,
                nomEntreprise: nomEntreprise,
                adresse: adresse,
                telephone: telephone,
                siret: siret,
                boldFont: boldFont,
              ),
              _buildSignatures(
                nom: nom,
                prenom: prenom,
                boldFont: boldFont,
                scriptFont: scriptFont,
                italicFont: italicFont,
                dateFinEffectif: dateFinEffectif,
                signatureBase64: signatureBase64, // Passage de l'ancien paramètre
                signatureImage: signatureImage, // Passage du nouveau paramètre
                signatureRetourImage: signatureRetourImage, // Passage du nouveau paramètre
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode statique pour convertir base64 en MemoryImage
  static pw.MemoryImage? base64ToMemoryImage(String? base64String) {
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

  static pw.Widget _buildCachet({
    required pw.ImageProvider? logoImage,
    required String nomEntreprise,
    required String adresse,
    required String telephone,
    required String siret,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.all(16.0),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoImage != null) ...[
            pw.Container(
              width: 70,
              height: 25,
              decoration: pw.BoxDecoration(
                image: pw.DecorationImage(
                  image: logoImage,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
          ],
          pw.Text(nomEntreprise,
              style: pw.TextStyle(fontSize: 16, font: boldFont)),
          pw.SizedBox(height: 4),
          pw.Text(adresse,
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center),
          pw.Text('Téléphone : $telephone',
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center),
          pw.Text('SIRET : $siret',
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures({
    required String? nom,
    required String? prenom,
    required pw.Font boldFont,
    required pw.Font scriptFont,
    required pw.Font italicFont,
    required String? dateFinEffectif,
    String? signatureBase64,
    pw.MemoryImage? signatureImage,
    pw.MemoryImage? signatureRetourImage,
  }) {
    // Convertir les signatures base64 en images si nécessaire
    signatureImage ??= base64ToMemoryImage(signatureBase64);
    
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.all(16.0),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('Signatures client',
              style: pw.TextStyle(fontSize: 16, font: boldFont)),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text('Départ',
                        style: pw.TextStyle(fontSize: 12, font: boldFont)),
                    pw.SizedBox(height: 5),
                    if (nom != null && prenom != null)
                      pw.Text(
                        '$nom $prenom',
                        style: pw.TextStyle(
                          fontSize: 12,  
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    // Modification pour gérer les signatures
                    if (signatureImage != null)
                      pw.Container(
                        width: 100,
                        height: 50,
                        child: pw.Image(
                          signatureImage,
                          fit: pw.BoxFit.contain,
                        ),
                      )
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text('Retour',
                        style: pw.TextStyle(fontSize: 12, font: boldFont)),
                    pw.SizedBox(height: 5),
                    if (nom != null &&
                        prenom != null &&
                        dateFinEffectif != null &&
                        dateFinEffectif.isNotEmpty)
                      pw.Text(
                        '$nom $prenom',
                        style: pw.TextStyle(
                          fontSize: 12,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    // Modification pour gérer les signatures de retour
                    if (signatureRetourImage != null)
                      pw.Container(
                        width: 100,
                        height: 50,
                        child: pw.Image(
                          signatureRetourImage,
                          fit: pw.BoxFit.contain,
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 12,
                height: 12,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'X',
                    style: pw.TextStyle(
                      fontSize: 8,
                      font: boldFont,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Text(
                'Lu et approuvé',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: italicFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
