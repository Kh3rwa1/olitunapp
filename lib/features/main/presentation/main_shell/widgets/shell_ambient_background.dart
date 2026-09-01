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
                        AppColors.translatorDarkBg,
                        AppColors.translatorDarkMid,
                        AppColors.translatorDarkLight,
                      ]
                    : const [
                        AppColors.translatorLightCardA,
                        AppColors.translatorLightCardB,
                        AppColors.translatorLightCardC,
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
