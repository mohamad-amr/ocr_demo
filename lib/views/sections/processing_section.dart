import 'package:flutter/material.dart';
import '../widgets/scanning_page.dart';

class ProcessingSection extends StatelessWidget {
  const ProcessingSection({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 236,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          key: ValueKey('processing-icon'),
          width: 64,
          height: 80,
          child: ScanningPage(),
        ),
        const SizedBox(height: 22),
        const Text(
          'Reviewing your work',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 18),
        const SizedBox(
          width: 160,
          child: LinearProgressIndicator(
            minHeight: 2,
            color: Color(0xFFB5A0DF),
            backgroundColor: Color(0xFF29262F),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Reading each step and preparing your marked PDF.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    ),
  );
}
