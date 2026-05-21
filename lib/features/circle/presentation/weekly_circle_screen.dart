import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/circle_providers.dart';

class WeeklyCircleScreen extends ConsumerWidget {
  const WeeklyCircleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaderboardAsync = ref.watch(circleLeaderboardProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Learning Circle',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => ref
                .read(circleLeaderboardProvider.notifier)
                .refreshLeaderboard(),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        data: (data) {
          final circle = data['circle'] ?? {};
          final weekId = circle['weekId'] ?? '';
          final endsAtStr = data['endsAt'] ?? '';
          final leaderboard = List<Map<String, dynamic>>.from(
            data['leaderboard'] ?? [],
          );
          final rank = data['rank'] ?? 1;
          final total = data['totalMembers'] ?? 20;
          final points = data['currentUserMember']?['circlePoints'] ?? 0;
          final pointsToNext = data['pointsToNextRank'] ?? 0;

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

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppColors.glowShadow(AppColors.primary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Santali Weekly Circle',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  remainingTime,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Week ${weekId.replaceAll(RegExp(r'.*-W'), '')}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryStat(
                                'Your Rank',
                                '#$rank of $total',
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24,
                              ),
                              _buildSummaryStat('Your Points', '$points pts'),
                            ],
                          ),
                          if (pointsToNext > 0) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.flash_on_rounded,
                                    color: Colors.yellow,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Only $pointsToNext point${pointsToNext > 1 ? "s" : ""} to reach #${rank - 1}!',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 28),

                    // Leaderboard title
                    Text(
                      'LEADERBOARD',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.primary
                            : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Leaderboard list
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leaderboard.length,
                        separatorBuilder: (context, index) => Divider(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final member = leaderboard[index];
                          final isUser =
                              member['userId'] == 'current_user' ||
                              member['userId'] == 'user_authenticated';
                          final displayName = member['displayName'] ?? '';
                          final points = member['circlePoints'] ?? 0;
                          final avatar = member['avatarEmoji'] ?? '🌿';
                          final rankNum = member['rank'] ?? (index + 1);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.primary.withValues(
                                      alpha: isDark ? 0.08 : 0.05,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '$rankNum.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: isUser
                                          ? AppColors.primary
                                          : (isDark
                                                ? Colors.white60
                                                : Colors.black45),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    avatar,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    isUser ? 'You ⭐' : displayName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isUser
                                          ? FontWeight.w900
                                          : FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Text(
                                  '$points pts',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isUser
                                        ? AppColors.primary
                                        : (isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                    const SizedBox(height: 28),

                    // How to earn points
                    Text(
                      'HOW TO EARN POINTS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.primary
                            : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildPointRule('Complete lesson', '+40', isDark),
                          _buildPointRule('Take 1 quick quiz', '+25', isDark),
                          _buildPointRule('Bakhed 80% listened', '+20', isDark),
                          _buildPointRule(
                            'Complete daily mission',
                            '+30',
                            isDark,
                          ),
                          _buildPointRule(
                            'Mistake review complete',
                            '+15',
                            isDark,
                          ),
                          _buildPointRule('Quick Win completed', '+10', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Privacy Note
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Only your display name and avatar are shown. No private information is shared.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.duoOrange,
              ),
              const SizedBox(height: 16),
              const Text('Could not load learning circle'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(circleLeaderboardProvider.notifier)
                    .refreshLeaderboard(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPointRule(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
