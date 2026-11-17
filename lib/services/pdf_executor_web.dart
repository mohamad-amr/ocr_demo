import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'pdf_composer.dart';

@JS('Worker')
extension type _PdfWorker._(JSObject _) implements JSObject {
  external _PdfWorker(String url);
  external set onmessage(JSFunction callback);
  external set onerror(JSFunction callback);
  external set onmessageerror(JSFunction callback);
  external void postMessage(JSAny? data);
  external void terminate();
}

extension type _Message._(JSObject _) implements JSObject {
  external JSAny? get data;
}

@JS('document.baseURI')
external String get _baseUri;

Future<Uint8List> executePdfBuild(PdfBuildJob job) async {
  final worker = _PdfWorker(
    Uri.parse(
      _baseUri,
    ).resolve('assets/assets/workers/pdf_builder.js').toString(),
  );
  final completion = Completer<Uint8List>();
  void fail() {
    if (!completion.isCompleted) {
      completion.completeError(
        StateError(
          'The PDF background worker failed. Check that pdf_builder.js is deployed and allowed by the site CSP.',
        ),
      );
    }
  }

  worker.onmessage = ((_Message event) {
    if (completion.isCompleted) return;
    final data = event.data.dartify();
    if (data is Uint8List) {
      completion.complete(data);
    } else {
      fail();
    }
  }).toJS;
  worker.onerror = ((JSAny? _) {
    fail();
  }).toJS;
  worker.onmessageerror = ((JSAny? _) {
    fail();
  }).toJS;
  try {
    worker.postMessage(job.toMessage().jsify());
    return await completion.future.timeout(const Duration(seconds: 90));
  } finally {
    worker.terminate();
  }
}
