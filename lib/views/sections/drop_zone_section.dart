import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/ocr_cubit.dart';
import '../widgets/primary_button.dart';

class DropZoneSection extends StatelessWidget {
  const DropZoneSection({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      border: Border.all(color: Colors.white24),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        const Icon(Icons.upload_file_outlined, size: 30, color: Colors.white70),
        const SizedBox(height: 12),
        const Text(
          'Select your worksheet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        const Text(
          'PDF • Use a clear scan of your work',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Choose PDF',
          icon: Icons.add,
          onTap: () => context.read<OcrCubit>().pickPdf(),
        ),
      ],
    ),
  );
}
