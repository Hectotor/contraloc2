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
    pw.ImageProvider? logoImage,
  }) {
    // Vérification et nettoyage des valeurs vides
    final entrepriseNom = nomEntreprise.trim().isNotEmpty ? nomEntreprise : 'Non renseigné';
    final entrepriseAdresse = adresse.trim().isNotEmpty ? adresse : 'Non renseigné';
    final entrepriseTelephone = telephone.trim().isNotEmpty ? telephone : 'Non renseigné';
    final entrepriseSiret = siret.trim().isNotEmpty ? siret : 'Non renseigné';

    // Vérification et nettoyage des valeurs vides pour les données client
    final clientNom = clientData['nom']?.trim().isNotEmpty ?? false ? clientData['nom'] : 'Non renseigné';
    final clientPrenom = clientData['prenom']?.trim().isNotEmpty ?? false ? clientData['prenom'] : 'Non renseigné';
    final clientAdresse = clientData['adresse']?.trim().isNotEmpty ?? false ? clientData['adresse'] : 'Non renseigné';
    final clientTelephone = clientData['telephone']?.trim().isNotEmpty ?? false ? clientData['telephone'] : 'Non renseigné';
    final clientEmail = clientData['email']?.trim().isNotEmpty ?? false ? clientData['email'] : 'Non renseigné';
    final clientNumeroPermis = clientData['numeroPermis']?.trim().isNotEmpty ?? false ? clientData['numeroPermis'] : 'Non renseigné';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildGarageInfo(
          nomEntreprise: entrepriseNom,
          adresse: entrepriseAdresse,
          telephone: entrepriseTelephone,
          siret: entrepriseSiret,
          boldFont: boldFont,
          ttf: ttf,
          logoImage: logoImage,
        ),
        _buildClientInfo(
          clientNom: clientNom,
          clientPrenom: clientPrenom,
          clientAdresse: clientAdresse,
          clientTelephone: clientTelephone,
          clientEmail: clientEmail,
          clientNumeroPermis: clientNumeroPermis,
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
    pw.ImageProvider? logoImage,
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
          pw.Text('Informations Loueur:',
              style: pw.TextStyle(
                fontSize: 12,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.black),
          pw.SizedBox(height: 5),
          pw.Text(nomEntreprise,
              style: pw.TextStyle(font: boldFont, fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text('Adresse: $adresse', 
              style: pw.TextStyle(font: ttf, fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text('Téléphone: $telephone', 
              style: pw.TextStyle(font: ttf, fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text('SIRET: $siret', 
              style: pw.TextStyle(font: ttf, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildClientInfo({
    required String clientNom,
    required String clientPrenom,
    required String clientAdresse,
    required String clientTelephone,
    required String clientEmail,
    required String clientNumeroPermis,
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
                fontSize: 12,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.black),
          pw.Text('Nom: $clientNom', style: pw.TextStyle(font: ttf, fontSize: 10)),
          pw.Text('Prénom: $clientPrenom',
              style: pw.TextStyle(font: ttf, fontSize: 10)),
          pw.Text('Adresse: $clientAdresse',
              style: pw.TextStyle(font: ttf, fontSize: 10)),
          pw.Text('Téléphone: $clientTelephone',
              style: pw.TextStyle(font: ttf, fontSize: 10)),
          pw.Text('Email: $clientEmail',
              style: pw.TextStyle(font: ttf, fontSize: 10)),
          pw.Text('Numéro de permis: $clientNumeroPermis',
              style: pw.TextStyle(font: ttf, fontSize: 10)),
        ],
      ),
    );
  }
}
