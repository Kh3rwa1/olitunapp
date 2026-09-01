import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/gamification_content_provider.dart';
import '../../domain/entities/user_stats_entity.dart';

class Badge {
  final String name;
  final String description;
  final String icon;
  final String category; // 'Learning', 'Culture', 'Habit', 'Circle'
  final int currentProgress;
  final int targetProgress;
  final bool isUnlocked;
  final int rewardStars;
  final String unlockedAt;

  const Badge({
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.currentProgress,
    required this.targetProgress,
    required this.isUnlocked,
    this.rewardStars = 0,
    this.unlockedAt = '',
  });
}

class BadgesGridWidget extends ConsumerStatefulWidget {
  final UserStatsEntity stats;
  final bool isDark;

  const BadgesGridWidget({
    super.key,
    required this.stats,
    required this.isDark,
  });

  @override
  ConsumerState<BadgesGridWidget> createState() => _BadgesGridWidgetState();
}

class _BadgesGridWidgetState extends ConsumerState<BadgesGridWidget> {
  String _selectedCategory = 'ALL';

  List<Badge> _getBadges() {
    final remoteBadges =
        ref.watch(userGamificationSummaryProvider).valueOrNull?.badges ??
        const <UserGamificationBadge>[];
    if (remoteBadges.isNotEmpty) {
      return remoteBadges
          .map(
            (badge) => Badge(
              name: badge.name,
              description: badge.description,
              icon: badge.icon,
              category: badge.category.toUpperCase(),
              currentProgress: badge.progress,
              targetProgress: badge.target <= 0 ? 1 : badge.target,
              isUnlocked: badge.isUnlocked,
              rewardStars: badge.rewardStars,
              unlockedAt: badge.unlockedAt,
            ),
          )
          .toList(growable: false);
    }

    final stats = widget.stats;
    return [
      // --- Learning Badges ---
      Badge(
        name: 'First Step',
        description: 'Complete your first Santali lesson.',
        icon: '🌱',
        category: 'LEARNING',
        currentProgress: stats.lessonsCompletedCount >= 1 ? 1 : 0,
        targetProgress: 1,
        isUnlocked: stats.lessonsCompletedCount >= 1,
      ),
      Badge(
        name: 'Fluency Path',
        description: 'Complete 10 Santali lessons.',
        icon: '🌿',
        category: 'LEARNING',
        currentProgress: stats.lessonsCompletedCount,
        targetProgress: 10,
        isUnlocked: stats.lessonsCompletedCount >= 10,
      ),
      Badge(
        name: 'Word Weaver',
        description: 'Learn and practice 50 vocabulary words.',
        icon: '📚',
        category: 'LEARNING',
        currentProgress: (stats.lessonsCompletedCount * 4).clamp(0, 50),
        targetProgress: 50,
        isUnlocked: (stats.lessonsCompletedCount * 4) >= 50,
      ),
      Badge(
        name: 'Quiz Master',
        description: 'Ace 5 quizzes with 100% correct answers.',
        icon: '🏆',
        category: 'LEARNING',
        currentProgress: stats.quizHistory.values
            .where((q) => q.score == q.totalQuestions && q.totalQuestions > 0)
            .length,
        targetProgress: 5,
        isUnlocked:
            stats.quizHistory.values
                .where(
                  (q) => q.score == q.totalQuestions && q.totalQuestions > 0,
                )
                .length >=
            5,
      ),
      Badge(
        name: 'Ol Chiki Reader',
        description: 'Practice all 30 letters of the Ol Chiki alphabet.',
        icon: '✍️',
        category: 'LEARNING',
        currentProgress: stats.practicedLetters.length,
        targetProgress: 30,
        isUnlocked: stats.practicedLetters.length >= 30,
      ),

      // --- Culture Badges ---
      Badge(
        name: 'Cultural Spark',
        description: 'Listen to your first Santali Bakhed rhyme.',
        icon: '🦚',
        category: 'CULTURE',
        currentProgress: stats.rhymesProgress > 0 ? 1 : 0,
        targetProgress: 1,
        isUnlocked: stats.rhymesProgress > 0,
      ),
      Badge(
        name: 'Bakhed Listener',
        description: 'Listen to 5 cultural rhymes.',
        icon: '🎵',
        category: 'CULTURE',
        currentProgress: (stats.rhymesProgress * 5).round().clamp(0, 5),
        targetProgress: 5,
        isUnlocked: (stats.rhymesProgress * 5).round() >= 5,
      ),
      Badge(
        name: 'Heritage Explorer',
        description: 'Deeply explore rhymes and traditional Santali knowledge.',
        icon: '🏹',
        category: 'CULTURE',
        currentProgress: (stats.rhymesProgress * 100).round().clamp(0, 100),
        targetProgress: 100,
        isUnlocked: stats.rhymesProgress >= 1.0,
      ),
      Badge(
        name: 'Ol Chiki Guardian',
        description:
            'Reach Intermediate level and master fundamental components.',
        icon: '🛡️',
        category: 'CULTURE',
        currentProgress: stats.lessonsCompletedCount >= 15 ? 1 : 0,
        targetProgress: 1,
        isUnlocked: stats.lessonsCompletedCount >= 15,
      ),

      // --- Habit Badges ---
      Badge(
        name: '3-Day Fire',
        description: 'Maintain a consistent 3-day learning streak.',
        icon: '🔥',
        category: 'HABIT',
        currentProgress: stats.currentStreak,
        targetProgress: 3,
        isUnlocked: stats.currentStreak >= 3,
      ),
      Badge(
        name: '7-Day Lightning',
        description: 'Maintain a consistent 7-day learning streak.',
        icon: '⚡',
        category: 'HABIT',
        currentProgress: stats.currentStreak,
        targetProgress: 7,
        isUnlocked: stats.currentStreak >= 7,
      ),
      Badge(
        name: '30-Day Master',
        description: 'Dedicate study for a consistent 30-day streak.',
        icon: '👑',
        category: 'HABIT',
        currentProgress: stats.currentStreak,
        targetProgress: 30,
        isUnlocked: stats.currentStreak >= 30,
      ),
      Badge(
        name: 'Perfect Week',
        description:
            'Complete all 4 daily missions every single day for a week.',
        icon: '🌟',
        category: 'HABIT',
        currentProgress: stats.completedMissionsDates.length.clamp(0, 7),
        targetProgress: 7,
        isUnlocked: stats.completedMissionsDates.length >= 7,
      ),
      Badge(
        name: 'Consistency Builder',
        description: 'Unlock completed mission badges on 10 separate days.',
        icon: '🧱',
        category: 'HABIT',
        currentProgress: stats.completedMissionsDates.length,
        targetProgress: 10,
        isUnlocked: stats.completedMissionsDates.length >= 10,
      ),
    ];
  }

