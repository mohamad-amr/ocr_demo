import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/ocr_service.dart';
import '../services/gemini_ocr_service.dart';
part 'ocr_state.dart';

class OcrCubit extends Cubit<OcrState> {
  OcrCubit(this._service) : super(const OcrState());

  final OcrService _service;
  bool _picking = false;
  int _requestVersion = 0;

  Future<void> pickPdf() async {
    if (_picking || state.status == OcrStatus.processing) return;
    _picking = true;
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();
      GeminiOcrService.validatePdf(bytes);
      if (isClosed) return;
      emit(
        OcrState(
          status: OcrStatus.picked,
          fileName: file.name,
          inputBytes: bytes,
        ),
      );
    } catch (e) {
      _fail(e);
    } finally {
      _picking = false;
    }
  }

  Future<void> dropFiles(List<XFile> files) async {
    if (_picking || state.status == OcrStatus.processing) return;
    _picking = true;
    final version = _requestVersion;
    try {
      if (files.length != 1) {
        throw const CorrectionException('Drop one PDF at a time.');
      }
      final file = files.single;
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        throw const CorrectionException('Choose a PDF worksheet.');
      }
      if (await file.length() > GeminiOcrService.maxInputBytes) {
        throw const CorrectionException('Choose a PDF smaller than 10 MB.');
      }
      final bytes = await file.readAsBytes();
      GeminiOcrService.validatePdf(bytes);
      if (isClosed || version != _requestVersion) return;
      emit(
        OcrState(
          status: OcrStatus.picked,
          fileName: file.name,
          inputBytes: bytes,
        ),
      );
    } catch (e) {
      if (version == _requestVersion) _fail(e);
    } finally {
      _picking = false;
    }
  }

  Future<void> process() async {
    final input = state.inputBytes;
    if (input == null || state.status == OcrStatus.processing) return;

    final version = ++_requestVersion;
    emit(state.copyWith(status: OcrStatus.processing));
    try {
      final output = await _service.process(input, state.fileName!);
      if (isClosed || version != _requestVersion) return;
      emit(state.copyWith(status: OcrStatus.success, outputBytes: output));
    } catch (e) {
      if (version == _requestVersion) _fail(e);
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
        fileName: '${baseName}_correction.pdf',
        bytes: output,
        mimeType: 'application/pdf',
      );
      if (saved != null) emit(state.copyWith(message: 'Saved'));
    } catch (e) {
      emit(state.copyWith(message: '$e'));
    }
  }

  void reset() {
    _requestVersion++;
    emit(const OcrState());
  }

  void _fail(Object error) {
    if (!isClosed) {
      emit(state.copyWith(status: OcrStatus.failure, message: '$error'));
    }
  }
}
