import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/ocr_cubit.dart';
import '../widgets/primary_button.dart';

class DropZoneSection extends StatefulWidget {
  const DropZoneSection({super.key});
  @override
  State<DropZoneSection> createState() => _DropZoneSectionState();
}

class _DropZoneSectionState extends State<DropZoneSection> {
  bool _dragging = false;
  bool _reading = false;

  @override
  Widget build(BuildContext context) {
    final supportsDrop =
        kIsWeb ||
        switch (defaultTargetPlatform) {
          TargetPlatform.macOS ||
          TargetPlatform.windows ||
          TargetPlatform.linux => true,
          _ => false,
        };
    final surface = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: _dragging ? const Color(0xFF211B2F) : const Color(0xFF141416),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        foregroundPainter: _DropBorder(
          _dragging ? const Color(0xFFA78BFA) : const Color(0xFF39373F),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSlide(
              offset: _dragging ? const Offset(0, -.08) : Offset.zero,
              duration: const Duration(milliseconds: 160),
              child: const _WorksheetIcon(),
            ),
            const SizedBox(height: 14),
            Text(
              _reading
                  ? 'Opening your worksheet…'
                  : _dragging
                  ? 'Drop your worksheet here'
                  : supportsDrop
                  ? 'Drop your worksheet here'
                  : 'Choose your worksheet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -.35,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'PDF · up to 10 MB · 20 pages',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 174,
              child: PrimaryButton(
                label: 'Choose PDF',
                icon: Icons.add_rounded,
                compact: true,
                onTap: () => context.read<OcrCubit>().pickPdf(),
              ),
            ),
          ],
        ),
      ),
    );
    if (!supportsDrop) return surface;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) async {
        setState(() {
          _dragging = false;
          _reading = true;
        });
        await context.read<OcrCubit>().dropFiles(details.files);
        if (mounted) setState(() => _reading = false);
      },
      child: surface,
    );
  }
}

class _WorksheetIcon extends StatelessWidget {
  const _WorksheetIcon();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 58,
    height: 66,
    child: Stack(
      children: [
        Positioned(
          left: 10,
          top: 1,
          child: Transform.rotate(
            angle: .09,
            child: Container(
              width: 42,
              height: 57,
              decoration: BoxDecoration(
                color: const Color(0xFF242029),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        Positioned(
          left: 3,
          top: 4,
          child: Container(
            width: 43,
            height: 57,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border.all(color: const Color(0xFF66616F)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.functions_rounded,
              size: 23,
              color: Colors.white60,
            ),
          ),
        ),
        const Positioned(
          right: 0,
          bottom: 0,
          child: Icon(
            Icons.add_circle_rounded,
            color: Color(0xFFB5A0DF),
            size: 23,
          ),
        ),
      ],
    ),
  );
}

class _DropBorder extends CustomPainter {
  const _DropBorder(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    // Corner guides suggest a page frame without a heavy second card border.
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const length = 12.0;
    final r = Rect.fromLTWH(-6, -10, size.width + 12, size.height + 20);
    for (final corner in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      final dx = corner.dx == r.left ? length : -length;
      final dy = corner.dy == r.top ? length : -length;
      canvas.drawLine(corner, corner + Offset(dx, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, dy), paint);
    }
  }

  @override
  bool shouldRepaint(_DropBorder oldDelegate) => color != oldDelegate.color;
}
