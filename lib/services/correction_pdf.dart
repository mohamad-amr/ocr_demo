import 'dart:async';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../models/math_correction.dart';
import 'pdf_composer.dart';
import 'pdf_executor_native.dart'
    if (dart.library.js_interop) 'pdf_executor_web.dart';
export 'pdf_composer.dart' show WorksheetPage;

class WorksheetRenderException implements Exception {
  const WorksheetRenderException(this.message);
  final String message;
  @override
  String toString() => message;
}

typedef WorksheetRenderer = Stream<WorksheetPage> Function(Uint8List pdf);

Stream<WorksheetPage> rasterWorksheet(Uint8List pdf) async* {
  await for (final page in Printing.raster(pdf, dpi: 120)) {
    yield WorksheetPage(
      png: await page.toPng(),
      width: page.width,
      height: page.height,
    );
  }
}

/// Keeps every original page visually intact, then adds vector pen marks and
/// a separate note gutter. Source pages are rasterized; feedback stays text.
Future<Uint8List> buildCorrectionPdf(
  MathCorrection correction,
  String fileName, {
  required Uint8List originalPdf,
  WorksheetRenderer? renderPages,
}) async {
  final pages = <WorksheetPage>[];
  final renderer = renderPages ?? rasterWorksheet;
  try {
    await for (final page in renderer(
      originalPdf,
    ).timeout(const Duration(seconds: 30))) {
      if (pages.length == 20) {
        throw const WorksheetRenderException(
          'Use a PDF with 20 pages or fewer for a marked copy.',
        );
      }
      if (page.width <= 0 || page.height <= 0 || page.png.isEmpty) {
        throw const WorksheetRenderException(
          'This PDF page could not be read. Export it again and retry.',
        );
      }
      pages.add(page);
      await Future<void>.delayed(Duration.zero);
    }
  } on WorksheetRenderException {
    rethrow;
  } catch (_) {
    throw const WorksheetRenderException(
      'Could not open the original PDF for marking. Use an unlocked PDF with readable pages and try again.',
    );
  }
  if (pages.isEmpty) {
    throw const WorksheetRenderException('This PDF has no readable pages.');
  }
  // Platform rendering and asset loading stay on the main isolate. PDF layout,
  // image embedding and serialization run in a native isolate or web worker.
  final fontData = await rootBundle.load('assets/fonts/Geist.ttf');
  final monoData = await rootBundle.load('assets/fonts/GeistMono.ttf');
  try {
    return await executePdfBuild(
      PdfBuildJob(correction: correction, fileName: fileName, pages: pages, font: fontData, mono: monoData),
    );
  } on TimeoutException {
    throw const WorksheetRenderException('Preparing the marked PDF timed out. Try fewer pages.');
  } catch (_) {
    throw const WorksheetRenderException('Could not prepare the marked PDF. On web, check that the PDF worker asset is deployed and allowed by the site security policy.');
  }
}



