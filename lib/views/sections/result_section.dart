import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../widgets/pdf_viewer.dart';
import '../widgets/result_toolbar.dart';

class ResultSection extends StatelessWidget {
  const ResultSection({super.key, required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResultToolbar(name: name),
          const SizedBox(height: 16),
          PdfViewer(bytes: bytes),
        ],
      ),
    );
  }
}