  void _showBadgeDialog(BuildContext context, Badge badge) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF141A24) : Colors.white,
              borderRadius: BorderRadius.circular(30),
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
                const SizedBox(height: 20),
                // Badge Name
                Text(
                  badge.name,
                  style: AppTypography.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Badge Category
                Text(
                  badge.category,
                  style: AppTypography.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: badge.isUnlocked ? AppColors.primary : Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // Badge Description
                Text(
                  badge.description,
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Progress
                if (!badge.isUnlocked) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: badge.targetProgress > 0
                          ? (badge.currentProgress / badge.targetProgress)
                                .clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: widget.isDark
                          ? Colors.white12
                          : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade500,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Progress: ${badge.currentProgress}/${badge.targetProgress}',
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
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
                        style: AppTypography.inter(
                          fontSize: 12,
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
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Awesome',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBadges = _getBadges();
    final categories = [
      'ALL',
      'LEARNING',
      'CULTURE',
      'HABIT',
      'CIRCLE',
      'QUIZ',
    ];

    final filteredBadges = _selectedCategory == 'ALL'
        ? allBadges
        : allBadges.where((b) => b.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Pill Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (widget.isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (widget.isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: AppTypography.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isSelected
                          ? Colors.white
                          : (widget.isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Grid of Badges
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 4 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredBadges.length,
              itemBuilder: (context, index) {
                final badge = filteredBadges[index];
                return GestureDetector(
                  onTap: () => _showBadgeDialog(context, badge),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                      boxShadow: widget.isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                (badge.isUnlocked
                                        ? AppColors.primary
                                        : Colors.grey)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              badge.icon,
                              style: TextStyle(
                                fontSize: 22,
                                color: badge.isUnlocked ? null : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            badge.name,
                            style: AppTypography.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badge.isUnlocked
                                  ? (widget.isDark
                                        ? Colors.white
                                        : Colors.black)
                                  : Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Unlocked or Locked Progress Indicator
                        if (badge.isUnlocked)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                badge.rewardStars > 0 ? 'REWARDED' : 'UNLOCKED',
                                style: AppTypography.inter(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'LOCKED (${badge.currentProgress}/${badge.targetProgress})',
                            style: AppTypography.inter(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              color: widget.isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().scale(
                  delay: Duration(milliseconds: index * 40),
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
