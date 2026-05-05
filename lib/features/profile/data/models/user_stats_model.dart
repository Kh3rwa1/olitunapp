import '../../domain/entities/user_stats_entity.dart';
import '../../domain/entities/quiz_result_entity.dart';

class UserStatsModel extends UserStatsEntity {
  const UserStatsModel({
    required super.practicedLetters,
    required super.completedLessons,
    required super.quizHistory,
    required super.categoryMastery,
    required super.totalLearningMinutes,
    required super.lastActiveDate,
    required super.currentStreak,
    required super.totalStars,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      practicedLetters: Set<String>.from(json['practicedLetters'] ?? []),
      completedLessons: Set<String>.from(json['completedLessons'] ?? []),
      quizHistory:
          (json['quizHistory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, QuizResultModel.fromJson(v)),
          ) ??
          {},
      categoryMastery: Map<String, int>.from(json['categoryMastery'] ?? {}),
      totalLearningMinutes: json['totalLearningMinutes'] ?? 0,
      lastActiveDate: json['lastActiveDate'] ?? '',
      currentStreak: json['currentStreak'] ?? 0,
      totalStars: json['totalStars'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'practicedLetters': practicedLetters.toList(),
      'completedLessons': completedLessons.toList(),
      'quizHistory': quizHistory.map(
        (k, v) => MapEntry(k, QuizResultModel.fromEntity(v).toJson()),
      ),
      'categoryMastery': categoryMastery,
      'totalLearningMinutes': totalLearningMinutes,
      'lastActiveDate': lastActiveDate,
      'currentStreak': currentStreak,
      'totalStars': totalStars,
    };
  }

  factory UserStatsModel.fromEntity(UserStatsEntity entity) {
    return UserStatsModel(
      practicedLetters: entity.practicedLetters,
      completedLessons: entity.completedLessons,
      quizHistory: entity.quizHistory,
      categoryMastery: entity.categoryMastery,
      totalLearningMinutes: entity.totalLearningMinutes,
      lastActiveDate: entity.lastActiveDate,
      currentStreak: entity.currentStreak,
      totalStars: entity.totalStars,
    );
  }
}

class QuizResultModel extends QuizResultEntity {
  const QuizResultModel({
    required super.quizId,
    required super.score,
    required super.totalQuestions,
    required super.completedAt,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      quizId: json['quizId'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      completedAt: json['completedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt,
    };
  }

  factory QuizResultModel.fromEntity(QuizResultEntity entity) {
    return QuizResultModel(
      quizId: entity.quizId,
      score: entity.score,
      totalQuestions: entity.totalQuestions,
      completedAt: entity.completedAt,
    );
  }
}
