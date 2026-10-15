import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/minimum_tap_target.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'onboarding_selection_item.dart';

class OnboardingScriptStep extends StatelessWidget {
  const OnboardingScriptStep({
    super.key,
    required this.isDark,
    required this.selectedScriptMode,
    required this.onSelected,
  });

  final bool isDark;
  final String selectedScriptMode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scriptModes = [
      OnboardingSelectionItem(
        value: 'both',
        title: 'Ol Chiki + Latin',
        subtitle: 'See phonetic transliterations below the script',
        icon: Icons.chrome_reader_mode_rounded,
      ),
      OnboardingSelectionItem(
        value: 'olchiki',
        title: 'Ol Chiki only',
        subtitle: 'Focus entirely on the native script characters',
        icon: Icons.language_rounded,
      ),
      OnboardingSelectionItem(
        value: 'latin',
        title: 'Latin only',
        subtitle: 'Read Santali spelled in standard Latin alphabet',
        icon: Icons.abc_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.displayTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.displaySubtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ...scriptModes.map((item) {
            final isSelected = selectedScriptMode == item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(item.value as String);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.10))
                        : (isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isDark ? Colors.white10 : Colors.black12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// STEP 4: DAILY GOAL
