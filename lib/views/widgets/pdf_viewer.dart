import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfViewer extends StatelessWidget {
  const PdfViewer({super.key, required this.bytes, this.height = 520});
  final Uint8List bytes;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFA794FF), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: PdfPreview(
        build: (_) async => bytes,
        useActions: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        pdfPreviewPageDecoration: const BoxDecoration(color: Colors.white),
        scrollViewDecoration: const BoxDecoration(color: Color(0xFFF2F2F2)),
      ),
    );
  }
}
