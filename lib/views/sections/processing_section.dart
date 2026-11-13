import 'package:flutter/material.dart';

import '../widgets/scanning_page.dart';

class ProcessingSection extends StatelessWidget {
  const ProcessingSection({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 100, child: FittedBox(child: ScanningPage())),
          const SizedBox(height: 16),
          const Text(
            'Preparing your demo…',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9297AD)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const SizedBox(
              width: 240,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFFA794FF),
                backgroundColor: Color(0xFF303244),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
