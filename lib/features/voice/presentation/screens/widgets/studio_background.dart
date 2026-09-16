import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../rhymes/presentation/widgets/enchanted_visualizer.dart';

/// Premium gradient + ambient visualizer behind the studio.
class StudioBackground extends StatelessWidget {
  const StudioBackground({super.key, required this.isDark});

  final bool isDark;

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
        const Positioned.fill(
          child: EnchantedVisualizer(
            isPlaying: true,
            color: AppColors.primary,
            showWaves: false,
            height: 400,
          ),
        ),
      ],
    );
  }
}
