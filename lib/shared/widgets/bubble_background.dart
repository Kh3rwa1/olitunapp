import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Premium animated background with floating orbs
class BubbleBackground extends StatefulWidget {
  final Widget child;
  final bool animate;
  final bool showOrbs;

  const BubbleBackground({
    super.key,
    required this.child,
    this.animate = true,
    this.showOrbs = true,
  });

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late List<_Orb> _orbs;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _generateOrbs();
  }

  void _generateOrbs() {
    final random = math.Random(42);
    _orbs = List.generate(8, (index) {
      return _Orb(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 20 + random.nextDouble() * 80,
        color: [
          AppColors.primary,
          AppColors.accentPurple,
          AppColors.accentPink,
          AppColors.accentMint,
        ][index % 4],
        floatOffset: random.nextDouble() * 2 * math.pi,
        pulseOffset: random.nextDouble() * 2 * math.pi,
      );
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
          ),
        ),

        // Animated orbs
        if (widget.showOrbs && widget.animate)
          AnimatedBuilder(
            animation: Listenable.merge([_floatController, _pulseController]),
            builder: (context, child) {
              return CustomPaint(
                painter: _OrbPainter(
                  orbs: _orbs,
                  floatValue: _floatController.value,
                  pulseValue: _pulseController.value,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),

        // Static orbs for non-animated version
        if (widget.showOrbs && !widget.animate)
          CustomPaint(
            painter: _OrbPainter(
              orbs: _orbs,
              floatValue: 0.5,
              pulseValue: 0.5,
              isDark: isDark,
            ),
            size: Size.infinite,
          ),

        // Child content
        widget.child,
      ],
    );
  }
}

class _Orb {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double floatOffset;
  final double pulseOffset;

  _Orb({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.floatOffset,
    required this.pulseOffset,
  });
}

class _OrbPainter extends CustomPainter {
  final List<_Orb> orbs;
  final double floatValue;
  final double pulseValue;
  final bool isDark;

  _OrbPainter({
    required this.orbs,
    required this.floatValue,
    required this.pulseValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final floatAnimation = math.sin(floatValue * math.pi * 2 + orb.floatOffset);
      final pulseAnimation = math.sin(pulseValue * math.pi * 2 + orb.pulseOffset);

      final x = orb.x * size.width + floatAnimation * 20;
      final y = orb.y * size.height + floatAnimation * 15;
      final radius = orb.radius + pulseAnimation * 10;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: isDark ? 0.08 : 0.12),
            orb.color.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(x, y), radius: radius),
        );

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) {
    return floatValue != oldDelegate.floatValue ||
        pulseValue != oldDelegate.pulseValue;
  }
}

/// Mesh gradient background - ultra premium
class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
          ),
        ),

        // Top-right accent
        Positioned(
          top: -200,
          right: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.15),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Bottom-left accent
        Positioned(
          bottom: -250,
          left: -200,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accentPurple.withValues(alpha: isDark ? 0.08 : 0.1),
                  AppColors.accentPurple.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Child
        child,
      ],
    );
  }
}

/// Gradient noise background for texture
class NoiseBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const NoiseBackground({
    super.key,
    required this.child,
    this.opacity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base color
        Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        ),

        // Noise texture overlay (simulated with dots)
        CustomPaint(
          painter: _NoisePainter(
            opacity: opacity,
            isDark: isDark,
          ),
          size: Size.infinite,
        ),

        // Child
        child,
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;
  final bool isDark;

  _NoisePainter({
    required this.opacity,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(0);
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);

    for (int i = 0; i < 2000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => false;
}
