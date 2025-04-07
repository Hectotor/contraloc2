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
    required String? dateFinEffectif,
    String? signatureBase64,
    pw.MemoryImage? signatureImage,
    pw.MemoryImage? signatureRetourImage,
  }) {
    signatureImage ??= base64ToMemoryImage(signatureBase64);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: _buildContainerDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _buildTitle('SIGNATURES', boldFont),
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
                dateFinEffectif: dateFinEffectif,
                boldFont: boldFont,
                italicFont: italicFont,
                signatureImage: signatureImage,
                signatureRetourImage: signatureRetourImage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.MemoryImage? base64ToMemoryImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    
    try {
      final base64Clean = base64String.contains(',') ? base64String.split(',').last : base64String;
      final bytes = base64Decode(base64Clean);
      return pw.MemoryImage(bytes);
    } catch (e) {
      print('Erreur de conversion base64 en image : $e');
      return null;
    }
  }

  static pw.BoxDecoration _buildContainerDecoration() {
    return pw.BoxDecoration(
      color: PdfColors.grey100,
      border: pw.Border.all(color: PdfColors.blue900),
      borderRadius: pw.BorderRadius.circular(8),
    );
  }

  static pw.Text _buildTitle(String text, pw.Font font) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 15, font: font, color: PdfColors.blue900),
      textAlign: pw.TextAlign.center,
    );
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
      decoration: _buildContainerDecoration(),
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
          ...[
            pw.Text(nomEntreprise, style: pw.TextStyle(font: boldFont)),
            pw.Text(adresse),
            pw.Text(telephone),
            pw.Text(siret),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures({
    required String? nom,
    required String? prenom,
    required String? dateFinEffectif,
    required pw.Font boldFont,
    required pw.Font italicFont,
    pw.MemoryImage? signatureImage,
    pw.MemoryImage? signatureRetourImage,
  }) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.all(5),
      margin: const pw.EdgeInsets.only(bottom: 5),
      decoration: _buildContainerDecoration(),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          _buildTitle('Signatures client', boldFont),
          pw.Divider(),
          pw.SizedBox(height: 5),
          _buildSignatureSection(
            title: 'Départ',
            name: '$nom $prenom',
            signature: signatureImage,
            boldFont: boldFont,
          ),
          pw.SizedBox(width: 10),
          _buildSignatureSection(
            title: 'Retour',
            name: dateFinEffectif?.isNotEmpty == true ? '$nom $prenom' : null,
            signature: signatureRetourImage,
            boldFont: boldFont,
          ),
          pw.SizedBox(height: 20),
          _buildCheckBox('Lu et approuvé', italicFont, boldFont),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureSection({
    required String title,
    String? name,
    pw.MemoryImage? signature,
    required pw.Font boldFont,
  }) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 9, font: boldFont)),
          pw.SizedBox(height: 5),
          if (name != null)
            pw.Text(name, style: pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.center),
          if (signature != null)
            pw.Container(
              width: 100,
              height: 50,
              child: pw.Image(signature, fit: pw.BoxFit.contain),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckBox(String text, pw.Font italicFont, pw.Font boldFont) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Center(
            child: pw.Text('X', style: pw.TextStyle(fontSize: 8, font: boldFont)),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(text, style: pw.TextStyle(fontSize: 10, font: italicFont)),
      ],
    );
  }
}
