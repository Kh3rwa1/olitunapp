import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/profile/data/models/user_stats_model.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileRepositoryImpl repo;
  late _MockAuthRepository auth;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auth = _MockAuthRepository();
    when(() => auth.isLoggedIn()).thenAnswer((_) async => const Right(false));
    repo = ProfileRepositoryImpl(auth, prefs);
  });

  test('getUserStats returns empty defaults when no data is stored', () async {
    final result = await repo.getUserStats();
    result.match((_) => fail('should be right'), (stats) {
      expect(stats.totalStars, 0);
      expect(stats.practicedLetters, isEmpty);
    });
  });

  test(
    'getUserStats returns stored stats round-tripped through JSON',
    () async {
      const stored = UserStatsEntity(
        practicedLetters: {'a', 'b'},
        completedLessons: {'l1'},
        quizHistory: {},
        categoryMastery: {'cat': 7},
        totalLearningMinutes: 42,
        lastActiveDate: '2025-01-01',
        currentStreak: 3,
        totalStars: 99,
      );
      await prefs.setString(
        'user_progress_data',
        jsonEncode(UserStatsModel.fromEntity(stored).toJson()),
      );

      final result = await repo.getUserStats();
      result.match((_) => fail('should be right'), (stats) {
        expect(stats.totalStars, 99);
        expect(stats.categoryMastery['cat'], 7);
        expect(stats.practicedLetters.contains('a'), isTrue);
      });
    },
  );

  test('getUserStats maps malformed stored JSON to CacheFailure', () async {
    await prefs.setString('user_progress_data', '{not json');

    final result = await repo.getUserStats();
    result.match(
      (failure) => expect(failure, isA<CacheFailure>()),
      (_) => fail('should be left'),
    );
  });

  test('getUserStats maps structurally-invalid JSON to CacheFailure', () async {
    await prefs.setString(
      'user_progress_data',
      jsonEncode({'totalStars': 'not-an-int'}),
    );

    final result = await repo.getUserStats();
    result.match(
      (failure) => expect(failure, isA<CacheFailure>()),
      (_) => fail('should be left'),
    );
  });

  test('updateUserStats persists data and returns Right(null)', () async {
    const stats = UserStatsEntity(
      practicedLetters: {'x'},
      completedLessons: {},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 1,
      lastActiveDate: '2025-05-03',
      currentStreak: 1,
      totalStars: 5,
    );
    final res = await repo.updateUserStats(stats);
    expect(res.isRight(), isTrue);
    final stored = prefs.getString('user_progress_data');
    expect(stored, isNotNull);
    expect(stored, contains('"totalStars":5'));
  });

  test('updateAvatar writes both emoji and color index to prefs', () async {
    final res = await repo.updateAvatar('🦊', 3);
    expect(res.isRight(), isTrue);
    expect(prefs.getString('user_avatar_emoji'), '🦊');
    expect(prefs.getInt('user_avatar_color'), 3);
  });

  test(
    'updateDisplayName writes name and returns Right when not logged in',
    () async {
      final res = await repo.updateDisplayName('Sido');
      expect(res.isRight(), isTrue);
      expect(prefs.getString('user_name'), 'Sido');
    },
  );

  test(
    'updateDisplayName still writes local name when auth status check fails',
    () async {
      when(
        () => auth.isLoggedIn(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final res = await repo.updateDisplayName('Kanhu');
      expect(res.isRight(), isTrue);
      expect(prefs.getString('user_name'), 'Kanhu');
    },
  );

  test(
    'updateDisplayName keeps local name when cloud display name sync fails',
    () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => const Right(true));
      when(
        () => auth.updateDisplayName('Baha'),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final res = await repo.updateDisplayName('Baha');
      expect(res.isRight(), isTrue);
      expect(prefs.getString('user_name'), 'Baha');
      verify(() => auth.updateDisplayName('Baha')).called(1);
    },
  );

  group('Bi-directional Cloud Sync Tests', () {
    test('getUserStats uploads local stats to cloud when cloud is empty', () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => const Right(true));
      when(() => auth.getUserPrefs()).thenAnswer((_) async => const Right(<String, dynamic>{}));
      when(() => auth.updateUserPrefs(any())).thenAnswer((_) async => const Right(null));

      const local = UserStatsEntity(
        practicedLetters: {'x'},
        completedLessons: {'l1'},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 10,
        lastActiveDate: '2025-01-01',
        currentStreak: 2,
        totalStars: 15,
      );
      await prefs.setString(
        'user_progress_data',
        jsonEncode(UserStatsModel.fromEntity(local).toJson()),
      );

      final result = await repo.getUserStats();
      expect(result.isRight(), isTrue);
      final returnedStats = result.getOrElse((_) => fail('should be right'));
      expect(returnedStats.totalStars, 15);

      verify(() => auth.updateUserPrefs(any())).called(1);
    });

    test('getUserStats merges local and cloud stats when both exist', () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => const Right(true));
      
      const local = UserStatsEntity(
        practicedLetters: {'a'},
        completedLessons: {'l1'},
        quizHistory: {},
        categoryMastery: {'numbers': 10},
        totalLearningMinutes: 5,
        lastActiveDate: '2025-01-01',
        currentStreak: 1,
        totalStars: 10,
      );

      const cloud = UserStatsEntity(
        practicedLetters: {'b'},
        completedLessons: {'l2'},
        quizHistory: {},
        categoryMastery: {'alphabets': 20},
        totalLearningMinutes: 15,
        lastActiveDate: '2025-01-02',
        currentStreak: 3,
        totalStars: 25,
      );

      when(() => auth.getUserPrefs()).thenAnswer(
        (_) async => Right(<String, dynamic>{
          'user_progress_data': jsonEncode(UserStatsModel.fromEntity(cloud).toJson()),
        }),
      );
      when(() => auth.updateUserPrefs(any())).thenAnswer((_) async => const Right(null));

      await prefs.setString(
        'user_progress_data',
        jsonEncode(UserStatsModel.fromEntity(local).toJson()),
      );

      final result = await repo.getUserStats();
      expect(result.isRight(), isTrue);
      final merged = result.getOrElse((_) => fail('should be right'));

      expect(merged.totalStars, 25); // Max of 10 and 25
      expect(merged.currentStreak, 3); // Max of 1 and 3
      expect(merged.practicedLetters, containsAll({'a', 'b'})); // Union
      expect(merged.completedLessons, containsAll({'l1', 'l2'})); // Union
      expect(merged.categoryMastery['numbers'], 10);
      expect(merged.categoryMastery['alphabets'], 20);
    });
  });
}
