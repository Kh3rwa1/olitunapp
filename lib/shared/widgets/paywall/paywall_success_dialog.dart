import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PaywallSuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback onStartLearning;

  const PaywallSuccessDialog({
    super.key,
    required this.message,
    required this.onStartLearning,
  });

  static Future<void> show(
    BuildContext context, {
    required String message,
    required VoidCallback onStartLearning,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PaywallSuccessDialog(
          message: message,
          onStartLearning: () {
            Navigator.of(dialogContext).pop();
            onStartLearning();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXxl),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.quizDarkCard : Colors.white,
          borderRadius: AppRadius.borderXxl,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 48,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Maran Jauhar! 🎉',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStartLearning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderXl,
                  ),
                ),
                child: Text(
                  'Start Learning',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
