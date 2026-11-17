import 'dart:convert';
import 'dart:typed_data';
import '../models/math_correction.dart';
import 'pdf_composer.dart';

/// Structured-clone data only; no UI objects, Firebase credentials or callbacks.
PdfBuildJob decodePdfJob(Map<Object?, Object?> message) {
  final font = message['font'] as Uint8List;
  final mono = message['mono'] as Uint8List;
  return PdfBuildJob(
    correction: MathCorrection.parse(jsonEncode(message['correction'])),
    fileName: message['fileName'] as String,
    pages: [
      for (final entry in message['pages'] as List)
        WorksheetPage(
          png: entry['png'] as Uint8List,
          width: (entry['width'] as num).toInt(),
          height: (entry['height'] as num).toInt(),
        ),
    ],
    font: ByteData.sublistView(font),
    mono: ByteData.sublistView(mono),
  );
}
