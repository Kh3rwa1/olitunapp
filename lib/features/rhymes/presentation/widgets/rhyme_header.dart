import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/theme/app_typography.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/widgets/eyebrow.dart';

/// Bakhed header: plain eyebrow, ink title, one quiet subtitle. The old
/// shimmering green title, grid paper and floating glyphs competed with the
/// cover art, which is the one thing this screen should show off.
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
        Eyebrow(
          eyebrow,
          uppercase: scriptMode != 'olchiki',
          color: isDark ? AppColors.primaryLight : AppColors.emeraldDeep,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style:
              (scriptMode == 'olchiki'
                      ? const TextStyle(fontFamily: 'OlChiki')
                      : AppTypography.inter())
                  .copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: isDark ? Colors.white : AppColors.webInk,
                  ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.unlockMagic,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: isDark ? Colors.white60 : AppColors.webSlate,
          ),
        ),
      ],
    );
  }
}
