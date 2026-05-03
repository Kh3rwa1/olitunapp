import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One-shot confetti burst (CustomPainter, no asset/package).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.particleCount = 36,
    this.duration = const Duration(milliseconds: 1600),
    this.colors = const [
      Color(0xFF7C5CFF),
      Color(0xFFFF7AC6),
      Color(0xFFFFC857),
      Color(0xFF34D399),
      Color(0xFF60A5FA),
    ],
  });

  final int particleCount;
  final Duration duration;
  final List<Color> colors;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  late final List<_Particle> _particles = _build();

  List<_Particle> _build() {
    final rng = math.Random();
    return List.generate(widget.particleCount, (i) {
      final angle = (math.pi * 2) * (i / widget.particleCount) +
          rng.nextDouble() * 0.4;
      final speed = 180 + rng.nextDouble() * 220;
      return _Particle(
        angle: angle,
        speed: speed,
        size: 6 + rng.nextDouble() * 6,
        spin: (rng.nextDouble() - 0.5) * 8,
        color: widget.colors[rng.nextInt(widget.colors.length)],
        delay: rng.nextDouble() * 0.15,
      );
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(
            t: _ctl.value,
            particles: _particles,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
    required this.delay,
  });

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final Color color;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.particles});

  final double t;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    for (final p in particles) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;

      final dx = math.cos(p.angle) * p.speed * lt;
      // Vertical: initial upward burst, then gravity pulls down.
      final dy = math.sin(p.angle) * p.speed * lt + 320 * lt * lt;
      final pos = origin + Offset(dx, dy);

      final paint = Paint()
        ..color = p.color.withValues(alpha: 1 - lt)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * lt);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.t != t || old.particles != particles;
}
