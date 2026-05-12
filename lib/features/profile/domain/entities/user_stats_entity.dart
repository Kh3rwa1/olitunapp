import 'package:equatable/equatable.dart';
import 'quiz_result_entity.dart';

class UserStatsEntity extends Equatable {
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

  /// Alphabet mastery: based on how many letters have been practiced
  double get alphabetProgress => (practicedLetters.length / 30).clamp(0.0, 1.0);

  /// Numbers mastery: from categoryMastery map or completed lessons
  double get numbersProgress {
    if (categoryMastery.containsKey('numbers')) {
      return (categoryMastery['numbers']! / 100).clamp(0.0, 1.0);
    }
    // Fallback: estimate from total completed lessons
    final total = completedLessons.length;
    return (total / 15).clamp(0.0, 1.0) * 0.5;
  }

  /// Vocabulary mastery: from categoryMastery map or completed lessons
  double get vocabularyProgress {
    if (categoryMastery.containsKey('words') ||
        categoryMastery.containsKey('vocabulary')) {
      final val =
          categoryMastery['words'] ?? categoryMastery['vocabulary'] ?? 0;
      return (val / 100).clamp(0.0, 1.0);
    }
    final total = completedLessons.length;
    return (total / 20).clamp(0.0, 1.0) * 0.4;
  }

  /// Sentences mastery
  double get sentencesProgress {
    if (categoryMastery.containsKey('sentences')) {
      return (categoryMastery['sentences']! / 100).clamp(0.0, 1.0);
    }
    final total = completedLessons.length;
    return (total / 25).clamp(0.0, 1.0) * 0.3;
  }

  /// Rhymes mastery
  double get rhymesProgress {
    if (categoryMastery.containsKey('rhymes')) {
      return (categoryMastery['rhymes']! / 100).clamp(0.0, 1.0);
    }
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
      totalCorrect += result.score;
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
        final pct = result.score / result.totalQuestions;
        if (pct > best) best = pct;
      }
    }
    return (best * 100).round();
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
