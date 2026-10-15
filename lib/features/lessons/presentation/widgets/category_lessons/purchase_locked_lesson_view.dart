import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/models/catalog/category_entity.dart';

/// Shown instead of a lesson that belongs to a paid category the learner
/// does not own. Never built for free categories.
class PurchaseLockedLessonView extends StatelessWidget {
  const PurchaseLockedLessonView({
    super.key,
    required this.isDark,
    required this.category,
    required this.onUnlock,
    required this.onBack,
  });

  final bool isDark;
  final CategoryEntity category;
  final VoidCallback onUnlock;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
      appBar: AppBar(
        leading: BackButton(onPressed: onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  category.titleLatin,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.paywallLockedLessonMessage,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('purchase-locked-unlock'),
                    onPressed: onUnlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderXl,
                      ),
                    ),
                    child: Text(
                      l10n.unlockCourse('${category.priceInr}'),
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.elevatedButtonFg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
