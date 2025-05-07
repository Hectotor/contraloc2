import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:contraloc/MOBILE/models/contrat_model.dart';

/// Génère la section des commentaires pour le PDF du contrat
pw.Widget buildCommentairesSection({
  required ContratModel contratModel,
  required pw.Font boldFont,
  required pw.Font ttf,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(15),
    margin: const pw.EdgeInsets.only(bottom: 40),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      border: pw.Border.all(color: PdfColors.black),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Titre principal
            pw.Text('Commentaires:',
                style: pw.TextStyle(
                  fontSize: 12,
                  font: boldFont,
                  color: PdfColors.blue900,
                )),
            pw.SizedBox(width: 10),
            
            // Lieux de départ et de restitution
            if (contratModel.lieuDepart != null && contratModel.lieuDepart!.isNotEmpty)
              pw.Text('Départ: ${contratModel.lieuDepart!}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: boldFont,
                  )),
            
            if (contratModel.lieuDepart != null && contratModel.lieuDepart!.isNotEmpty && 
               contratModel.lieuRestitution != null && contratModel.lieuRestitution!.isNotEmpty)
              pw.Text(' / ',
                  style: pw.TextStyle(
                    fontSize: 10,
                  )),
            
            if (contratModel.lieuRestitution != null && contratModel.lieuRestitution!.isNotEmpty)
              pw.Text('Restitution: ${contratModel.lieuRestitution!}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: boldFont,
                  )),
          ],
        ),
        pw.Divider(color: PdfColors.black),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Les lieux de départ et de restitution sont maintenant affichés dans l'en-tête
                  pw.Text('Aller:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: boldFont,
                        color: PdfColors.black)),
                  pw.Text(contratModel.commentaireAller ?? '',
                      style: pw.TextStyle(font: ttf)),
                  pw.SizedBox(height: 8),
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
  );
}
