import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/profile_providers.dart';
import '../../domain/entities/user_stats_entity.dart';

class NextMilestoneCard extends ConsumerWidget {
  const NextMilestoneCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (stats) {
        final levelIndex = stats.levelIndex;

        // 1. Next level details
        String nextLevelName = '';
        double levelProgress = 0.0;
        final levelRequirements = <String>[];

        if (levelIndex == 0) {
          nextLevelName = 'Intermediate';
          final progressRatio = (stats.overallProgress / 0.20).clamp(0.0, 1.0);
          final lessonsRatio = (stats.completedLessons.length / 3.0).clamp(
            0.0,
            1.0,
          );
          levelProgress = (progressRatio + lessonsRatio) / 2.0;

          if (stats.completedLessons.length < 3) {
            levelRequirements.add(
              'Complete ${3 - stats.completedLessons.length} more lessons',
            );
          }
          if (stats.overallProgress < 0.20) {
            levelRequirements.add(
              'Reach 20% overall progress (current: ${(stats.overallProgress * 100).round()}%)',
            );
          }
        } else if (levelIndex == 1) {
          nextLevelName = 'Advanced';
          final progressRatio = (stats.overallProgress / 0.50).clamp(0.0, 1.0);
          final lessonsRatio = (stats.completedLessons.length / 10.0).clamp(
            0.0,
            1.0,
          );
          levelProgress = (progressRatio + lessonsRatio) / 2.0;

          if (stats.completedLessons.length < 10) {
            levelRequirements.add(
              'Complete ${10 - stats.completedLessons.length} more lessons',
            );
          }
          if (stats.overallProgress < 0.50) {
            levelRequirements.add(
              'Reach 50% overall progress (current: ${(stats.overallProgress * 100).round()}%)',
            );
          }
        } else if (levelIndex == 2) {
          nextLevelName = 'Master';
          final progressRatio = (stats.overallProgress / 0.75).clamp(0.0, 1.0);
          final lessonsRatio = (stats.completedLessons.length / 20.0).clamp(
            0.0,
            1.0,
          );
          levelProgress = (progressRatio + lessonsRatio) / 2.0;

          if (stats.completedLessons.length < 20) {
            levelRequirements.add(
              'Complete ${20 - stats.completedLessons.length} more lessons',
            );
          }
          if (stats.overallProgress < 0.75) {
            levelRequirements.add(
              'Reach 75% overall progress (current: ${(stats.overallProgress * 100).round()}%)',
            );
          }
        } else {
          nextLevelName = 'Santali Sage / Guru';
          final progressRatio = stats.overallProgress;
          final lettersRatio = (stats.practicedLetters.length / 30.0).clamp(
            0.0,
            1.0,
          );
          final starsRatio = (stats.totalStars / 150.0).clamp(0.0, 1.0);
          levelProgress = (progressRatio + lettersRatio + starsRatio) / 3.0;

          if (stats.overallProgress < 1.0) {
            levelRequirements.add('Achieve 100% overall progress');
          }
          if (stats.practicedLetters.length < 30) {
            levelRequirements.add(
              'Practice ${30 - stats.practicedLetters.length} more letters',
            );
          }
          if (stats.totalStars < 150) {
            levelRequirements.add('Earn ${150 - stats.totalStars} more stars');
          }
        }

        if (levelRequirements.isEmpty) {
          levelRequirements.add('You have conquered all current levels! 🎉');
        }

        // 2. Identify the closest locked badge
        final archerName = ref.watch(badgeTraditionalArcherNameProvider);
        final kudumName = ref.watch(badgeTraditionalKudumNameProvider);
        final kherwalName = ref.watch(badgeTraditionalKherwalNameProvider);

        final badges = [
          _BadgeProgress(
            name: archerName,
            icon: Icons.track_changes_rounded,
            ratio: (stats.practicedLetters.length / 20.0).clamp(0.0, 1.0),
            targetText:
                'Practice 20+ letters (${stats.practicedLetters.length}/20)',
            color: AppColors.primary,
          ),
          _BadgeProgress(
            name: kudumName,
            icon: Icons.psychology_rounded,
            ratio: (stats.completedLessons.length / 3.0).clamp(0.0, 1.0),
            targetText:
                'Complete 3 lessons (${stats.completedLessons.length}/3)',
            color: AppColors.duoOrange,
          ),
          _BadgeProgress(
            name: kherwalName,
            icon: Icons.spa_rounded,
            ratio: (stats.overallProgress / 0.40).clamp(0.0, 1.0),
            targetText:
                'Reach 40% overall progress (${(stats.overallProgress * 100).round()}%/40%)',
            color: AppColors.duoYellow,
          ),
          _BadgeProgress(
            name: 'Daily Voyager',
            icon: Icons.rocket_launch_rounded,
            ratio: (stats.currentStreak / 3.0).clamp(0.0, 1.0),
            targetText: 'Maintain a 3-day streak (${stats.currentStreak}/3)',
            color: AppColors.duoBlue,
          ),
          _BadgeProgress(
            name: 'Communicator',
            icon: Icons.record_voice_over_rounded,
            ratio: (stats.totalLearningMinutes / 10.0).clamp(0.0, 1.0),
            targetText:
                'Practice for 10 minutes (${stats.totalLearningMinutes}/10 mins)',
            color: const Color(0xFF00E5FF),
          ),
          _BadgeProgress(
            name: 'Star Gazer',
            icon: Icons.star_rounded,
            ratio: (stats.totalStars / 50.0).clamp(0.0, 1.0),
            targetText: 'Earn 50 stars (${stats.totalStars}/50)',
            color: AppColors.duoYellow,
          ),
        ];

        // Find closest locked badge
        _BadgeProgress? closestBadge;
        double maxRatio = -1.0;
        for (final b in badges) {
          if (b.ratio < 1.0 && b.ratio > maxRatio) {
            maxRatio = b.ratio;
            closestBadge = b;
          }
        }

        final badge = closestBadge;

        return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E2620), const Color(0xFF121212)]
                      : [const Color(0xFFE8FDF3), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.05 : 0.03,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Stylized absolute decor elements (no purple!)
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.trending_up_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEXT MILESTONE',
                                      style: AppTypography.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Road to $nextLevelName',
                                      style: AppTypography.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      // Disambiguates this % from the hero
                                      // card's course-wide Overall Progress.
                                      'Level progress · '
                                      '${UserStatsEntity.levelThresholds[levelIndex]} → $nextLevelName',
                                      style: AppTypography.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Level Progress Bar — % lives here (once), so the
                          // card no longer mirrors the hero card's chip+bar.
                          Row(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 10,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: levelProgress,
                                      child: Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primary.withValues(
                                                alpha: 0.7,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(levelProgress * 100).round()}%',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Checklist of requirements
                          ...levelRequirements.map(
                            (req) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.star_outline_rounded,
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      req,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Closest Locked Badge Banner
                          if (badge != null) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Colors.white10),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'To unlock the ${badge.name} badge: ${badge.targetText}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: badge.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: badge.color.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: badge.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        badge.icon,
                                        color: badge.color,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Closest Badge Achievement',
                                            style: AppTypography.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Unlock the ${badge.name} Badge',
                                            style: AppTypography.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badge.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${(badge.ratio * 100).round()}%',
                                        style: AppTypography.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: badge.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _BadgeProgress {
  final String name;
  final IconData icon;
  final double ratio;
  final String targetText;
  final Color color;

  _BadgeProgress({
    required this.name,
    required this.icon,
    required this.ratio,
    required this.targetText,
    required this.color,
  });
}
