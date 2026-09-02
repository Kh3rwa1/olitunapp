import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/categories/domain/entities/category_entity.dart';
import '../../../l10n/generated/app_localizations.dart';

class PaywallActionSection extends StatelessWidget {
  final CategoryEntity category;
  final bool isLoading;
  final bool showPaidButton;
  final VoidCallback onPayPressed;

  const PaywallActionSection({
    super.key,
    required this.category,
    required this.isLoading,
    required this.showPaidButton,
    required this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: AppRadius.borderXl,
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.webMonetizationRestrictedTitle,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.webMonetizationNotice,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (showPaidButton) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPayPressed,
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
                  fontSize: 16,
                  color: AppColors.elevatedButtonFg,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Security reassurance trust badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.trustBadgeSecureCheckout,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
