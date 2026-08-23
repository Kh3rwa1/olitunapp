import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/data/models/user_stats_model.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';

void main() {
  group('UserStatsModel practiceDates', () {
    test('round-trips through JSON', () {
      const entity = UserStatsEntity(
        practicedLetters: {'a'},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 5,
        lastActiveDate: '2026-08-23',
        currentStreak: 1,
        totalStars: 10,
        practiceDates: {'2026-08-22', '2026-08-23'},
      );

      final json = UserStatsModel.fromEntity(entity).toJson();
      expect(json['practiceDates'], ['2026-08-22', '2026-08-23']);

      final decoded = UserStatsModel.fromJson(json);
      expect(decoded.practiceDates, {'2026-08-22', '2026-08-23'});
    });

    test('defaults to empty for legacy payloads without the field', () {
      final decoded = UserStatsModel.fromJson({
        'practicedLetters': [],
        'completedLessons': [],
        'quizHistory': {},
        'categoryMastery': {},
        'totalLearningMinutes': 0,
        'lastActiveDate': '',
        'currentStreak': 0,
        'totalStars': 0,
      });
      expect(decoded.practiceDates, isEmpty);
    });
  });
}
