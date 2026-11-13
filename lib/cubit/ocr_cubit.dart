import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/ocr_service.dart';
part 'ocr_state.dart';

class OcrCubit extends Cubit<OcrState> {
  OcrCubit(this._service) : super(const OcrState());

  final OcrService _service;

  Future<void> pickPdf() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (files.isEmpty) return;

      final file = files.first;
      emit(
        OcrState(
          status: OcrStatus.picked,
          fileName: file.name,
          inputBytes: await file.readAsBytes(),
        ),
      );
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> process() async {
    final input = state.inputBytes;
    if (input == null) return;

    emit(state.copyWith(status: OcrStatus.processing));
    try {
      final output = await _service.process(input, state.fileName!);
      emit(state.copyWith(status: OcrStatus.success, outputBytes: output));
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> download() async {
    final output = state.outputBytes;
    if (output == null) return;

    try {
      final baseName = state.fileName!.replaceAll(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      );
      final saved = await FilePicker.saveFile(
        fileName: '${baseName}_ocr.pdf',
        bytes: output,
        mimeType: 'application/pdf',
      );
      if (saved != null) emit(state.copyWith(message: 'Saved'));
    } catch (e) {
      emit(state.copyWith(message: '$e'));
    }
  }

  void reset() => emit(const OcrState());

  void _fail(Object error) =>
      emit(state.copyWith(status: OcrStatus.failure, message: '$error'));
}
