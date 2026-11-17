import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_demo/cubit/ocr_cubit.dart';
import 'package:ocr_demo/services/gemini_ocr_service.dart';

void main() {
  test('Dropped PDF uses the same selected state as a picked file', () async {
    final cubit = OcrCubit(GeminiOcrService(request: (_) async => null));
    final bytes = Uint8List.fromList('%PDF-1.7\n'.codeUnits);
    await cubit.dropFiles([XFile.fromData(bytes, path: 'algebra.PDF')]);
    expect(cubit.state.status, OcrStatus.picked);
    expect(cubit.state.fileName, 'algebra.PDF');
    expect(cubit.state.inputBytes, bytes);
    await cubit.close();
  });
  test('Rejects multiple, non-PDF, corrupt and oversized drops', () async {
    final cubit = OcrCubit(GeminiOcrService(request: (_) async => null));
    final pdf = XFile.fromData(
      Uint8List.fromList('%PDF-1.7'.codeUnits),
      path: 'a.pdf',
    );
    for (final files in [
      <XFile>[],
      [pdf, pdf],
      [XFile.fromData(Uint8List(1), path: 'a.png')],
      [XFile.fromData(Uint8List(12), path: 'a.pdf')],
      [
        XFile.fromData(
          Uint8List(GeminiOcrService.maxInputBytes + 1),
          path: 'big.pdf',
        ),
      ],
    ]) {
      cubit.reset();
      await cubit.dropFiles(files);
      expect(cubit.state.status, OcrStatus.failure);
      expect(cubit.state.inputBytes, isNull);
    }
    await cubit.close();
  });
}
