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
                        Color(0xFF0A0E1A),
                        Color(0xFF121A2B),
                        Color(0xFF1E2A44),
                      ]
                    : const [
                        Color(0xFFF3F8FF),
                        Color(0xFFF8FAFF),
                        Color(0xFFE8F0FF),
                      ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: TickerMode(
            enabled: shouldAnimate,
            child: EnchantedVisualizer(
              isPlaying: shouldAnimate,
              color: AppColors.primary,
              showWaves: false,
              height: 400,
            ),
          ),
        ),
      ],
    );
  }
}
