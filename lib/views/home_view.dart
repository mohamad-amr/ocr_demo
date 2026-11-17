import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ocr_cubit.dart';
import 'sections/drop_zone_section.dart';
import 'sections/picked_section.dart';
import 'sections/processing_section.dart';
import 'sections/result_section.dart';
import 'widgets/math_animation.dart';
import 'widgets/stage_transition.dart';
import 'widgets/workflow_steps.dart';

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
        child: MathAnimation(
          child: LayoutBuilder(
            builder: (context, bounds) => SingleChildScrollView(
              key: const ValueKey('page-scroll'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                          'OCR / GEMINI',
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
                    ConstrainedBox(
                      // Keep short stages centered, but let a PDF grow naturally.
                      constraints: BoxConstraints(
                        minHeight: (bounds.maxHeight - 110).clamp(
                          0.0,
                          double.infinity,
                        ),
                      ),
                      child: Center(
                        child: BlocBuilder<OcrCubit, OcrState>(
                          builder: (context, state) => ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: state.status == OcrStatus.success
                                  ? 900
                                  : 560,
                            ),
                            child: _Workspace(state: state),
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
    ),
  );
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.state});
  final OcrState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Your work. A closer look.',
          style: TextStyle(
            fontSize: 30,
            height: 1.1,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Keep your handwriting. Get corrections on the page.',
          style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 22),
        Container(
          key: const ValueKey('workspace-panel'),
          decoration: BoxDecoration(
            color: const Color(0xFF111113),
            border: Border.all(color: const Color(0xFF302D35)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkflowSteps(status: state.status),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  // A growing PDF must not animate its entire height: that
                  // shifts already visible pages while the user is scrolling.
                  child: state.status == OcrStatus.success
                      ? _section()
                      : StageTransition(child: _section()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your PDF is sent to Google for review. Check the marks before relying on them.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.5),
        ),
      ],
    ),
  );

  Widget _section() {
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
        );
    }
  }
}
