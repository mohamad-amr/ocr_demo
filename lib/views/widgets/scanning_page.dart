import 'package:flutter/material.dart';

class ScanningPage extends StatefulWidget {
  const ScanningPage({super.key});
  @override
  State<ScanningPage> createState() => _ScanningPageState();
}

class _ScanningPageState extends State<ScanningPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = .5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, _) => CustomPaint(painter: _PagePainter(_controller.value)),
  );
}

class _PagePainter extends CustomPainter {
  const _PagePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final paper = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 2, size.width - 10, size.height - 4),
      const Radius.circular(6),
    );
    canvas.drawRRect(paper, Paint()..color = const Color(0xFF19171D));
    canvas.drawRRect(
      paper,
      Paint()
        ..color = const Color(0xFF776A8B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final ink = Paint()
      ..color = const Color(0xFF595160)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = 19.0 + i * 13;
      canvas.drawLine(
        Offset(16, y),
        Offset(size.width - (i.isEven ? 16 : 25), y),
        ink,
      );
    }
    final y = 12 + Curves.easeInOut.transform(progress) * (size.height - 24);
    canvas.drawLine(
      Offset(1, y),
      Offset(size.width - 1, y),
      Paint()
        ..color = const Color(0xFFBFA7E9)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PagePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
