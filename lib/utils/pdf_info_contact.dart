import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/contrat_model.dart';

class PdfInfoContactWidget {
  static pw.Row build({
    required String nomEntreprise,
    required String adresse,
    required String telephone,
    required String siret,
    required ContratModel contrat,
    required pw.Font boldFont,
    required pw.Font ttf,
    pw.ImageProvider? logoImage, // Ajout du paramètre logoImage
    String? nomCollaborateur, // Ajout du paramètre pour le nom du collaborateur
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
          nomCollaborateur: nomCollaborateur, // Passage du nom du collaborateur
        ),
        _buildClientInfo(
          contrat: contrat,
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
    pw.ImageProvider? logoImage, // On peut garder le paramètre mais ne pas l'utiliser
    String? nomCollaborateur, // Ajout du paramètre pour le nom du collaborateur
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
                fontSize: 15,
                font: boldFont,
                color: PdfColors.blue900,
              )),
          pw.Divider(color: PdfColors.black),
          pw.SizedBox(height: 2),
          pw.Text(nomEntreprise,
              style: pw.TextStyle(fontSize: 12, font: boldFont)),
          pw.SizedBox(height: 2),
          if (nomCollaborateur?.isNotEmpty == true)
            pw.Text('Contrat créé par: $nomCollaborateur', style: pw.TextStyle(font: ttf, fontSize: 9)),
          if (nomCollaborateur?.isNotEmpty == true)
            pw.SizedBox(height: 2),
          if (adresse.isNotEmpty)
            pw.Text('Adresse: $adresse', style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.SizedBox(height: 2),
          if (telephone.isNotEmpty)
            pw.Text('Téléphone: $telephone', style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.SizedBox(height: 2),
          if (siret.isNotEmpty)
            pw.Text('SIRET: $siret', style: pw.TextStyle(font: ttf, fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildClientInfo({
    required ContratModel contrat,
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
          if (contrat.entrepriseClient != null && contrat.entrepriseClient!.isNotEmpty)
            pw.Text('Entreprise: ${contrat.entrepriseClient}',
                style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Nom: ${contrat.nom}', style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Prénom: ${contrat.prenom}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Adresse: ${contrat.adresse}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Téléphone: ${contrat.telephone}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Email: ${contrat.email}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          pw.Text('Numéro de permis: ${contrat.numeroPermis}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
          if (contrat.immatriculationVehiculeClient != null && contrat.immatriculationVehiculeClient!.isNotEmpty)
            pw.Text('Immatriculation véhicule: ${contrat.immatriculationVehiculeClient}',
                style: pw.TextStyle(font: ttf, fontSize: 9)),
          if (contrat.kilometrageVehiculeClient != null && contrat.kilometrageVehiculeClient!.isNotEmpty)
            pw.Text('Kilométrage véhicule: ${contrat.kilometrageVehiculeClient}',
                style: pw.TextStyle(font: ttf, fontSize: 9)),
        ],
      ),
    );
  }
}