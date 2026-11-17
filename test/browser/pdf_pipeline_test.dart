@TestOn('browser')
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing_web.dart';
// ignore: implementation_imports
import 'package:printing/src/interface.dart';
import 'package:ocr_demo/cubit/ocr_cubit.dart';
import 'package:ocr_demo/models/math_correction.dart';
import 'package:ocr_demo/services/correction_pdf.dart';
import 'package:ocr_demo/services/gemini_ocr_service.dart';
import 'package:ocr_demo/views/home_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => PrintingPlatform.instance = PrintingPlugin());
  testWidgets(
    'Real web PDF rasterization, marking and page-level scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Uint8List result;
      await tester.runAsync(() async {
        final original = pw.Document();
        original.addPage(pw.Page(build: (_) => pw.Text('2x + 6 = 14\nx = 4')));
        original.addPage(pw.Page(build: (_) => pw.Text('3x - 7 = 11\nx = 6')));
        result = await buildCorrectionPdf(
          const MathCorrection(
            summary: 'Both answers are correct.',
            problems: [
              CorrectedProblem(
                question: '2x + 6 = 14',
                studentWork: 'x = 4',
                verdict: 'correct',
                explanation: 'Both sides are equal.',
                correctedSteps: ['2(4) + 6 = 14'],
                marginNote: 'Correct.',
                location: ProblemLocation(
                  page: 1,
                  top: .03,
                  left: .03,
                  bottom: .12,
                  right: .3,
                ),
              ),
            ],
          ),
          'browser-check.pdf',
          originalPdf: await original.save(),
        );
        final pages = await rasterWorksheet(result).toList();
        expect(pages.length, greaterThanOrEqualTo(3));
        expect(pages.first.width, greaterThan(500));
      });
      final cubit = OcrCubit(GeminiOcrService(request: (_) async => null));
      addTearDown(cubit.close);
      cubit.emit(
        OcrState(
          status: OcrStatus.success,
          fileName: 'browser-check.pdf',
          outputBytes: result,
        ),
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: HomeView()),
        ),
      );
      // Advance real PDF.js work and Flutter frames: preview rendering deliberately
      // waits for a painted frame before requesting another page.
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 16));
        if (find.text('End of document').evaluate().isNotEmpty) break;
      }
      expect(find.text('PAGE 1'), findsOneWidget);
      expect(find.text('PAGE 3'), findsOneWidget);
      expect(find.byType(Scrollable), findsOneWidget);
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scroll.position.maxScrollExtent, greaterThan(1000));
      await tester.drag(
        find.byKey(const ValueKey('page-scroll')),
        const Offset(0, -600),
      );
      await tester.pump();
      expect(scroll.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
