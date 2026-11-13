import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/ocr_cubit.dart';
import '../widgets/file_chip.dart';
import '../widgets/primary_button.dart';

class PickedSection extends StatelessWidget {
  const PickedSection({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OcrCubit>();
    return SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FileChip(name: name),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Generate demo result',
            icon: Icons.auto_awesome_rounded,
            onTap: () => cubit.process(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => cubit.reset(),
            child: const Text(
              'Choose another',
              style: TextStyle(color: Color(0xFF9297AD)),
            ),
          ),
        ],
      ),
    );
  }
}
