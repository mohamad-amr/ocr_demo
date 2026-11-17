import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/ocr_cubit.dart';
import 'primary_button.dart';

class ResultToolbar extends StatelessWidget {
  const ResultToolbar({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OcrCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your marked worksheet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF9297AD)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PrimaryButton(
              label: 'Download marked PDF',
              icon: Icons.download_rounded,
              onTap: () => cubit.download(),
              compact: true,
            ),
            TextButton(
              onPressed: cubit.reset,
              child: const Text('Start again'),
            ),
          ],
        ),
      ],
    );
  }
}
