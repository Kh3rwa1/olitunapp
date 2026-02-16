import 'dart:math' as math;
import 'package:flutter/material.dart';

class EnchantedVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final bool showWaves;
  final bool showParticles;
  final double height;

  const EnchantedVisualizer({
    super.key,
    required this.isPlaying,
    required this.color,
    this.showWaves = true,
    this.showParticles = true,
    this.height = 120,
  });

  @override
  State<EnchantedVisualizer> createState() => _EnchantedVisualizerState();
}

class _EnchantedVisualizerState extends State<EnchantedVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = List.generate(15, (index) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(EnchantedVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _EnchantedPainter(
            animationValue: _controller.value,
            isPlaying: widget.isPlaying,
            color: widget.color,
            particles: _particles,
            showWaves: widget.showWaves,
            showParticles: widget.showParticles,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 4 + 1;
  double speed = math.Random().nextDouble() * 0.015 + 0.002;
  double opacity = math.Random().nextDouble() * 0.5 + 0.2;

  void update() {
    y -= speed;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

class _EnchantedPainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;
  final Color color;
  final List<_Particle> particles;
  final bool showWaves;
  final bool showParticles;

  _EnchantedPainter({
    required this.animationValue,
    required this.isPlaying,
    required this.color,
    required this.particles,
    required this.showWaves,
    required this.showParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showParticles && isPlaying) {
      for (var particle in particles) {
        particle.update();
        final paint = Paint()
          ..color = color.withValues(alpha: 
            particle.opacity * (1.0 - (1.0 - particle.y).abs()),
          )
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(particle.x * size.width, particle.y * size.height),
          particle.size,
          paint,
        );
      }
    }

    if (showWaves) {
      final wavePaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      final path = Path();
      final waveHeight = isPlaying ? 15.0 : 4.0;
      final speed = animationValue * 2 * math.pi;

      path.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x++) {
        final y =
            size.height * 0.7 +
            math.sin(x * 0.03 + speed) * waveHeight +
            math.cos(x * 0.02 + speed * 0.6) * (waveHeight * 0.4);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, wavePaint);

      final wavePaint2 = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      final path2 = Path();
      path2.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x++) {
        final y =
            size.height * 0.75 +
            math.cos(x * 0.04 - speed * 0.8) * waveHeight +
            math.sin(x * 0.02 - speed * 1.2) * (waveHeight * 0.6);
        path2.lineTo(x, y);
      }
      path2.lineTo(size.width, size.height);
      path2.lineTo(0, size.height);
      path2.close();
      canvas.drawPath(path2, wavePaint2);
    }
  }

  @override
  bool shouldRepaint(covariant _EnchantedPainter oldDelegate) => true;
}
