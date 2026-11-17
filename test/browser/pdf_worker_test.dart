@TestOn('browser')
library;

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_demo/models/math_correction.dart';
import 'package:ocr_demo/services/pdf_composer.dart';
import 'package:ocr_demo/services/pdf_executor_web.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Browser worker exports PDF while main-thread timer keeps running',
    () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
      final pen = ui.Paint()
        ..color = const ui.Color(0xFF333333)
        ..strokeWidth = 2;
      for (var y = 20.0; y < 840; y += 12) {
        canvas.drawLine(ui.Offset(20, y), ui.Offset(570, y + 6), pen);
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(595, 842);
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
      final font = await rootBundle.load('assets/fonts/Geist.ttf');
      final mono = await rootBundle.load('assets/fonts/GeistMono.ttf');
      var ticks = 0;
      final timer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => ticks++,
      );
      final watch = Stopwatch()..start();
      try {
        final bytes = await executePdfBuild(
          PdfBuildJob(
            correction: const MathCorrection(
              summary: 'Worker responsiveness fixture.',
              problems: [],
            ),
            fileName: 'worker-test.pdf',
            pages: List.generate(
              6,
              (_) => WorksheetPage(png: png, width: 595, height: 842),
            ),
            font: font,
            mono: mono,
          ),
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(1000));
        expect(
          ticks,
          greaterThan(2),
          reason:
              'The browser event loop must continue while the worker builds.',
        );
        // Timing is evidence only, not a hardware-dependent performance assertion.
        // ignore: avoid_print
        print(
          'Worker: ${watch.elapsedMilliseconds} ms, $ticks main-thread timer ticks, ${bytes.length} PDF bytes',
        );
      } finally {
        timer.cancel();
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
