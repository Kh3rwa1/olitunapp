import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

class RhymeHeader extends ConsumerWidget {
  const RhymeHeader({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final l10n = AppLocalizations.of(context)!;
    final eyebrow = scriptMode == 'olchiki' ? 'ᱥᱟᱱᱛᱟᱲᱤ' : 'Santali';
    final title = scriptMode == 'olchiki' ? l10n.rhymes : 'Bakhed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      eyebrow,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                        color: isDark
                            ? AppColors.primary
                            : AppColors.primaryDark.withValues(alpha: 0.6),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 600.ms)
                    .slideY(begin: 0.5)
                    .then()
                    .shimmer(
                      delay: 1.seconds,
                      duration: 1800.ms,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                Text(
                      title,
                      style:
                          (scriptMode == 'olchiki'
                                  ? const TextStyle(fontFamily: 'OlChiki')
                                  : AppTypography.inter())
                              .copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                                height: 1,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryDark,
                              ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideX(begin: -0.15, curve: Curves.easeOutCubic)
                    .blurXY(begin: 4, end: 0, duration: 500.ms),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
              'Unlock the magic of stories & songs',
              style: AppTypography.inter(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 800.ms)
            .slideY(begin: 0.3, curve: Curves.easeOutCubic)
            .then(delay: 500.ms)
            .shimmer(
              duration: 2.seconds,
              color: (isDark ? Colors.white : AppColors.primary).withValues(
                alpha: 0.15,
              ),
            ),
      ],
    );
  }
}
