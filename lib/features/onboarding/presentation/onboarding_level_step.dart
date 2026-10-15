import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/minimum_tap_target.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'onboarding_selection_item.dart';

class OnboardingLevelStep extends StatelessWidget {
  const OnboardingLevelStep({
    super.key,
    required this.isDark,
    required this.selectedLevel,
    required this.onSelected,
  });

  final bool isDark;
  final LearnerLevel selectedLevel;
  final ValueChanged<LearnerLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    final levels = [
      OnboardingSelectionItem(
        value: LearnerLevel.beginner,
        title: "I'm completely new",
        subtitle: 'Start from the very first letter',
        icon: Icons.baby_changing_station_rounded,
      ),
      OnboardingSelectionItem(
        value: LearnerLevel.familiar,
        title: 'I know some letters',
        subtitle: 'Review alphabet and simple characters',
        icon: Icons.auto_awesome_rounded,
      ),
      OnboardingSelectionItem(
        value: LearnerLevel.basicReader,
        title: 'I can read basic words',
        subtitle: 'Build vocabulary and short phrases',
        icon: Icons.menu_book_rounded,
      ),
      OnboardingSelectionItem(
        value: LearnerLevel.advanced,
        title: 'I want to practice fluency',
        subtitle: 'Advanced sentences, quizzes & culture',
        icon: Icons.school_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.familiarityTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.familiaritySubtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ...levels.map((item) {
            final isSelected = selectedLevel == item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(item.value as LearnerLevel);
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

// STEP 3: SCRIPT SELECTION
