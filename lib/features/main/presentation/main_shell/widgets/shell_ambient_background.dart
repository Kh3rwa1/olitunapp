import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../rhymes/presentation/widgets/enchanted_visualizer.dart';

class ShellAmbientBackground extends StatelessWidget {
  final bool isDark;
  final bool shouldAnimate;

  const ShellAmbientBackground({
    super.key,
    required this.isDark,
    required this.shouldAnimate,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        AppColors.bakhedBackground,
                        AppColors.nightGreen,
                        AppColors.nightBlue,
                      ]
                    : const [
                        AppColors.webCanvasWarm,
                        AppColors.mintWash,
                        AppColors.skyWash,
                      ],
              ),
            ),
          ),
        ),
        // Emerald mist — top center glow, always on for premium depth.
        Positioned(
          top: -140,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: isDesktop ? 900 : 560,
                height: isDesktop ? 420 : 320,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.14),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Cool sky orb — right edge, balances the emerald warmth.
        Positioned(
          top: isDesktop ? 180 : 120,
          right: -100,
          child: IgnorePointer(
            child: Container(
              width: isDesktop ? 420 : 260,
              height: isDesktop ? 420 : 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF38BDF8,
                    ).withValues(alpha: isDark ? 0.10 : 0.10),
                    AppColors.skyBright.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Violet whisper — bottom left, visible on tall desktop canvases.
        if (isDesktop)
          Positioned(
            bottom: -120,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF8B5CF6,
                      ).withValues(alpha: isDark ? 0.08 : 0.06),
                      AppColors.accentPurple.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Fine grid — product-surface texture, desktop only.
        if (isDesktop)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.5 : 0.6,
                child: CustomPaint(painter: _WebGridPainter(isDark: isDark)),
              ),
            ),
          ),
        Positioned.fill(
          child: TickerMode(
            enabled: shouldAnimate,
            child: Opacity(
              opacity: isDark ? 0.5 : 0.35,
              child: EnchantedVisualizer(
                isPlaying: shouldAnimate,
                color: AppColors.primary,
                showWaves: false,
                height: 400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WebGridPainter extends CustomPainter {
  final bool isDark;
  const _WebGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : AppColors.webInk).withValues(
        alpha: isDark ? 0.035 : 0.045,
      )
      ..strokeWidth = 1;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WebGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
