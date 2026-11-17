import 'dart:io';
import 'dart:typed_data';
import 'package:ocr_demo/models/math_correction.dart';
import 'package:ocr_demo/services/correction_pdf.dart';

Future<Uint8List> worksheetBytes() =>
    File('test/fixtures/handwritten-worksheet.pdf').readAsBytes();
Stream<WorksheetPage> fixturePages(Uint8List _) async* {
  yield WorksheetPage(
    png: await File('test/fixtures/handwritten-worksheet.png').readAsBytes(),
    width: 1190,
    height: 1684,
  );
}

MathCorrection worksheetCorrection() => MathCorrection(
  summary:
      'Five answers reviewed. Two are correct; revisit distribution, square roots and adding fractions.',
  problems: [
    CorrectedProblem(
      question: '2(x + 3) = 14',
      studentWork: '2x + 3 = 14; x = 5.5',
      verdict: 'incorrect',
      explanation:
          'Distribute the 2 to both terms inside the parentheses. The constant becomes 6, not 3.',
      correctedSteps: ['2x + 6 = 14', '2x = 8', 'x = 4'],
      marginNote: 'Multiply BOTH terms by 2.',
      location: const ProblemLocation(
        page: 1,
        top: .125,
        left: .12,
        bottom: .23,
        right: .57,
      ),
    ),
    CorrectedProblem(
      question: '3x - 7 = 11',
      studentWork: '3x = 18; x = 6',
      verdict: 'correct',
      explanation: 'You added 7 to both sides and divided by 3 correctly.',
      correctedSteps: ['3(6) - 7 = 11'],
      marginNote: 'Good. Both sides stay equal.',
      location: const ProblemLocation(
        page: 1,
        top: .29,
        left: .12,
        bottom: .4,
        right: .57,
      ),
    ),
    CorrectedProblem(
      question: 'x^2 - 9 = 0',
      studentWork: 'x^2 = 9; x = 3',
      verdict: 'incorrect',
      explanation: 'There are two solutions. Both 3 and -3 have a square of 9.',
      correctedSteps: ['x^2 = 9', 'x = 3 or x = -3'],
      marginNote: 'Remember the negative root too.',
      location: const ProblemLocation(
        page: 1,
        top: .457,
        left: .12,
        bottom: .57,
        right: .57,
      ),
    ),
    CorrectedProblem(
      question: '1/2 + 1/3',
      studentWork: '2/5',
      verdict: 'incorrect',
      explanation:
          'Use a common denominator before adding. Do not add denominators.',
      correctedSteps: ['1/2 = 3/6', '1/3 = 2/6', '3/6 + 2/6 = 5/6'],
      marginNote: 'Use a common denominator: 6.',
      location: const ProblemLocation(
        page: 1,
        top: .624,
        left: .12,
        bottom: .71,
        right: .57,
      ),
    ),
    CorrectedProblem(
      question: '5(x - 2) = 3x + 4',
      studentWork: '5x - 10 = 3x + 4; 2x = 14; x = 7',
      verdict: 'correct',
      explanation:
          'The distribution and rearrangement are correct. Substitution gives 25 on each side.',
      correctedSteps: ['5(7 - 2) = 25', '3(7) + 4 = 25'],
      marginNote: 'Correct. Nice working.',
      location: const ProblemLocation(
        page: 1,
        top: .772,
        left: .12,
        bottom: .89,
        right: .7,
      ),
    ),
  ],
);
