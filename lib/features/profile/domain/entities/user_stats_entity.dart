import 'package:equatable/equatable.dart';
import 'quiz_result_entity.dart';

class UserStatsEntity extends Equatable {
  static const int alphabetLetterCount = 30;
  static const List<String> levelThresholds = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Master',
  ];

  final Set<String> practicedLetters;
  final Set<String> completedLessons;
  final Map<String, QuizResultEntity> quizHistory;
  final Map<String, int> categoryMastery;
  final int totalLearningMinutes;
  final String lastActiveDate;
  final int currentStreak;
  final int totalStars;

  const UserStatsEntity({
    required this.practicedLetters,
    required this.completedLessons,
    required this.quizHistory,
    required this.categoryMastery,
    required this.totalLearningMinutes,
    required this.lastActiveDate,
    required this.currentStreak,
    required this.totalStars,
  });

  @override
  List<Object?> get props => [
    practicedLetters,
    completedLessons,
    quizHistory,
    categoryMastery,
    totalLearningMinutes,
    lastActiveDate,
    currentStreak,
    totalStars,
  ];

  UserStatsEntity copyWith({
    Set<String>? practicedLetters,
    Set<String>? completedLessons,
    Map<String, QuizResultEntity>? quizHistory,
    Map<String, int>? categoryMastery,
    int? totalLearningMinutes,
    String? lastActiveDate,
    int? currentStreak,
    int? totalStars,
  }) {
    return UserStatsEntity(
      practicedLetters: practicedLetters ?? this.practicedLetters,
      completedLessons: completedLessons ?? this.completedLessons,
      quizHistory: quizHistory ?? this.quizHistory,
      categoryMastery: categoryMastery ?? this.categoryMastery,
      totalLearningMinutes: totalLearningMinutes ?? this.totalLearningMinutes,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      currentStreak: currentStreak ?? this.currentStreak,
      totalStars: totalStars ?? this.totalStars,
    );
  }

  // ============== COMPUTED PROPERTIES ==============

  double _masteryProgress(List<String> keys) {
    for (final key in keys) {
      final value = categoryMastery[key];
      if (value != null) return (value / 100).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Alphabet mastery: based on how many letters have been practiced
  double get alphabetProgress {
    final trackedMastery = _masteryProgress(['alphabets', 'alphabet']);
    if (trackedMastery > 0) return trackedMastery;
    return (practicedLetters.length / alphabetLetterCount).clamp(0.0, 1.0);
  }

  /// Numbers mastery: from categoryMastery map or completed lessons
  double get numbersProgress {
    final trackedMastery = _masteryProgress(['numbers', 'number']);
    if (trackedMastery > 0) return trackedMastery;
    // Fallback: estimate from total completed lessons
    final total = completedLessons.length;
    return (total / 15).clamp(0.0, 1.0) * 0.5;
  }

  /// Vocabulary mastery: from categoryMastery map or completed lessons
  double get vocabularyProgress {
    final trackedMastery = _masteryProgress(['words', 'vocabulary']);
    if (trackedMastery > 0) return trackedMastery;
    final total = completedLessons.length;
    return (total / 20).clamp(0.0, 1.0) * 0.4;
  }

  /// Sentences mastery
  double get sentencesProgress {
    final trackedMastery = _masteryProgress(['sentences', 'sentence']);
    if (trackedMastery > 0) return trackedMastery;
    final total = completedLessons.length;
    return (total / 25).clamp(0.0, 1.0) * 0.3;
  }

  /// Rhymes mastery
  double get rhymesProgress {
    final trackedMastery = _masteryProgress(['rhymes', 'rhyme', 'bakhed']);
    if (trackedMastery > 0) return trackedMastery;
    final total = completedLessons.length;
    return (total / 20).clamp(0.0, 1.0) * 0.3;
  }

  int get lessonsCompletedCount => completedLessons.length;
  int get quizzesCompletedCount => quizHistory.length;

  double get quizAccuracy {
    if (quizHistory.isEmpty) return 0.0;
    int totalCorrect = 0;
    int totalQuestions = 0;
    for (final result in quizHistory.values) {
      if (result.totalQuestions <= 0) continue;
      totalCorrect += result.score.clamp(0, result.totalQuestions);
      totalQuestions += result.totalQuestions;
    }
    if (totalQuestions == 0) return 0.0;
    return totalCorrect / totalQuestions;
  }

  int get bestQuizScore {
    if (quizHistory.isEmpty) return 0;
    double best = 0;
    for (final result in quizHistory.values) {
      if (result.totalQuestions > 0) {
        final pct =
            result.score.clamp(0, result.totalQuestions) /
            result.totalQuestions;
        if (pct > best) best = pct;
      }
    }
    return (best * 100).round();
  }

  List<QuizResultEntity> get recentQuizResults {
    final results = quizHistory.values.toList();
    results.sort((a, b) {
      final aDate = DateTime.tryParse(a.completedAt);
      final bDate = DateTime.tryParse(b.completedAt);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return results;
  }

  int get quizzesCompletedThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    return quizHistory.values.where((result) {
      final completedAt = DateTime.tryParse(result.completedAt);
      if (completedAt == null) return false;
      final completedDay = DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );
      return !completedDay.isBefore(weekStart) && !completedDay.isAfter(today);
    }).length;
  }

  double get overallProgress {
    final skills = [
      alphabetProgress,
      numbersProgress,
      vocabularyProgress,
      sentencesProgress,
      rhymesProgress,
    ];
    return skills.reduce((a, b) => a + b) / skills.length;
  }

  String get learnerLevel {
    final progress = overallProgress;
    final lessons = lessonsCompletedCount;
    if (progress >= 0.75 && lessons >= 20) return levelThresholds[3];
    if (progress >= 0.5 && lessons >= 10) return levelThresholds[2];
    if (progress >= 0.2 && lessons >= 3) return levelThresholds[1];
    return levelThresholds[0];
  }

  int get levelIndex => levelThresholds.indexOf(learnerLevel).clamp(0, 3);
}
