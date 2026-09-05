import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/features/auth/domain/entities/user_entity.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/profile/data/models/user_stats_model.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/streak_week_logic.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository auth;
  late SharedPreferences prefs;

  final fixedClock = DateTime(2026, 9, 5, 12); // 2026-09-05

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auth = _MockAuthRepository();
    when(() => auth.isLoggedIn()).thenAnswer((_) async => const Right(false));
    when(
      () => auth.getCurrentUser(),
    ).thenAnswer((_) async => const Right(null));
  });

  group('Multi-Device Progress Merge Concurrency', () {
    test(
      'Independent star earnings on two devices are both preserved without drops',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // Baseline: 100 stars
        const baseline = UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-04',
          currentStreak: 1,
          totalStars: 100,
        );

        // Device A earns 10 stars
        final deviceA = baseline.recordStarReward(10, eventId: 'evt_devA_1');
        expect(deviceA.totalStars, 110);
        expect(deviceA.starEvents, {'evt_devA_1': 10});

        // Device B independently earns 20 stars
        final deviceB = baseline.recordStarReward(20, eventId: 'evt_devB_1');
        expect(deviceB.totalStars, 120);
        expect(deviceB.starEvents, {'evt_devB_1': 20});

        // Mock cloud having Device A's stats
        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(deviceA).toJson(),
            ),
          }),
        );
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        // Device B pushes its stats to repo
        final result = await repo.updateUserStats(deviceB);
        expect(result.isRight(), isTrue);

        final merged = result.getOrElse((_) => fail('updateUserStats failed'));

        // Both earnings preserved: 100 base + 10 (A) + 20 (B) = 130 stars
        expect(merged.totalStars, 130);
        expect(merged.starEvents.containsKey('evt_devA_1'), isTrue);
        expect(merged.starEvents.containsKey('evt_devB_1'), isTrue);
      },
    );

    test(
      'Independent learning minutes and lessons on two devices are preserved',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        const baseline = UserStatsEntity(
          practicedLetters: {},
          completedLessons: {'lesson_0'},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 10,
          lastActiveDate: '2026-09-04',
          currentStreak: 1,
          totalStars: 50,
        );

        // Device A completes lesson 1 (5 mins)
        final deviceA = baseline
            .copyWith(completedLessons: {'lesson_0', 'lesson_1'})
            .recordLearningMinutes(5, eventId: 'lesson_lesson_1');

        // Device B completes lesson 2 (10 mins)
        final deviceB = baseline
            .copyWith(completedLessons: {'lesson_0', 'lesson_2'})
            .recordLearningMinutes(10, eventId: 'lesson_lesson_2');

        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(deviceA).toJson(),
            ),
          }),
        );
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        final result = await repo.updateUserStats(deviceB);
        final merged = result.getOrElse((_) => fail('updateUserStats failed'));

        // 10 base + 5 (A) + 10 (B) = 25 minutes
        expect(merged.totalLearningMinutes, 25);
        expect(
          merged.completedLessons,
          containsAll({'lesson_0', 'lesson_1', 'lesson_2'}),
        );
        expect(merged.minuteEvents.containsKey('lesson_lesson_1'), isTrue);
        expect(merged.minuteEvents.containsKey('lesson_lesson_2'), isTrue);
      },
    );

    test(
      'Duplicate reward event IDs are deduplicated and not counted twice',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        const baseline = UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-04',
          currentStreak: 1,
          totalStars: 100,
        );

        final deviceA = baseline.recordStarReward(
          15,
          eventId: 'duplicate_event_123',
        );
        final deviceB = baseline.recordStarReward(
          15,
          eventId: 'duplicate_event_123',
        );

        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(deviceA).toJson(),
            ),
          }),
        );
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        final result = await repo.updateUserStats(deviceB);
        final merged = result.getOrElse((_) => fail('updateUserStats failed'));

        // Should only count once: 100 + 15 = 115
        expect(merged.totalStars, 115);
        expect(merged.starEvents.length, 1);
      },
    );

    test(
      'Event pruning caps starEvents map and folds into baseStars correctly',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // Create 110 distinct star events
        var statsA = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );

        for (int i = 0; i < 60; i++) {
          statsA = statsA.recordStarReward(
            2,
            eventId: 'evt_a_${i.toString().padLeft(3, '0')}',
          );
        }

        var statsB = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );

        for (int i = 60; i < 110; i++) {
          statsB = statsB.recordStarReward(
            2,
            eventId: 'evt_b_${i.toString().padLeft(3, '0')}',
          );
        }

        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(statsA).toJson(),
            ),
          }),
        );
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        final result = await repo.updateUserStats(statsB);
        final merged = result.getOrElse((_) => fail('updateUserStats failed'));

        // Total stars must be 110 events * 2 = 220
        expect(merged.totalStars, 220);
        // Event map must be bounded to at most 100 entries
        expect(merged.starEvents.length, lessThanOrEqualTo(100));
      },
    );
  });

  group('Dynamic Streak Derivation', () {
    test('Consecutive practice dates ending today compute accurate streak', () {
      final practiceDates = {'2026-09-03', '2026-09-04', '2026-09-05'};
      final streak = StreakWeekLogic.deriveStreak(
        practiceDates,
        asOf: fixedClock, // 2026-09-05
        lastActiveDate: '2026-09-05',
      );
      expect(streak, 3);
    });

    test(
      'Consecutive practice dates ending yesterday retain active streak before today session',
      () {
        final practiceDates = {'2026-09-03', '2026-09-04'};
        final streak = StreakWeekLogic.deriveStreak(
          practiceDates,
          asOf: fixedClock, // 2026-09-05
          lastActiveDate: '2026-09-04',
        );
        expect(streak, 2);
      },
    );

    test('Inactive dates break streak and eliminate zombie streaks', () {
      // Practiced last week, inactive for 3 days
      final practiceDates = {'2026-08-30', '2026-08-31', '2026-09-01'};
      final streak = StreakWeekLogic.deriveStreak(
        practiceDates,
        asOf: fixedClock, // 2026-09-05
        lastActiveDate: '2026-09-01',
        fallbackStreak: 15, // zombie streak
      );
      expect(streak, 0);
    });

    test(
      'Complementary practice dates across devices merge into unified streak',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // Device A practiced 2026-09-03 and 2026-09-05
        const deviceA = UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 10,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 10,
          practiceDates: {'2026-09-03', '2026-09-05'},
        );

        // Device B practiced 2026-09-04
        const deviceB = UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 10,
          lastActiveDate: '2026-09-04',
          currentStreak: 1,
          totalStars: 10,
          practiceDates: {'2026-09-04'},
        );

        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(deviceA).toJson(),
            ),
          }),
        );
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        final result = await repo.updateUserStats(deviceB);
        final merged = result.getOrElse((_) => fail('updateUserStats failed'));

        // Union of practice dates {2026-09-03, 2026-09-04, 2026-09-05} bridges the gap -> streak is 3
        expect(
          merged.practiceDates,
          containsAll({'2026-09-03', '2026-09-04', '2026-09-05'}),
        );
        expect(merged.currentStreak, 3);
      },
    );
  });

  group('Per-User Storage Isolation', () {
    test(
      'Switching user accounts on the same device isolates local cache',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        const userAlice = UserEntity(
          id: 'usr_alice',
          email: 'alice@example.com',
        );
        const userBob = UserEntity(id: 'usr_bob', email: 'bob@example.com');

        // 1. User Alice logs in and saves stats
        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => auth.getCurrentUser(),
        ).thenAnswer((_) async => const Right(userAlice));
        when(
          () => auth.getUserPrefs(),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        const aliceStats = UserStatsEntity(
          practicedLetters: {'a'},
          completedLessons: {'l_alice'},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 50,
          lastActiveDate: '2026-09-05',
          currentStreak: 5,
          totalStars: 100,
        );

        await repo.updateUserStats(aliceStats);

        // Verify Alice stats are in scoped key
        final aliceLocal = prefs.getString('user_stats_usr_alice');
        expect(aliceLocal, isNotNull);
        expect(aliceLocal, contains('"totalStars":100'));

        // 2. User Bob logs in on the same device
        when(
          () => auth.getCurrentUser(),
        ).thenAnswer((_) async => const Right(userBob));
        when(
          () => auth.getUserPrefs(),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));

        // Bob reads user stats: should NOT see Alice's stats
        final bobInitialResult = await repo.getUserStats();
        final bobInitialStats = bobInitialResult.getOrElse(
          (_) => fail('getUserStats failed'),
        );
        expect(bobInitialStats.totalStars, 0);
        expect(bobInitialStats.completedLessons, isEmpty);

        // Bob saves his own stats
        const bobStats = UserStatsEntity(
          practicedLetters: {'b'},
          completedLessons: {'l_bob'},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 10,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 25,
        );
        await repo.updateUserStats(bobStats);

        // Verify Bob stats are in Bob's scoped key
        final bobLocal = prefs.getString('user_stats_usr_bob');
        expect(bobLocal, isNotNull);
        expect(bobLocal, contains('"totalStars":25'));

        // Verify Alice's scoped cache remained pristine and untouched
        final aliceLocalAfter = prefs.getString('user_stats_usr_alice');
        expect(aliceLocalAfter, isNotNull);
        expect(aliceLocalAfter, contains('"totalStars":100'));
        expect(aliceLocalAfter, isNot(contains('l_bob')));
      },
    );

    test('Guest user uses isolated user_stats_guest storage', () async {
      final repo = ProfileRepositoryImpl(auth, prefs, clock: () => fixedClock);

      when(() => auth.isLoggedIn()).thenAnswer((_) async => const Right(false));
      when(
        () => auth.getCurrentUser(),
      ).thenAnswer((_) async => const Right(null));

      const guestStats = UserStatsEntity(
        practicedLetters: {'g'},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 5,
        lastActiveDate: '2026-09-05',
        currentStreak: 1,
        totalStars: 15,
      );

      await repo.updateUserStats(guestStats);

      expect(prefs.getString('user_stats_guest'), isNotNull);
      expect(prefs.getString('user_stats_guest'), contains('"totalStars":15'));
    });
  });
}
