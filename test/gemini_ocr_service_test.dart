import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:ocr_demo/models/math_correction.dart';
import 'package:ocr_demo/services/gemini_ocr_service.dart';
import 'package:ocr_demo/cubit/ocr_cubit.dart';
import 'package:ocr_demo/services/ocr_service.dart';
import 'worksheet_fixture.dart';

String response({String verdict = 'incorrect'}) => jsonEncode({
  'summary': 'One distribution error.',
  'problems': [
    {
      'question': '2(x + 3) = 14',
      'studentWork': '2x + 3 = 14',
      'verdict': verdict,
      'explanation': 'Multiply both terms by 2.',
      'correctedSteps': ['2x + 6 = 14', '2x = 8', 'x = 4'],
    },
  ],
});

class PendingService implements OcrService {
  final result = Completer<Uint8List>();
  int calls = 0;
  @override
  Future<Uint8List> process(Uint8List inputPdf, String fileName) {
    calls++;
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pdf = Uint8List.fromList('%PDF-1.7\n'.codeUnits);
  test(
    'Rejects empty, oversized and non-PDF input before requesting AI',
    () async {
      var calls = 0;
      final service = GeminiOcrService(
        request: (_) async {
          calls++;
          return response();
        },
      );
      for (final bytes in [
        Uint8List(0),
        Uint8List(GeminiOcrService.maxInputBytes + 1),
        Uint8List.fromList('hello'.codeUnits),
      ]) {
        await expectLater(
          service.process(bytes, 'test.pdf'),
          throwsA(isA<CorrectionException>()),
        );
      }
      expect(calls, 0);
    },
  );
  test('Validates verdict and required fields', () {
    expect(
      MathCorrection.parse(response()).problems.single.verdict,
      'incorrect',
    );
    expect(
      () => MathCorrection.parse(response(verdict: 'maybe')),
      throwsFormatException,
    );
    expect(
      () => MathCorrection.parse('{"problems":[]}'),
      throwsFormatException,
    );
  });
  test('Handles empty and malformed model responses', () async {
    for (final value in [null, '', '{broken']) {
      final service = GeminiOcrService(request: (_) async => value);
      await expectLater(
        service.process(pdf, 'test.pdf'),
        throwsA(isA<CorrectionException>()),
      );
    }
  });
  test(
    'Renders a real PDF from a validated correction with bundled font',
    () async {
      final service = GeminiOcrService(
        request: (_) async => response(),
        renderPages: fixturePages,
      );
      final result = await service.process(pdf, 'algebra.pdf');
      expect(String.fromCharCodes(result.take(5)), '%PDF-');
      expect(result.length, greaterThan(1000));
    },
  );
  test('Maps App Check rejection and timeouts to useful messages', () async {
    final rejected = GeminiOcrService(
      request: (_) async => throw Exception('403 App Check'),
    );
    await expectLater(
      rejected.process(pdf, 'a.pdf'),
      throwsA(
        isA<CorrectionException>().having(
          (e) => e.message,
          'message',
          contains('App Check'),
        ),
      ),
    );
    final slow = GeminiOcrService(
      timeout: const Duration(milliseconds: 1),
      request: (_) => Completer<String?>().future,
    );
    await expectLater(
      slow.process(pdf, 'a.pdf'),
      throwsA(
        isA<CorrectionException>().having(
          (e) => e.message,
          'message',
          contains('too long'),
        ),
      ),
    );
  });
  test(
    'Preserves backend validation errors even without HTTP status',
    () async {
      final service = GeminiOcrService(
        request: (_) async => throw ServerException(
          'Invalid argument: response schema is too complex.',
        ),
      );
      await expectLater(
        service.process(pdf, 'test.pdf'),
        throwsA(
          isA<CorrectionException>().having(
            (e) => e.message,
            'message',
            contains('response schema is too complex'),
          ),
        ),
      );
    },
  );
  test(
    'Explains invalid API keys and redacts credentials in diagnostics',
    () async {
      for (final error in [
        InvalidApiKey('API key not valid. Please pass a valid API key.'),
        ServerException('400 invalid argument with key AIzaExampleSecret123'),
      ]) {
        final service = GeminiOcrService(request: (_) async => throw error);
        await expectLater(
          service.process(pdf, 'test.pdf'),
          throwsA(
            isA<CorrectionException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains(
                  error is InvalidApiKey
                      ? 'Firebase rejected the API key'
                      : 'AI request rejected',
                ),
                isNot(contains('AIzaExampleSecret123')),
              ),
            ),
          ),
        );
      }
    },
  );
  test('App Check failures stop before uploading the PDF', () async {
    var calls = 0;
    for (final tokenRequest in <Future<String?> Function()>[
      () async => null,
      () async => '',
      () async => throw Exception('attestation rejected'),
      () => Completer<String?>().future,
    ]) {
      final service = GeminiOcrService(
        appCheckToken: tokenRequest,
        appCheckTimeout: const Duration(milliseconds: 1),
        request: (_) async {
          calls++;
          return response();
        },
      );
      await expectLater(
        service.process(pdf, 'test.pdf'),
        throwsA(
          isA<CorrectionException>().having(
            (e) => e.message,
            'message',
            contains('App Check'),
          ),
        ),
      );
    }
    expect(calls, 0);
  });
  test('Verified request times out without retrying', () async {
    var calls = 0;
    final pending = Completer<String?>();
    final service = GeminiOcrService(
      appCheckToken: () async => 'test-token',
      timeout: const Duration(milliseconds: 1),
      request: (_) {
        calls++;
        return pending.future;
      },
    );
    await expectLater(
      service.process(pdf, 'test.pdf'),
      throwsA(
        isA<CorrectionException>().having(
          (e) => e.message,
          'message',
          contains('AI response took too long'),
        ),
      ),
    );
    pending.complete(response());
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
  });
  test(
    'Duplicate submission is ignored and reset discards stale results',
    () async {
      final service = PendingService();
      final cubit = OcrCubit(service);
      cubit.emit(
        OcrState(status: OcrStatus.picked, fileName: 'a.pdf', inputBytes: pdf),
      );
      final pending = cubit.process();
      await cubit.process();
      expect(service.calls, 1);
      cubit.reset();
      service.result.complete(pdf);
      await pending;
      expect(cubit.state.status, OcrStatus.idle);
      await cubit.close();
    },
  );
}
