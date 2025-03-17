import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfInfoContactWidget {
  static pw.Row build({
    required String nomEntreprise,
    required String adresse,
    required String telephone,
    required String siret,
    required Map<String, dynamic> clientData,
    required pw.Font boldFont,
    required pw.Font ttf,
    pw.ImageProvider? logoImage, // Ajout du paramètre logoImage
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildGarageInfo(
          nomEntreprise: nomEntreprise,
          adresse: adresse,
          telephone: telephone,
          siret: siret,
          boldFont: boldFont,
          ttf: ttf,
          logoImage: logoImage, // Passage du logoImage
        ),
        _buildClientInfo(
          clientData: clientData,
          boldFont: boldFont,
          ttf: ttf,
        ),
      ],
    );
  }

  static pw.Widget _buildGarageInfo({
    required String nomEntreprise,
    required String adresse,
    required String telephone,
    required String siret,
    required pw.Font boldFont,
    required pw.Font ttf,
    pw.ImageProvider?
        logoImage, // On peut garder le paramètre mais ne pas l'utiliser
  }) {
    return pw.Container(
      width: 250,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Suppression du bloc logo ici
          pw.Text('Informations Loueur:',
              style: pw.TextStyle(
                fontSize: 15,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.black),
          pw.SizedBox(height: 2),
          pw.Text(nomEntreprise,
              style: pw.TextStyle(fontSize: 12, font: boldFont)),
          pw.SizedBox(height: 2),
          if (adresse.isNotEmpty)
            pw.Text('Adresse: $adresse', style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.SizedBox(height: 2),
          if (telephone.isNotEmpty)
            pw.Text('Téléphone: $telephone', style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.SizedBox(height: 2),
          pw.Text('SIRET: $siret', style: pw.TextStyle(font: ttf, fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildClientInfo({
    required Map<String, dynamic> clientData,
    required pw.Font boldFont,
    required pw.Font ttf,
  }) {
    return pw.Container(
      width: 250,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Informations Client:',
              style: pw.TextStyle(
                fontSize: 15,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.black),
          pw.Text('Nom: ${clientData['nom']}', style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Prénom: ${clientData['prenom']}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Adresse: ${clientData['adresse']}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Téléphone: ${clientData['telephone']}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Email: ${clientData['email']}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Numéro de permis: ${clientData['numeroPermis']}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
        ],
      ),
    );
  }
}
