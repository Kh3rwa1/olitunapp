import '../../../../../shared/providers/gamification_content_provider.dart';
import '../../../domain/entities/user_stats_entity.dart';

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

class BadgeCatalog {
  const BadgeCatalog._();

  static List<Badge> resolveBadges({
    required UserStatsEntity stats,
    List<UserGamificationBadge>? remoteBadges,
  }) {
    if (remoteBadges != null && remoteBadges.isNotEmpty) {
      return remoteBadges
          .map<Badge>(
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
}
