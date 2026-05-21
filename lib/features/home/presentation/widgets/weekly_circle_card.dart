import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/minimum_tap_target.dart';
import '../../../circle/presentation/providers/circle_providers.dart';

class WeeklyCircleCard extends ConsumerWidget {
  const WeeklyCircleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaderboardAsync = ref.watch(circleLeaderboardProvider);

    return leaderboardAsync.when(
      data: (data) {
        final rank = data['rank'] ?? 1;
        final total = data['totalMembers'] ?? 20;
        final points = data['currentUserMember']?['circlePoints'] ?? 0;
        final pointsToNext = data['pointsToNextRank'] ?? 0;
        final endsAtStr = data['endsAt'] ?? '';
        final isStarterCircle = data['isStarterCircle'] == true;
        final starterMessage =
            data['starterCircleMessage'] as String? ??
            'You’re warming up while more learners join.';
        final rankIcon = isStarterCircle
            ? '🌱'
            : rank <= 3
            ? '🏆'
            : rank <= (total / 2).ceil()
            ? '🔥'
            : '🌱';

        // Calculate remaining time
        String remainingTime = 'Ends soon';
        if (endsAtStr.isNotEmpty) {
          try {
            final endsAt = DateTime.parse(endsAtStr);
            final diff = endsAt.difference(DateTime.now());
            if (diff.isNegative) {
              remainingTime = 'Ended';
            } else {
              remainingTime = 'Ends in ${diff.inDays}d ${diff.inHours % 24}h';
            }
          } catch (_) {}
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.group_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isStarterCircle ? 'Starter Circle' : 'Weekly Circle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      remainingTime,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStarterCircle
                            ? 'Warming up'
                            : '#$rank of $total learners',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isStarterCircle
                            ? starterMessage
                            : '$points points this week',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Text(rankIcon, style: const TextStyle(fontSize: 32)),
                ],
              ),
              if (pointsToNext > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.duoYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.duoYellow.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.duoYellow,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Only $pointsToNext point${pointsToNext > 1 ? "s" : ""} to reach #${rank - 1}!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.brandTextDark
                                : AppColors.brandTextLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: MinimumTapTarget(
                  onTap: () => context.push('/circle'),
                  borderRadius: BorderRadius.circular(16),
                  child: ElevatedButton(
                    onPressed: () => context.push('/circle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Circle Leaderboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.duoOrange,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load Weekly Circle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref
                  .read(circleLeaderboardProvider.notifier)
                  .refreshLeaderboard(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
