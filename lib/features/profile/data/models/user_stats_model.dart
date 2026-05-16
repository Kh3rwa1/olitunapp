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
    int readInt(String key) {
      final value = json[key];
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.round();
      if (value is String) return int.parse(value);
      throw FormatException('Invalid integer field: $key');
    }

    Map<String, int> readMastery(dynamic value) {
      if (value is! Map) return {};
      return value.map((key, raw) {
        final parsed = raw is int
            ? raw
            : raw is num
            ? raw.round()
            : raw is String
            ? int.parse(raw)
            : throw FormatException('Invalid mastery value: $key');
        return MapEntry(key.toString(), parsed.clamp(0, 100));
      });
    }

    Map<String, QuizResultEntity> readQuizHistory(dynamic value) {
      if (value is! Map<String, dynamic>) return {};
      return value.map((k, v) {
        final data = v is Map<String, dynamic>
            ? v
            : v is Map
            ? Map<String, dynamic>.from(v)
            : <String, dynamic>{};
        return MapEntry(k, QuizResultModel.fromJson(data));
      });
    }

    return UserStatsModel(
      practicedLetters: Set<String>.from(json['practicedLetters'] ?? []),
      completedLessons: Set<String>.from(json['completedLessons'] ?? []),
      quizHistory: readQuizHistory(json['quizHistory']),
      categoryMastery: readMastery(json['categoryMastery']),
      totalLearningMinutes: readInt('totalLearningMinutes'),
      lastActiveDate: json['lastActiveDate'] ?? '',
      currentStreak: readInt('currentStreak'),
      totalStars: readInt('totalStars'),
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
    int readInt(String key) {
      final value = json[key];
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.round();
      if (value is String) return int.parse(value);
      throw FormatException('Invalid integer field: $key');
    }

    return QuizResultModel(
      quizId: json['quizId'] ?? '',
      score: readInt('score'),
      totalQuestions: readInt('totalQuestions'),
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
