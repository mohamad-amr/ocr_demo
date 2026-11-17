import 'dart:typed_data';

/// Converts a worksheet PDF into a correction report.
abstract class OcrService {
  Future<Uint8List> process(Uint8List inputPdf, String fileName);
}
