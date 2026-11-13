import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ocr_cubit.dart';
import 'sections/drop_zone_section.dart';
import 'sections/picked_section.dart';
import 'sections/processing_section.dart';
import 'sections/result_section.dart';
import 'widgets/math_animation.dart';
import 'widgets/stage_transition.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => BlocListener<OcrCubit, OcrState>(
    listenWhen: (p, c) => c.message != null && p.message != c.message,
    listener: (context, state) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message!)));
    },
    child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text(
                        '∑',
                        style: TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 28,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'MathLens',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'OCR / DEMO',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.white12),
                  Expanded(
                    child: MathAnimation(
                      child: Center(
                        child: BlocBuilder<OcrCubit, OcrState>(
                          builder: (context, state) => ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: state.status == OcrStatus.success
                                  ? 900
                                  : 480,
                            ),
                            child: _Workspace(state: state),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 12),
                  const Text(
                    '© Mohamed Amr 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'GeistMono',
                      fontSize: 11,
                      letterSpacing: 1.6,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.state});
  final OcrState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      return SingleChildScrollView(
        key: const ValueKey('workspace-scroll'),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: bounds.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check your math.',
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    letterSpacing: -1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Upload a PDF of your handwritten solution.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: List.generate(3, (i) {
                    final active = switch (state.status) {
                      OcrStatus.processing => 1,
                      OcrStatus.success => 2,
                      _ => 0,
                    };
                    return Expanded(
                      child: Text(
                        ['01 / Upload', '02 / Process', '03 / Result'][i],
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'GeistMono',
                          color: i == active
                              ? const Color(0xFFA78BFA)
                              : Colors.white38,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                StageTransition(child: _section(bounds.maxHeight)),
                const SizedBox(height: 12),
                const Text(
                  'Demo only. AI correction is not connected.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _section(double height) {
    switch (state.status) {
      case OcrStatus.idle:
      case OcrStatus.failure when state.fileName == null:
        return const DropZoneSection(key: ValueKey('idle'));
      case OcrStatus.picked:
      case OcrStatus.failure:
        return PickedSection(
          key: const ValueKey('picked'),
          name: state.fileName!,
        );
      case OcrStatus.processing:
        return ProcessingSection(
          key: const ValueKey('processing'),
          name: state.fileName!,
        );
      case OcrStatus.success:
        return ResultSection(
          key: const ValueKey('result'),
          name: state.fileName!,
          bytes: state.outputBytes!,
          previewHeight: (height - 300).clamp(120, 520),
        );
    }
  }
}
