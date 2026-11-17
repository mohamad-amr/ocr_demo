import 'dart:async';
import 'dart:js_interop';
import 'package:ocr_demo/services/pdf_composer.dart';
import 'package:ocr_demo/services/pdf_worker_protocol.dart';

@JS('self.onmessage')
external set _onMessage(JSFunction callback);
@JS('self.postMessage')
external void _postMessage(JSAny? data);

extension type _Message._(JSObject _) implements JSObject {
  external JSAny? get data;
}

void main() {
  _onMessage = ((_Message event) {
    unawaited(_build(event));
  }).toJS;
}

Future<void> _build(_Message event) async {
  try {
    final message = event.data.dartify() as Map<Object?, Object?>;
    final bytes = await composeCorrectionPdf(decodePdfJob(message));
    _postMessage(bytes.toJS);
  } catch (_) {
    _postMessage('PDF build failed'.toJS);
  }
}
