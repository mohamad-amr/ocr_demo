part of 'ocr_cubit.dart';

enum OcrStatus { idle, picked, processing, success, failure }

class OcrState extends Equatable {
  const OcrState({
    this.status = OcrStatus.idle,
    this.fileName,
    this.inputBytes,
    this.outputBytes,
    this.message,
  });

  final OcrStatus status;
  final String? fileName;
  final Uint8List? inputBytes;
  final Uint8List? outputBytes;

  /// One-shot feedback (error or confirmation) for the UI to show once.
  /// It is cleared automatically on the next emitted state.
  final String? message;

  OcrState copyWith({
    OcrStatus? status,
    Uint8List? outputBytes,
    String? message,
  }) => OcrState(
    status: status ?? this.status,
    fileName: fileName,
    inputBytes: inputBytes,
    outputBytes: outputBytes ?? this.outputBytes,
    message: message,
  );

  @override
  List<Object?> get props => [
    status,
    fileName,
    inputBytes,
    outputBytes,
    message,
  ];
}
