import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Confetti celebration overlay
class ConfettiOverlay extends StatefulWidget {
  final bool show;
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    required this.show,
    this.duration = const Duration(milliseconds: 2500),
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Confetti> _confetti;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _confetti = List.generate(50, (_) => _Confetti.random(_random));
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _confetti = List.generate(50, (_) => _Confetti.random(_random));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              confetti: _confetti,
              animationValue: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Confetti {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double rotationSpeed;
  final Color color;
  final _Shape shape;
  final double wobble;

  _Confetti({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.rotationSpeed,
    required this.color,
    required this.shape,
    required this.wobble,
  });

  factory _Confetti.random(math.Random random) {
    final colors = [
      AppColors.primaryCyan,
      AppColors.accentCoral,
      AppColors.accentYellow,
      AppColors.success,
      AppColors.accentCoral,
      AppColors.primaryTeal,
    ];

    return _Confetti(
      x: random.nextDouble(),
      startY: -0.1 - random.nextDouble() * 0.3,
      size: 6 + random.nextDouble() * 8,
      speed: 0.5 + random.nextDouble() * 0.5,
      rotationSpeed: 2 + random.nextDouble() * 4,
      color: colors[random.nextInt(colors.length)],
      shape: _Shape.values[random.nextInt(_Shape.values.length)],
      wobble: random.nextDouble() * 0.1,
    );
  }
}

enum _Shape { circle, square, star }

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double animationValue;

  _ConfettiPainter({
    required this.confetti,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final paint = Paint()
        ..color = c.color.withValues(alpha: 1.0 - animationValue * 0.5)
        ..style = PaintingStyle.fill;

      final x = c.x * size.width +
          math.sin(animationValue * math.pi * 4 + c.wobble * 10) * 30;
      final y = c.startY * size.height +
          animationValue * size.height * c.speed * 1.5;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(animationValue * math.pi * c.rotationSpeed);

      switch (c.shape) {
        case _Shape.circle:
          canvas.drawCircle(Offset.zero, c.size / 2, paint);
          break;
        case _Shape.square:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size),
              const Radius.circular(2),
            ),
            paint,
          );
          break;
        case _Shape.star:
          _drawStar(canvas, c.size, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = size / 4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * math.pi / 180;

      if (i == 0) {
        path.moveTo(
          outerRadius * math.cos(outerAngle),
          outerRadius * math.sin(outerAngle),
        );
      } else {
        path.lineTo(
          outerRadius * math.cos(outerAngle),
          outerRadius * math.sin(outerAngle),
        );
      }

      path.lineTo(
        innerRadius * math.cos(innerAngle),
        innerRadius * math.sin(innerAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Star burst animation for correct answers
class StarBurst extends StatefulWidget {
  final bool show;
  final Color? color;

  const StarBurst({
    super.key,
    required this.show,
    this.color,
  });

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(StarBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    final color = widget.color ?? AppColors.accentYellow;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _StarBurstPainter(
            animationValue: _controller.value,
            color: color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _StarBurstPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _StarBurstPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw expanding stars
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final distance = animationValue * maxRadius;
      final opacity = (1.0 - animationValue).clamp(0.0, 1.0);
      final starSize = 12 * (1 + animationValue * 0.5);

      final starCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(starCenter.dx, starCenter.dy);
      canvas.rotate(animationValue * math.pi);
      _drawStar(canvas, starSize, paint);
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = size / 4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * math.pi / 180;

      if (i == 0) {
        path.moveTo(
          outerRadius * math.cos(outerAngle),
          outerRadius * math.sin(outerAngle),
        );
      } else {
        path.lineTo(
          outerRadius * math.cos(outerAngle),
          outerRadius * math.sin(outerAngle),
        );
      }

      path.lineTo(
        innerRadius * math.cos(innerAngle),
        innerRadius * math.sin(innerAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarBurstPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
