import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

class PdfPermisWidget {
  static pw.Widget build({
    required Uint8List? permisRectoBytes,
    required Uint8List? permisVersoBytes,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 0,
          child: pw.Text(
            'Permis de Conduire',
            style: pw.TextStyle(fontSize: 18, font: boldFont),
          ),
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (permisRectoBytes != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Recto',
                      style: pw.TextStyle(fontSize: 14, font: boldFont),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Image(
                      pw.MemoryImage(permisRectoBytes),
                      height: 150,
                      fit: pw.BoxFit.contain,
                    ),
                  ],
                ),
              ),
            pw.SizedBox(width: 10),
            if (permisVersoBytes != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Verso',
                      style: pw.TextStyle(fontSize: 14, font: boldFont),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Image(
                      pw.MemoryImage(permisVersoBytes),
                      height: 150,
                      fit: pw.BoxFit.contain,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
