import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/streak_week_logic.dart';

UserStatsEntity _stats({
  String lastActiveDate = '',
  int streak = 0,
  Set<String> practiceDates = const {},
  Map<String, QuizResultEntity> quizHistory = const {},
}) {
  return UserStatsEntity(
    practicedLetters: {},
    completedLessons: {},
    quizHistory: quizHistory,
    categoryMastery: {},
    totalLearningMinutes: 0,
    lastActiveDate: lastActiveDate,
    currentStreak: streak,
    totalStars: 0,
    practiceDates: practiceDates,
  );
}

void main() {
  group('StreakWeekLogic.calendarWeek', () {
    test('anchors on Monday of the current week', () {
      // Wed, Aug 19 2026
      final week = StreakWeekLogic.calendarWeek(DateTime(2026, 8, 19));
      expect(week.length, 7);
      expect(week.first.weekday, DateTime.monday);
      expect(week.first, DateTime(2026, 8, 17));
      expect(week.last, DateTime(2026, 8, 23));
    });

    test('on a Sunday the full week is already in the past', () {
      final week = StreakWeekLogic.calendarWeek(DateTime(2026, 8, 23));
      expect(week.first, DateTime(2026, 8, 17));
      expect(week.last, DateTime(2026, 8, 23));
    });

    test('on a Monday only today is non-future', () {
      final week = StreakWeekLogic.calendarWeek(DateTime(2026, 8, 17));
      expect(week.first, DateTime(2026, 8, 17));
      expect(week.where((d) => d.isAfter(DateTime(2026, 8, 17))).length, 6);
    });
  });

  group('StreakWeekLogic.isDayActive', () {
    test('true when date is in practiceDates', () {
      final stats = _stats(practiceDates: {'2026-08-18'});
<<<<<<< HEAD
      expect(StreakWeekLogic.isDayActive(stats, DateTime(2026, 8, 18)), isTrue);
=======
      expect(
        StreakWeekLogic.isDayActive(stats, DateTime(2026, 8, 18)),
        isTrue,
      );
>>>>>>> 1002fa04 (fix(profile): honest streak states, calendar-week strip, nav scrim and a11y)
    });

    test('true when a quiz was completed that day', () {
      final stats = _stats(
        quizHistory: {
          'q1': QuizResultEntity(
            quizId: 'q1',
            score: 10,
            totalQuestions: 10,
            completedAt: DateTime(2026, 8, 19, 14, 30).toIso8601String(),
          ),
        },
      );
<<<<<<< HEAD
      expect(StreakWeekLogic.isDayActive(stats, DateTime(2026, 8, 19)), isTrue);
=======
      expect(
        StreakWeekLogic.isDayActive(stats, DateTime(2026, 8, 19)),
        isTrue,
      );
>>>>>>> 1002fa04 (fix(profile): honest streak states, calendar-week strip, nav scrim and a11y)
    });

    test('true for today via lastActiveDate with positive streak', () {
      final stats = _stats(lastActiveDate: '2026-08-23', streak: 2);
<<<<<<< HEAD
      expect(StreakWeekLogic.isDayActive(stats, DateTime(2026, 8, 23)), isTrue);
=======
      expect(
        StreakWeekLogic.isDayActive(stats, DateTime(2026, 8, 23)),
        isTrue,
      );
>>>>>>> 1002fa04 (fix(profile): honest streak states, calendar-week strip, nav scrim and a11y)
    });

    test('false for inactive days', () {
      final stats = _stats(lastActiveDate: '2026-08-23', streak: 2);
      expect(
        StreakWeekLogic.isDayActive(stats, DateTime(2026, 8, 18)),
        isFalse,
      );
    });
  });

  group('StreakWeekLogic.activeCountInWeek', () {
    test('counts distinct active days only', () {
      final stats = _stats(
        practiceDates: {'2026-08-18', '2026-08-20'},
        quizHistory: {
          'q1': QuizResultEntity(
            quizId: 'q1',
            score: 5,
            totalQuestions: 10,
            completedAt: DateTime(2026, 8, 20, 9).toIso8601String(),
          ),
        },
      );
      final week = StreakWeekLogic.calendarWeek(DateTime(2026, 8, 23));
      // 18th + 20th (quiz and practice overlap counts once)
      expect(StreakWeekLogic.activeCountInWeek(stats, week), 2);
    });
  });

  group('StreakWeekLogic.headerState', () {
    test('idle when no activity at all', () {
      final state = StreakWeekLogic.headerState(streak: 0, activeCount: 0);
      expect(state, StreakHeaderState.idle);
    });

    test('active with any streak or weekly activity', () {
      expect(
        StreakWeekLogic.headerState(streak: 3, activeCount: 0),
        StreakHeaderState.active,
      );
      expect(
        StreakWeekLogic.headerState(streak: 0, activeCount: 1),
        StreakHeaderState.active,
      );
    });
  });
}
