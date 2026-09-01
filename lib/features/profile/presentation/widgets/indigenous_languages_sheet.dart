import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/languages/language_registry.dart';
import '../../../../core/languages/models/language_manifest.dart';
import '../../../../core/languages/providers/target_language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/script_typography_registry.dart';

class IndigenousLanguagesSheet extends ConsumerWidget {
  const IndigenousLanguagesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return const IndigenousLanguagesSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCode = ref.watch(targetLanguageCodeProvider);
    const languages = LanguageRegistry.allLanguages;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: AppRadius.topXxl,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Sheet Header
              Text(
                'Indigenous Languages Platform',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Explore native scripts & tribal languages of eastern India',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Language Cards
              for (final manifest in languages) ...[
                _LanguageManifestCard(
                  manifest: manifest,
                  isSelected: manifest.code == activeCode,
                  isDark: isDark,
                  onSelect: () {
                    HapticFeedback.selectionClick();
                    if (manifest.readiness == LanguageReadiness.comingSoon) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${manifest.name} content & audio packs are coming soon!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    ref
                        .read(targetLanguageCodeProvider.notifier)
                        .selectLanguage(manifest.code);
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Learning language set to ${manifest.name} (${manifest.scriptName})',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageManifestCard extends StatelessWidget {
  final LanguageManifest manifest;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onSelect;

  const _LanguageManifestCard({
    required this.manifest,
    required this.isSelected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeLabel;

    switch (manifest.readiness) {
      case LanguageReadiness.active:
        badgeColor = AppColors.success;
        badgeLabel = 'ACTIVE';
        break;
      case LanguageReadiness.preview:
        badgeColor = AppColors.accentOchre;
        badgeLabel = 'PREVIEW';
        break;
      case LanguageReadiness.comingSoon:
        badgeColor = Colors.grey;
        badgeLabel = 'COMING SOON';
        break;
    }

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02)),
          borderRadius: AppRadius.borderXl,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Names & Readiness badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manifest.nativeName,
                        style: ScriptTypographyRegistry.getStyle(
                          languageCode: manifest.code,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${manifest.name} • ${manifest.scriptName}',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              manifest.description,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Sample Glyphs Row
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: manifest.sampleGlyphs.map((glyph) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    glyph,
                    style: ScriptTypographyRegistry.getStyle(
                      languageCode: manifest.code,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Capabilities Row
            Row(
              children: [
                if (manifest.audioPackSupported) ...[
                  const Icon(
                    Icons.headphones_rounded,
                    size: 14,
                    color: AppColors.accentOchre,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Audio Pack',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (manifest.offlineLessonsSupported) ...[
                  const Icon(
                    Icons.download_done_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offline Lessons',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  '${manifest.alphabetLetterCount} letters',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
