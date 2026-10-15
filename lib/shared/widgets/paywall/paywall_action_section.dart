import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';

enum PaywallStage {
  /// Fetching the server order (and its authoritative price).
  preparing,
  ready,
  purchasing,
  signInRequired,
  unsupportedPlatform,
  notConfigured,
  unlocked,
  pendingVerification,
}

class PaywallActionSection extends StatelessWidget {
  const PaywallActionSection({
    super.key,
    required this.stage,
    required this.priceLabel,
    required this.onUnlock,
    required this.onSignIn,
    required this.onDone,
    this.notice,
  });

  final PaywallStage stage;
  final String priceLabel;
  final VoidCallback onUnlock;
  final VoidCallback onSignIn;
  final VoidCallback onDone;

  /// Inline status under the button (cancelled, failed, offline…).
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...switch (stage) {
          PaywallStage.unsupportedPlatform => [
            _Notice(icon: Icons.android_rounded, text: l10n.paywallAndroidOnly),
          ],
          PaywallStage.notConfigured => [
            _Notice(
              icon: Icons.info_outline_rounded,
              text: l10n.paywallNotConfigured,
            ),
          ],
          PaywallStage.signInRequired => [
            _Notice(
              icon: Icons.person_outline_rounded,
              text: l10n.pleaseLogInToPurchase,
            ),
            const SizedBox(height: AppSpacing.md),
            _PrimaryButton(
              key: const Key('paywall-sign-in'),
              label: l10n.signIn,
              onPressed: onSignIn,
            ),
          ],
          PaywallStage.unlocked => [
            _Notice(
              icon: Icons.check_circle_rounded,
              text: l10n.courseUnlocked,
            ),
            const SizedBox(height: AppSpacing.md),
            _PrimaryButton(
              key: const Key('paywall-start-learning'),
              label: l10n.startLearning,
              onPressed: onDone,
            ),
          ],
          PaywallStage.pendingVerification => [
            _Notice(
              icon: Icons.hourglass_top_rounded,
              text: l10n.paywallVerificationPending,
            ),
            const SizedBox(height: AppSpacing.md),
            _PrimaryButton(
              key: const Key('paywall-close'),
              label: l10n.close,
              onPressed: onDone,
            ),
          ],
          PaywallStage.preparing ||
          PaywallStage.ready ||
          PaywallStage.purchasing => [
            _PrimaryButton(
              key: const Key('paywall-unlock'),
              label: l10n.unlockCourse(priceLabel),
              busy: stage != PaywallStage.ready,
              onPressed: stage == PaywallStage.ready ? onUnlock : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.trustBadgeSecureCheckout,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        },
        if (notice != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            notice!,
            key: const Key('paywall-notice'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        ),
        child: busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.elevatedButtonFg,
                ),
              )
            : Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.elevatedButtonFg,
                ),
              ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderXl,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
