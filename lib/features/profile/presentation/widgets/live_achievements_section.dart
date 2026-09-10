import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/gamification_content_provider.dart';

/// Restores achievements without local estimates or invented progress. Every
/// displayed badge comes from the authenticated Appwrite summary function.
class LiveAchievementsSection extends ConsumerWidget {
  const LiveAchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ref
        .watch(userGamificationSummaryProvider)
        .when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _StatusCard(
            isDark: isDark,
            icon: Icons.cloud_off_rounded,
            message: 'Achievements are temporarily unavailable.',
            action: TextButton.icon(
              onPressed: () => ref.invalidate(userGamificationSummaryProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
          data: (summary) {
            final badges = summary.badges
                .where(
                  (badge) => badge.badgeId.isNotEmpty && badge.name.isNotEmpty,
                )
                .toList(growable: false);
            if (badges.isEmpty) {
              return _StatusCard(
                isDark: isDark,
                icon: Icons.workspace_premium_outlined,
                message: 'No verified achievements yet. Complete learning activities to unlock them.',
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: badges.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth >= 700 ? 1.45 : 1.08,
                  ),
                  itemBuilder: (context, index) =>
                      _AchievementCard(badge: badges[index], isDark: isDark),
                );
              },
            );
          },
        );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.badge, required this.isDark});

  final UserGamificationBadge badge;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasTarget = badge.target > 0;
    final progressRatio = hasTarget
        ? (badge.progress / badge.target).clamp(0.0, 1.0).toDouble()
        : null;
    final stateLabel = badge.isUnlocked
        ? 'Unlocked'
        : hasTarget
        ? '${badge.progress} of ${badge.target}'
        : 'In progress';

    return Semantics(
      container: true,
      label: '${badge.name}. $stateLabel.',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.isUnlocked
                ? AppColors.primary.withValues(alpha: 0.42)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
          boxShadow: isDark ? const [] : AppColors.softShadow,
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          (badge.isUnlocked
                                  ? AppColors.primary
                                  : AppColors.xpNeutral)
                              .withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    badge.isUnlocked
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    size: 18,
                    color: badge.isUnlocked
                        ? AppColors.brandTextLight
                        : AppColors.xpNeutral,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                badge.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (!badge.isUnlocked && progressRatio != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 6,
                    color: AppColors.primary,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                stateLabel,
                style: AppTypography.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badge.isUnlocked
                      ? (isDark
                            ? AppColors.brandTextDark
                            : AppColors.brandTextLight)
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isDark,
    required this.icon,
    required this.message,
    this.action,
  });

  final bool isDark;
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.025),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}
