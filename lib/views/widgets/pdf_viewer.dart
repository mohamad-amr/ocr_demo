import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// A document in the page's normal flow: no nested scroll area.
class PdfViewer extends StatefulWidget {
  const PdfViewer({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  final _pages = <ui.Image>[];
  bool _loading = true;
  String? _error;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(PdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) _render();
  }

  Future<void> _render() async {
    final version = ++_version;
    for (final image in _pages) {
      image.dispose();
    }
    _pages.clear();
    _loading = true;
    _error = null;
    try {
      // Paint the result shell before starting PDF.js/native raster work.
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted || version != _version) return;
      await for (final page in Printing.raster(widget.bytes, dpi: 96)) {
        if (!mounted || version != _version) return;
        // Use the decoded image directly. Native previews previously encoded
        // every raster as PNG only to immediately decode it again for display.
        final image = await page.toImage();
        if (!mounted || version != _version) {
          image.dispose();
          return;
        }
        setState(() => _pages.add(image));
        // Backpressure: show this page before asking the renderer for the next.
        await SchedulerBinding.instance.endOfFrame;
        if (!mounted || version != _version) return;
      }
    } catch (_) {
      if (mounted && version == _version) {
        setState(
          () => _error =
              'Preview could not load. You can still download the marked PDF.',
        );
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _version++;
    for (final image in _pages) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('pdf-pages'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < _pages.length; i++) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'PAGE ${i + 1}',
            style: const TextStyle(
              fontFamily: 'GeistMono',
              fontSize: 9,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: _pages[i].width / _pages[i].height,
            child: Semantics(
              image: true,
              label: 'Marked worksheet page ${i + 1}',
              child: RawImage(
                image: _pages[i],
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
      // Keep this slot after rendering, so finishing at the bottom does not
      // shrink the scroll extent and pull the reader backwards.
      SizedBox(
        height: 68,
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFB5A0DF),
                  ),
                )
              : Text(
                  _error == null ? 'End of document' : 'Preview incomplete',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
    ],
  );
}
