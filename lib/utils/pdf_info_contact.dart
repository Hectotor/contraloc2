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
    String? nomCollaborateur,
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
          logoImage: logoImage,
          nomCollaborateur: nomCollaborateur,
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
    pw.ImageProvider? logoImage,
    String? nomCollaborateur,
  }) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Informations Loueur:',
              style: pw.TextStyle(
                fontSize: 10,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.grey400, thickness: 0.5),
          pw.SizedBox(height: 1),
          pw.Text(nomEntreprise,
              style: pw.TextStyle(fontSize: 9, font: boldFont)),
          pw.SizedBox(height: 1),
          if (nomCollaborateur != null && nomCollaborateur.isNotEmpty)
            pw.Text('Contrat créé par: $nomCollaborateur', style: pw.TextStyle(font: ttf, fontSize: 8)),
          if (nomCollaborateur != null && nomCollaborateur.isNotEmpty)
            pw.SizedBox(height: 1),
          if (adresse.isNotEmpty)
            pw.Text('Adresse: $adresse', style: pw.TextStyle(font: ttf, fontSize: 8)),
          pw.SizedBox(height: 1),
          if (telephone.isNotEmpty)
            pw.Text('Téléphone: $telephone', style: pw.TextStyle(font: ttf, fontSize: 8)),
          pw.SizedBox(height: 1),
          pw.Text('SIRET: $siret', style: pw.TextStyle(font: ttf, fontSize: 8)),
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
      width: 200,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Informations Client:',
              style: pw.TextStyle(
                fontSize: 10,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.grey400, thickness: 0.5),
          pw.Text('Nom: ${clientData['nom']}', style: pw.TextStyle(font: ttf, fontSize: 8)),
          pw.Text('Prénom: ${clientData['prenom']}', style: pw.TextStyle(font: ttf, fontSize: 8)),
          pw.Text('Adresse: ${clientData['adresse']}', style: pw.TextStyle(font: ttf, fontSize: 8)),
          pw.Text('Téléphone: ${clientData['telephone']}', style: pw.TextStyle(font: ttf, fontSize: 8)),
          pw.Text('Email: ${clientData['email']}', style: pw.TextStyle(font: ttf, fontSize: 8)),
          pw.Text('Numéro de permis: ${clientData['numeroPermis']}', style: pw.TextStyle(font: ttf, fontSize: 8)),
          if (clientData['immatriculationVehiculeClient'] != null && clientData['immatriculationVehiculeClient'].toString().isNotEmpty)
            pw.Text('Immatriculation véhicule: ${clientData['immatriculationVehiculeClient']}', style: pw.TextStyle(font: ttf, fontSize: 8)),
          if (clientData['kilometrageVehiculeClient'] != null && clientData['kilometrageVehiculeClient'].toString().isNotEmpty)
            pw.Text('Kilométrage véhicule: ${clientData['kilometrageVehiculeClient']}', style: pw.TextStyle(font: ttf, fontSize: 8)),
        ],
      ),
    );
  }
}
