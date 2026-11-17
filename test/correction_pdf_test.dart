import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_demo/models/math_correction.dart';
import 'package:ocr_demo/services/correction_pdf.dart';
import 'worksheet_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Rejects invalid locations without discarding usable feedback', () {
    for (final location in [
      null,
      {
        'page': 0,
        'box': [0, 0, 0, 0],
      },
      {
        'page': 1,
        'box': [600, 100, 400, 500],
      },
      {
        'page': 1,
        'box': [0, 0, 1001, 900],
      },
      {
        'page': 1,
        'box': ['bad', 0, 500, 500],
      },
      {
        'page': 1,
        'box': [0, 0, 500],
      },
    ]) {
      expect(ProblemLocation.tryParse(location), isNull);
    }
    final location = ProblemLocation.tryParse({
      'page': 2,
      'box': [100, 200, 300, 400],
    })!;
    expect(location.page, 2);
    expect(location.top, .1);
    expect(location.right, .4);
  });
  test(
    'Builds marked original pages and a complete correction appendix',
    () async {
      final bytes = await buildCorrectionPdf(
        worksheetCorrection(),
        'handwritten-algebra.pdf',
        originalPdf: await worksheetBytes(),
        renderPages: fixturePages,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(40000));
      if (const bool.fromEnvironment('WRITE_REVIEW_ARTIFACTS')) {
        await Directory('output/pdf').create(recursive: true);
        await File(
          'output/pdf/marked-worksheet-preview.pdf',
        ).writeAsBytes(bytes);
      }
    },
  );
  test('Handles crowded margins, unplaced notes and long explanations', () async {
    final original = worksheetCorrection().problems.first;
    final correction = MathCorrection(
      summary: 'Crowded worksheet.',
      problems: List.generate(
        12,
        (i) => CorrectedProblem(
          question: original.question,
          studentWork: original.studentWork,
          verdict: i.isEven ? 'incorrect' : 'unclear',
          explanation: List.filled(
            70,
            'Check the distribution and keep both sides equal.',
          ).join(' '),
          correctedSteps: List.filled(8, '2x + 6 = 14'),
          marginNote:
              'Apply the factor to both terms before moving the constant to the other side.',
          location: i == 11 ? null : original.location,
        ),
      ),
    );
    final bytes = await buildCorrectionPdf(
      correction,
      'crowded.pdf',
      originalPdf: await worksheetBytes(),
      renderPages: fixturePages,
    );
    expect(bytes.length, greaterThan(10000));
  });
  test('Does not silently return a report without original pages', () async {
    await expectLater(
      buildCorrectionPdf(
        worksheetCorrection(),
        'empty.pdf',
        originalPdf: Uint8List(0),
        renderPages: (_) => const Stream<WorksheetPage>.empty(),
      ),
      throwsA(isA<WorksheetRenderException>()),
    );
    await expectLater(
      buildCorrectionPdf(
        worksheetCorrection(),
        'locked.pdf',
        originalPdf: Uint8List(0),
        renderPages: (_) => Stream<WorksheetPage>.error(Exception('locked')),
      ),
      throwsA(isA<WorksheetRenderException>()),
    );
  });
  test(
    'Rejects more than 20 original pages rather than dropping any',
    () async {
      final page = await fixturePages(Uint8List(0)).first;
      await expectLater(
        buildCorrectionPdf(
          worksheetCorrection(),
          'long.pdf',
          originalPdf: Uint8List(0),
          renderPages: (_) => Stream.fromIterable(List.filled(21, page)),
        ),
        throwsA(isA<WorksheetRenderException>()),
      );
    },
  );
}
