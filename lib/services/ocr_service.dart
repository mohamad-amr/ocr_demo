import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Contract for turning an input PDF into an OCR'd output PDF.
/// Swap [MockOcrService] with a real implementation (e.g. an HTTP call to your
/// OCR backend) without touching the bloc or UI.
abstract class OcrService {
  Future<Uint8List> process(Uint8List inputPdf, String fileName);
}

/// Placeholder that simulates latency and produces a result PDF locally.
class MockOcrService implements OcrService {
  @override
  Future<Uint8List> process(Uint8List inputPdf, String fileName) async {
    await Future<void>.delayed(const Duration(seconds: 3));

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'OCR Result',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Source: $fileName'),
            pw.Text(
              'Input size: ${(inputPdf.length / 1024).toStringAsFixed(1)} KB',
            ),
            pw.Divider(height: 32),
            pw.Text(
              'This is a mock output. Replace MockOcrService with a real '
              'implementation to return the recognized PDF.',
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
