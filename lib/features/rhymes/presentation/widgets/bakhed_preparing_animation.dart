import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import 'enchanted_visualizer.dart';

class BakhedPreparingAnimation extends ConsumerWidget {
  const BakhedPreparingAnimation({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.8);

    return Center(
      child: RepaintBoundary(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420, minHeight: 280),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.1),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: EnchantedVisualizer(
                        isPlaying: !reduceEffects,
                        color: AppColors.primary,
                        showParticles: !reduceEffects,
                        height: 132,
                      ),
                    ),
                    Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.primary,
                            size: 42,
                          ),
                        )
                        .animate(
                          target: reduceEffects ? 0 : 1,
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(0.96, 0.96),
                          end: const Offset(1.08, 1.08),
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Bakhed are being prepared',
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'New listening stories will appear here after publishing.',
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 15,
                  height: 1.35,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
