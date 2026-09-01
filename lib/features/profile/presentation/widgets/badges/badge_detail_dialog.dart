import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../shared/widgets/sharing/share_card_payload.dart';
import '../../../../../../shared/widgets/sharing/social_share_modal.dart';
import 'badge_item_model.dart';

class BadgeDetailDialog extends StatelessWidget {
  final Badge badge;
  final bool isDark;

  const BadgeDetailDialog({
    super.key,
    required this.badge,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required Badge badge,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) {
        return Center(
          child: BadgeDetailDialog(badge: badge, isDark: isDark),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.borderXxxl,
        border: Border.all(
          color: (badge.isUnlocked ? AppColors.primary : Colors.grey)
              .withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (badge.isUnlocked ? AppColors.primary : Colors.grey)
                .withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge Icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: (badge.isUnlocked ? AppColors.primary : Colors.grey)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: badge.isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 48,
                  color: badge.isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.lg),
          // Badge Name
          Text(
            badge.name,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          // Badge Category
          Text(
            badge.category,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: badge.isUnlocked ? AppColors.primary : Colors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Badge Description
          Text(
            badge.description,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Progress
          if (!badge.isUnlocked) ...[
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: LinearProgressIndicator(
                value: badge.targetProgress > 0
                    ? (badge.currentProgress / badge.targetProgress).clamp(
                        0.0,
                        1.0,
                      )
                    : 0.0,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade500),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: ${badge.currentProgress}/${badge.targetProgress}',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  badge.rewardStars > 0 ? 'REWARDED' : 'UNLOCKED',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (badge.rewardStars > 0) ...[
              const SizedBox(height: 8),
              Text(
                '+${badge.rewardStars} stars',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.xl),
          // Actions
          if (badge.isUnlocked) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  SocialShareModal.show(
                    context,
                    payload: ShareCardPayload.badgeAchievement(
                      badgeName: badge.name,
                      description: badge.description,
                      iconEmoji: badge.icon,
                      category: badge.category,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderLg,
                  ),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(
                  'Share Achievement',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderLg,
                ),
              ),
              child: Text(
                'Awesome',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
