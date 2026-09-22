import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bento_grid.dart';
import '../../../../core/motion/motion.dart';
import '../../../quiz/presentation/providers/mistake_provider.dart';

class MistakeReviewCard extends ConsumerWidget {
  final int? mistakeCount;
  final VoidCallback? onTap;
  final String ctaLabel;
  final int animationIndex;

  const MistakeReviewCard({
    super.key,
    this.mistakeCount,
    this.onTap,
    this.ctaLabel = 'Practice Now',
    this.animationIndex = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = mistakeCount == null ? ref.watch(mistakeProvider) : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final count = mistakeCount ?? mistakes!.length;

    if (count <= 0) return const SizedBox.shrink();

    return AnimatedBentoChild(
      index: animationIndex,
      child: PressableScale(
        onTap: onTap ?? () => context.push('/mistakes'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.mistakeCardDarkTop.withValues(alpha: 0.8),
                      AppColors.mistakeCardDarkBottom.withValues(alpha: 0.6),
                    ]
                  : [
                      AppColors.mistakeCardLightTop,
                      AppColors.mistakeCardLightBottom,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.mistakeCardDarkBorder.withValues(alpha: 0.5)
                  : AppColors.mistakeCardLightBorder.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.red.shade100).withValues(
                  alpha: isDark ? 0.3 : 0.4,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.mistakeBadgeDarkBg.withValues(alpha: 0.3)
                          : AppColors.mistakeBadgeLightBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.healing_rounded,
                      color: isDark
                          ? AppColors.mistakeBadgeDarkFg
                          : Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MISTAKE REVIEW',
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.mistakeBadgeDarkFg
                          : Colors.red.shade700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.mistakeBadgeDarkBg.withValues(alpha: 0.5)
                          : AppColors.mistakeBadgeLightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Takes 2 min',
                      style: AppTypography.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.mistakeBadgeDarkFg
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$count word${count > 1 ? 's' : ''} need${count > 1 ? '' : 's'} practice',
                style: AppTypography.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '“Mistakes are just lessons asking for a second chance.”',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    ctaLabel,
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.mistakeBadgeDarkFg
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: isDark
                        ? AppColors.mistakeBadgeDarkFg
                        : Colors.red.shade700,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
