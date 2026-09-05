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
    required super.completedMissionsDates,
    super.practiceDates,
    super.syncEpoch,
    super.starEvents,
    super.minuteEvents,
    super.compactedStarEvents,
    super.compactedMinuteEvents,
    super.baseStarsByOrigin,
    super.starCheckpoints,
    super.baseMinutesByOrigin,
    super.minuteCheckpoints,
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

    Map<String, int> readIntMap(dynamic value) {
      if (value is! Map) return {};
      return value.map((key, raw) {
        final parsed = raw is int
            ? raw
            : raw is num
            ? raw.round()
            : raw is String
            ? int.tryParse(raw) ?? 0
            : 0;
        return MapEntry(key.toString(), parsed < 0 ? 0 : parsed);
      });
    }

    final rawStarEvents = readIntMap(json['starEvents']);
    final rawMinuteEvents = readIntMap(json['minuteEvents']);
    final totalStarsVal = readInt('totalStars');
    final totalMinutesVal = readInt('totalLearningMinutes');

    var baseStarsMap = readIntMap(json['baseStarsByOrigin']);
    if (baseStarsMap.isEmpty) {
      final activeSum = rawStarEvents.values.fold<int>(0, (s, v) => s + v);
      final legacyBase = totalStarsVal >= activeSum
          ? totalStarsVal - activeSum
          : totalStarsVal;
      if (legacyBase > 0) {
        baseStarsMap = {'__legacy__': legacyBase};
      }
    }

    var baseMinutesMap = readIntMap(json['baseMinutesByOrigin']);
    if (baseMinutesMap.isEmpty) {
      final activeSum = rawMinuteEvents.values.fold<int>(0, (s, v) => s + v);
      final legacyBase = totalMinutesVal >= activeSum
          ? totalMinutesVal - activeSum
          : totalMinutesVal;
      if (legacyBase > 0) {
        baseMinutesMap = {'__legacy__': legacyBase};
      }
    }

    final starCheckpointsMap = readIntMap(json['starCheckpoints']);
    final minuteCheckpointsMap = readIntMap(json['minuteCheckpoints']);

    return UserStatsModel(
      practicedLetters: Set<String>.from(json['practicedLetters'] ?? []),
      completedLessons: Set<String>.from(json['completedLessons'] ?? []),
      quizHistory: readQuizHistory(json['quizHistory']),
      categoryMastery: readMastery(json['categoryMastery']),
      totalLearningMinutes: totalMinutesVal,
      lastActiveDate: json['lastActiveDate'] ?? '',
      currentStreak: readInt('currentStreak'),
      totalStars: totalStarsVal,
      completedMissionsDates: Set<String>.from(
        json['completedMissionsDates'] ?? [],
      ),
      practiceDates: Set<String>.from(json['practiceDates'] ?? []),
      syncEpoch: readInt('syncEpoch'),
      starEvents: rawStarEvents,
      minuteEvents: rawMinuteEvents,
      compactedStarEvents: Set<String>.from(json['compactedStarEvents'] ?? []),
      compactedMinuteEvents: Set<String>.from(
        json['compactedMinuteEvents'] ?? [],
      ),
      baseStarsByOrigin: baseStarsMap,
      starCheckpoints: starCheckpointsMap,
      baseMinutesByOrigin: baseMinutesMap,
      minuteCheckpoints: minuteCheckpointsMap,
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
      'completedMissionsDates': completedMissionsDates.toList(),
      'practiceDates': practiceDates.toList(),
      'syncEpoch': syncEpoch,
      'starEvents': starEvents,
      'minuteEvents': minuteEvents,
      'compactedStarEvents': compactedStarEvents.toList(),
      'compactedMinuteEvents': compactedMinuteEvents.toList(),
      'baseStarsByOrigin': baseStarsByOrigin,
      'starCheckpoints': starCheckpoints,
      'baseMinutesByOrigin': baseMinutesByOrigin,
      'minuteCheckpoints': minuteCheckpoints,
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
      completedMissionsDates: entity.completedMissionsDates,
      practiceDates: entity.practiceDates,
      syncEpoch: entity.syncEpoch,
      starEvents: entity.starEvents,
      minuteEvents: entity.minuteEvents,
      compactedStarEvents: entity.compactedStarEvents,
      compactedMinuteEvents: entity.compactedMinuteEvents,
      baseStarsByOrigin: entity.baseStarsByOrigin,
      starCheckpoints: entity.starCheckpoints,
      baseMinutesByOrigin: entity.baseMinutesByOrigin,
      minuteCheckpoints: entity.minuteCheckpoints,
    );
  }
}

class QuizResultModel extends QuizResultEntity {
  const QuizResultModel({
    required super.quizId,
    required super.score,
    required super.totalQuestions,
    required super.completedAt,
    super.failedNoHearts,
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
      failedNoHearts: json['failedNoHearts'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt,
      'failedNoHearts': failedNoHearts,
    };
  }

  factory QuizResultModel.fromEntity(QuizResultEntity entity) {
    return QuizResultModel(
      quizId: entity.quizId,
      score: entity.score,
      totalQuestions: entity.totalQuestions,
      completedAt: entity.completedAt,
      failedNoHearts: entity.failedNoHearts,
    );
  }
}
