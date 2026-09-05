import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/domain/entities/user_entity.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/profile/data/models/user_stats_model.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/streak_week_logic.dart';
import 'package:itun/features/profile/presentation/providers/user_stats_provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAnalyticsService extends Mock implements LearningAnalyticsService {}

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
        // Compacted events must be recorded
        expect(merged.compactedStarEvents, isNotEmpty);
      },
    );

    test(
      'Stale replay with 105 events does not re-credit compacted events',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // Device A records 105 events (each 5 stars = 525 stars)
        var deviceA = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 105; i++) {
          deviceA = deviceA.recordStarReward(
            5,
            eventId: 'evt_${i.toString().padLeft(3, '0')}',
          );
        }

        // Simulate cloud having merged and compacted Device A's progress
        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => auth.getUserPrefs(),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        final resultA = await repo.updateUserStats(deviceA);
        final compactedA = resultA.getOrElse(
          (_) => fail('updateUserStats failed'),
        );

        expect(compactedA.totalStars, 525);
        expect(
          compactedA.compactedStarEvents.length,
          5,
        ); // 105 - 100 = 5 compacted
        expect(compactedA.starEvents.length, 100);

        // Device B was an offline device that had a stale snapshot containing the first 50 events
        // (including the 5 that A compacted: evt_000..evt_004) PLUS a brand-new event evt_b_unique (+5)
        var deviceB = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 50; i++) {
          deviceB = deviceB.recordStarReward(
            5,
            eventId: 'evt_${i.toString().padLeft(3, '0')}',
          );
        }
        deviceB = deviceB.recordStarReward(5, eventId: 'evt_b_unique');
        expect(deviceB.totalStars, 255);

        // Mock cloud returning Device A's compacted stats to Device B
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(compactedA).toJson(),
            ),
          }),
        );

        // Device B syncs and merges with cloud
        final resultB = await repo.updateUserStats(deviceB);
        final mergedB = resultB.getOrElse((_) => fail('merge failed'));

        // Total unique events: 105 from A + 1 unique from B = 106 events * 5 = 530 stars!
        // Compacted events (evt_000..evt_004) MUST NOT be double-counted!
        expect(mergedB.totalStars, 530);
        expect(mergedB.starEvents.containsKey('evt_b_unique'), isTrue);
        expect(mergedB.compactedStarEvents.contains('evt_000'), isTrue);
        expect(mergedB.starEvents.containsKey('evt_000'), isFalse);
      },
    );

    test(
      'Vector Checkpoint CRDT: 601 real events -> stale replay of old event remains 601 across repeated replays',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // 601 real events on Device A (each 1 star)
        var deviceA = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 601; i++) {
          deviceA = deviceA.recordStarReward(1, eventId: 'devA_$i');
        }

        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => auth.getUserPrefs(),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        // Sync and compact on cloud: 501 events folded into base, 100 active
        final resultA = await repo.updateUserStats(deviceA);
        final compactedA = resultA.getOrElse(
          (_) => fail('updateUserStats failed'),
        );

        expect(compactedA.totalStars, 601);
        expect(compactedA.starEvents.length, 100);
        // Checkpoint must reflect sequence 500
        expect(compactedA.starCheckpoints['devA'], 500);
        expect(compactedA.baseStarsByOrigin['devA'], 501);

        // A stale snapshot containing early events (devA_0..devA_9), which are well beyond
        // the 500 tracking limit and would be evicted under simple set tombstoning.
        var staleDevice = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 10; i++) {
          staleDevice = staleDevice.recordStarReward(1, eventId: 'devA_$i');
        }

        // Mock cloud returning Device A's compacted stats
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(compactedA).toJson(),
            ),
          }),
        );

        // First stale replay: must remain 601 (NOT 602)
        final replayResult1 = await repo.updateUserStats(staleDevice);
        final replayed1 = replayResult1.getOrElse(
          (_) => fail('replay 1 failed'),
        );
        expect(replayed1.totalStars, 601);

        // Repeated stale replay: must still remain 601 (NOT 603)
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(replayed1).toJson(),
            ),
          }),
        );
        final replayResult2 = await repo.updateUserStats(staleDevice);
        final replayed2 = replayResult2.getOrElse(
          (_) => fail('replay 2 failed'),
        );
        expect(replayed2.totalStars, 601);
      },
    );

    test(
      'Vector Checkpoint CRDT: Two independently compacted devices (101 events on A + 101 on B) merge to exactly 202',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // Device A has 101 real events (1 star each, origin devA)
        var deviceA = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 101; i++) {
          deviceA = deviceA.recordStarReward(1, eventId: 'devA_$i');
        }

        // Device B has 101 different real events (1 star each, origin devB)
        var deviceB = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 101; i++) {
          deviceB = deviceB.recordStarReward(1, eventId: 'devB_$i');
        }

        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => auth.getUserPrefs(),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        // Device A compacts offline: 1 event folded into base (baseStarsByOrigin['devA'] = 1)
        final resultA = await repo.updateUserStats(deviceA);
        final compactedA = resultA.getOrElse((_) => fail('compact A failed'));
        expect(compactedA.totalStars, 101);
        expect(compactedA.starEvents.length, 100);
        expect(compactedA.baseStarsByOrigin['devA'], 1);

        // Device B compacts offline: 1 event folded into base (baseStarsByOrigin['devB'] = 1)
        when(
          () => auth.getUserPrefs(),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));
        final resultB = await repo.updateUserStats(deviceB);
        final compactedB = resultB.getOrElse((_) => fail('compact B failed'));
        expect(compactedB.totalStars, 101);
        expect(compactedB.starEvents.length, 100);
        expect(compactedB.baseStarsByOrigin['devB'], 1);

        // Now merge compacted Device A and compacted Device B through cloud sync
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(compactedA).toJson(),
            ),
          }),
        );

        final mergeResult = await repo.updateUserStats(compactedB);
        final merged = mergeResult.getOrElse((_) => fail('merge failed'));

        // MUST be 202, NOT 201!
        expect(merged.totalStars, 202);
        expect(merged.starEvents.length, 100);
        expect(merged.baseStarsByOrigin['devA'], 101);
        expect(merged.baseStarsByOrigin['devB'], 1);
        expect(merged.starCheckpoints['devA'], 100);
        expect(merged.starCheckpoints['devB'], 0);
      },
    );

    test(
      'Two devices using default star_<timestamp> format merge to 202 instead of 101',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // Device A has 101 unsequenced events (e.g. star_<timestamp>)
        var deviceA = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 101; i++) {
          deviceA = deviceA.recordStarReward(1, eventId: 'star_1725547382$i');
        }

        // Device B has 101 different unsequenced events
        var deviceB = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 101; i++) {
          deviceB = deviceB.recordStarReward(1, eventId: 'star_1725547383$i');
        }

        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => auth.getUserPrefs(),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        // Device A uploads its 101 star_<timestamp> events to cloud
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(deviceA).toJson(),
            ),
          }),
        );

        // Device B merges its 101 events with Device A's cloud progress
        final mergeResult = await repo.updateUserStats(deviceB);
        final merged = mergeResult.getOrElse((_) => fail('merge failed'));

        // In the flawed algorithm, Device B's timestamp checkpoint on origin 'star'
        // suppressed all 101 events of Device A, yielding only 101 instead of 202.
        // With generic unsequenced origins treated as discrete, all 202 events are preserved.
        expect(merged.totalStars, 202);
      },
    );

    test(
      'Previously unseen event arriving below a checkpoint remains preserved (103 not 102)',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // Device A has 102 events on origin devA and compacts to checkpoint 1
        var deviceA = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 0; i < 102; i++) {
          deviceA = deviceA.recordStarReward(1, originId: 'devA', seq: i);
        }

        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => auth.getUserPrefs(),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        final resultA = await repo.updateUserStats(deviceA);
        final compactedA = resultA.getOrElse((_) => fail('compact A failed'));
        expect(compactedA.totalStars, 102);
        expect(compactedA.starCheckpoints['devA'], 1);

        // A previously unseen event arrives from another device / discrete source
        final unseenDevice = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        ).recordStarReward(1, eventId: 'unseen_external_event_1');

        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(compactedA).toJson(),
            ),
          }),
        );

        final mergeResult = await repo.updateUserStats(unseenDevice);
        final merged = mergeResult.getOrElse((_) => fail('merge failed'));

        // MUST be 103, NOT 102!
        expect(merged.totalStars, 103);
        expect(
          merged.starEvents.containsKey('unseen_external_event_1'),
          isTrue,
        );
      },
    );

    test(
      'Real UserStatsNotifier: two client containers generate persistent origins and safe sequences, merging cleanly',
      () async {
        final mockAnalytics = _MockAnalyticsService();
        when(
          () => mockAnalytics.track(
            any(),
            source: any(named: 'source'),
            sourceId: any(named: 'sourceId'),
            learnerLevel: any(named: 'learnerLevel'),
            scriptMode: any(named: 'scriptMode'),
            metadata: any(named: 'metadata'),
          ),
        ).thenAnswer((_) async {});

        // Client A SharedPreferences
        SharedPreferences.setMockInitialValues({});
        final prefsA = await SharedPreferences.getInstance();
        final containerA = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefsA),
            authRepositoryProvider.overrideWithValue(auth),
            userStatsClockProvider.overrideWithValue(() => fixedClock),
            learningAnalyticsServiceProvider.overrideWithValue(mockAnalytics),
          ],
        );
        addTearDown(containerA.dispose);

        // Wait for container A to initialize
        await containerA.read(userStatsProvider.notifier).loadStats();

        // Client A awards 5 stars through the real notifier
        await containerA.read(userStatsProvider.notifier).addStars(5);
        final statsA = containerA.read(userStatsProvider).value!;
        expect(statsA.totalStars, 5);
        final eventKeyA = statsA.starEvents.keys.first;
        expect(eventKeyA, startsWith('c_'));
        expect(eventKeyA, endsWith('_1'));

        // Client B SharedPreferences
        SharedPreferences.setMockInitialValues({});
        final prefsB = await SharedPreferences.getInstance();
        final containerB = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefsB),
            authRepositoryProvider.overrideWithValue(auth),
            userStatsClockProvider.overrideWithValue(() => fixedClock),
            learningAnalyticsServiceProvider.overrideWithValue(mockAnalytics),
          ],
        );
        addTearDown(containerB.dispose);

        await containerB.read(userStatsProvider.notifier).loadStats();

        // Client B awards 10 stars through the real notifier
        await containerB.read(userStatsProvider.notifier).addStars(10);
        final statsB = containerB.read(userStatsProvider).value!;
        expect(statsB.totalStars, 10);
        final eventKeyB = statsB.starEvents.keys.first;
        expect(eventKeyB, startsWith('c_'));
        expect(eventKeyB, endsWith('_1'));

        // The two origins MUST be distinct
        expect(eventKeyA, isNot(equals(eventKeyB)));

        // Merge Client A and Client B stats through repository
        final repo = ProfileRepositoryImpl(
          auth,
          prefsA,
          clock: () => fixedClock,
        );
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

        final mergeResult = await repo.updateUserStats(statsB);
        final merged = mergeResult.getOrElse((_) => fail('merge failed'));

        // Must preserve both earnings: 5 + 10 = 15!
        expect(merged.totalStars, 15);
        expect(merged.starEvents.length, 2);
      },
    );

    test(
      'Compaction merge is commutative and deterministic (CRDT property)',
      () async {
        final repo = ProfileRepositoryImpl(
          auth,
          prefs,
          clock: () => fixedClock,
        );

        // Create state X with 60 events
        var stateX = const UserStatsEntity(
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
          stateX = stateX.recordStarReward(
            3,
            eventId: 'x_${i.toString().padLeft(3, '0')}',
          );
        }

        // Create state Y with 60 events (some overlapping, some distinct)
        var stateY = const UserStatsEntity(
          practicedLetters: {},
          completedLessons: {},
          quizHistory: {},
          categoryMastery: {},
          totalLearningMinutes: 0,
          lastActiveDate: '2026-09-05',
          currentStreak: 1,
          totalStars: 0,
        );
        for (int i = 30; i < 90; i++) {
          stateY = stateY.recordStarReward(
            3,
            eventId: 'x_${i.toString().padLeft(3, '0')}',
          );
        }
        for (int i = 0; i < 30; i++) {
          stateY = stateY.recordStarReward(
            3,
            eventId: 'y_${i.toString().padLeft(3, '0')}',
          );
        }

        // Merge X then Y
        when(
          () => auth.isLoggedIn(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => auth.updateUserPrefs(any()),
        ).thenAnswer((_) async => const Right(null));

        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(stateX).toJson(),
            ),
          }),
        );
        final mergeXY = (await repo.updateUserStats(
          stateY,
        )).getOrElse((_) => fail('XY failed'));

        // Merge Y then X
        when(() => auth.getUserPrefs()).thenAnswer(
          (_) async => Right(<String, dynamic>{
            'user_progress_data': jsonEncode(
              UserStatsModel.fromEntity(stateY).toJson(),
            ),
          }),
        );
        final mergeYX = (await repo.updateUserStats(
          stateX,
        )).getOrElse((_) => fail('YX failed'));

        // Total unique events: 90 ('x_000'..'x_089') + 30 ('y_000'..'y_029') = 120 events * 3 = 360 stars
        expect(mergeXY.totalStars, 360);
        expect(mergeYX.totalStars, 360);
        expect(mergeXY.totalStars, equals(mergeYX.totalStars));
        expect(mergeXY.starEvents, equals(mergeYX.starEvents));
        expect(
          mergeXY.compactedStarEvents,
          equals(mergeYX.compactedStarEvents),
        );
      },
    );

    test('Learning minutes compaction and stale replay deduplication', () async {
      final repo = ProfileRepositoryImpl(auth, prefs, clock: () => fixedClock);

      var deviceA = const UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '2026-09-05',
        currentStreak: 1,
        totalStars: 0,
      );
      for (int i = 0; i < 110; i++) {
        deviceA = deviceA.recordLearningMinutes(
          2,
          eventId: 'min_${i.toString().padLeft(3, '0')}',
        );
      }

      when(() => auth.isLoggedIn()).thenAnswer((_) async => const Right(true));
      when(
        () => auth.getUserPrefs(),
      ).thenAnswer((_) async => const Right(<String, dynamic>{}));
      when(
        () => auth.updateUserPrefs(any()),
      ).thenAnswer((_) async => const Right(null));

      final resultA = await repo.updateUserStats(deviceA);
      final compactedA = resultA.getOrElse(
        (_) => fail('updateUserStats failed'),
      );

      expect(compactedA.totalLearningMinutes, 220); // 110 * 2
      expect(compactedA.compactedMinuteEvents.length, 10);
      expect(compactedA.minuteEvents.length, 100);

      // Stale device B has first 20 events (which are compacted in A) plus min_b_new
      var deviceB = const UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '2026-09-05',
        currentStreak: 1,
        totalStars: 0,
      );
      for (int i = 0; i < 20; i++) {
        deviceB = deviceB.recordLearningMinutes(
          2,
          eventId: 'min_${i.toString().padLeft(3, '0')}',
        );
      }
      deviceB = deviceB.recordLearningMinutes(2, eventId: 'min_b_new');

      when(() => auth.getUserPrefs()).thenAnswer(
        (_) async => Right(<String, dynamic>{
          'user_progress_data': jsonEncode(
            UserStatsModel.fromEntity(compactedA).toJson(),
          ),
        }),
      );

      final resultB = await repo.updateUserStats(deviceB);
      final mergedB = resultB.getOrElse((_) => fail('merge failed'));

      // 110 events from A + 1 from B = 111 * 2 = 222 minutes
      expect(mergedB.totalLearningMinutes, 222);
      expect(mergedB.minuteEvents.containsKey('min_b_new'), isTrue);
      expect(mergedB.compactedMinuteEvents.contains('min_000'), isTrue);
      expect(mergedB.minuteEvents.containsKey('min_000'), isFalse);
    });
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
