import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/local_settings_provider.dart';

class TypingCompleteCelebration extends ConsumerStatefulWidget {
  final String targetText;

  const TypingCompleteCelebration({
    super.key,
    required this.targetText,
  });

  @override
  ConsumerState<TypingCompleteCelebration> createState() => _TypingCompleteCelebrationState();
}

class _TypingCompleteCelebrationState extends ConsumerState<TypingCompleteCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final List<_ConfettiParticle> _particles;
  late final Random _random;

  @override
  void initState() {
    super.initState();
    // Deterministic seed for robust golden tests, unseeded in production
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    _random = isTest ? Random(42) : Random();

    // 1500ms hard ceiling for performance optimization
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    // Initialize 40 colorful random particles
    _particles = List.generate(40, (_) => _generateParticle());

    _controller.forward();
  }

  _ConfettiParticle _generateParticle() {
    final colors = [
      AppColors.primary,
      Colors.amberAccent,
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.deepPurpleAccent,
    ];
    return _ConfettiParticle(
      color: colors[_random.nextInt(colors.length)],
      angle: _random.nextDouble() * 2 * pi,
      speed: _random.nextDouble() * 120 + 60,
      size: _random.nextDouble() * 8 + 6,
      rotation: _random.nextDouble() * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 5,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceVisualEffectsProvider);

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.4),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Confetti Particle Custom Painter (skipped in motion-reduced mode)
          if (!reduceMotion)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          // 2. Celebratory Content (Bounce scale checkmark + target text)
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.glowShadow(AppColors.primary),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.targetText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'OlChiki',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double angle;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Decay functions for fade out and scale down
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final scale = (1.0 - progress * 0.8).clamp(0.0, 1.0);

    for (final p in particles) {
      // Calculate radial displacement
      final distance = p.speed * progress;
      final dx = cos(p.angle) * distance;
      final dy = sin(p.angle) * distance + (progress * progress * 80); // add subtle gravity drift

      final pos = center + Offset(dx, dy);
      final currentSize = p.size * scale;

      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotation + p.rotationSpeed * progress);

      // Draw random shapes (squares or diamonds)
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: currentSize, height: currentSize),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
