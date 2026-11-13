import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Cursor proximity lights the background without intercepting workspace input.
class MathAnimation extends StatefulWidget {
  const MathAnimation({super.key, required this.child});
  final Widget child;
  @override
  State<MathAnimation> createState() => _MathAnimationState();
}

class _MathAnimationState extends State<MathAnimation> {
  Offset _pointer = Offset.zero;
  bool _inside = false;
  static const symbols = [
    ('+', Offset(0.04, 0.12)),
    ('π', Offset(0.16, 0.05)),
    ('∑', Offset(0.24, 0.25)),
    ('÷', Offset(0.06, 0.40)),
    ('∫', Offset(0.17, 0.53)),
    ('≠', Offset(0.03, 0.73)),
    ('√', Offset(0.24, 0.84)),
    ('θ', Offset(0.12, 0.94)),
    ('×', Offset(0.79, 0.08)),
    ('∞', Offset(0.94, 0.19)),
    ('Δ', Offset(0.75, 0.37)),
    ('=', Offset(0.90, 0.48)),
    ('λ', Offset(0.80, 0.65)),
    ('±', Offset(0.96, 0.78)),
    ('∂', Offset(0.73, 0.93)),
    ('∏', Offset(0.89, 0.96)),
  ];

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (event) => setState(() {
        _inside = true;
        _pointer = event.localPosition;
      }),
      onHover: (event) => setState(() => _pointer = event.localPosition),
      onExit: (_) => setState(() => _inside = false),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, bounds) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _PaperTexture()),
                  ),
                ),
                IgnorePointer(
                  child: ExcludeSemantics(
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(end: _pointer),
                      duration: Duration(milliseconds: reduced ? 0 : 160),
                      curve: Curves.easeOutCubic,
                      builder: (context, pointer, _) =>
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: _inside ? 1.0 : 0.0),
                            duration: Duration(milliseconds: reduced ? 0 : 300),
                            builder: (context, visibility, _) => Stack(
                              children: [
                                Positioned(
                                  left: pointer.dx - 220,
                                  top: pointer.dy - 220,
                                  child: Container(
                                    width: 440,
                                    height: 440,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFFA78BFA).withValues(
                                            alpha: 0.045 * visibility,
                                          ),
                                          const Color(0xFF8B5CF6).withValues(
                                            alpha: 0.012 * visibility,
                                          ),
                                          const Color(0x008B5CF6),
                                        ],
                                        stops: const [0, 0.4, 1],
                                      ),
                                    ),
                                  ),
                                ),
                                for (final item in symbols)
                                  _symbol(
                                    item,
                                    bounds,
                                    pointer,
                                    visibility,
                                    reduced,
                                  ),
                              ],
                            ),
                          ),
                    ),
                  ),
                ),
                widget.child,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _symbol(
    (String, Offset) item,
    BoxConstraints bounds,
    Offset pointer,
    double visibility,
    bool reduced,
  ) {
    final origin = Offset(
      (bounds.maxWidth - 80) * item.$2.dx + 24,
      (bounds.maxHeight - 80) * item.$2.dy + 24,
    );
    final delta = pointer - (origin + const Offset(15, 15));
    final strength =
        math.pow((1 - delta.distance / 210).clamp(0.0, 1.0), 1.5).toDouble() *
        visibility;
    final shift = reduced ? Offset.zero : delta * (0.035 * strength);
    return Positioned(
      left: origin.dx + shift.dx,
      top: origin.dy + shift.dy,
      child: Transform.scale(
        scale: reduced ? 1 : 1 + strength * 0.12,
        child: Text(
          item.$1,
          style: TextStyle(
            fontFamily: 'GeistMono',
            fontSize: bounds.maxWidth < 760 ? 20 : 30,
            height: 1.2,
            fontWeight: FontWeight.w300,
            color: Color.lerp(
              const Color(0xFF393340),
              const Color(0xFFF3ECFF),
              strength,
            ),
            shadows: [
              Shadow(
                color: const Color(
                  0xFFA78BFA,
                ).withValues(alpha: strength * 0.3),
                blurRadius: 4 + strength * 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deterministic grain and drafting lines, softened beneath the workspace.
class _PaperTexture extends CustomPainter {
  const _PaperTexture();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += 24) {
      line.color = (x % 120 == 0)
          ? const Color(0x162D283B)
          : const Color(0x0DFFFFFF);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += 24) {
      line.color = (y % 120 == 0)
          ? const Color(0x22A78BFA)
          : const Color(0x0DFFFFFF);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final grain = Paint();
    final random = math.Random(26);
    final count = (size.width * size.height / 100).round();
    for (var i = 0; i < count; i++) {
      grain.color = Colors.white.withValues(
        alpha: 0.025 + random.nextDouble() * 0.045,
      );
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.3 + random.nextDouble() * 0.4,
        grain,
      );
    }
    final cross = Paint()
      ..color = const Color(0x30A78BFA)
      ..strokeWidth = 0.7;
    for (double x = 48; x < size.width; x += 120) {
      for (double y = 48; y < size.height; y += 120) {
        canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), cross);
        canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), cross);
      }
    }
    // A dark center keeps texture away from the main reading area.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.7,
          colors: [Color(0xF2090909), Color(0xC0090909), Color(0x00090909)],
          stops: [0, 0.38, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _PaperTexture oldDelegate) => false;
}
