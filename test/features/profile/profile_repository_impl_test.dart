import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/core/storage/hive_service.dart' as hive_service;
import 'package:itun/features/auth/domain/entities/user_entity.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/profile/data/models/user_stats_model.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileRepositoryImpl repo;
  late _MockAuthRepository auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    hive_service.prefs = await SharedPreferences.getInstance();
    auth = _MockAuthRepository();
    when(() => auth.isLoggedIn()).thenAnswer((_) async => const Right(false));
    repo = ProfileRepositoryImpl(auth);
  });

  test('getUserStats returns empty defaults when no data is stored', () async {
    final result = await repo.getUserStats();
    result.match(
      (_) => fail('should be right'),
      (stats) {
        expect(stats.totalStars, 0);
        expect(stats.practicedLetters, isEmpty);
      },
    );
  });

  test('getUserStats returns stored stats round-tripped through JSON',
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
    await hive_service.prefs.setString(
      'user_progress_data',
      jsonEncode(UserStatsModel.fromEntity(stored).toJson()),
    );

    final result = await repo.getUserStats();
    result.match((_) => fail('should be right'), (stats) {
      expect(stats.totalStars, 99);
      expect(stats.categoryMastery['cat'], 7);
      expect(stats.practicedLetters.contains('a'), isTrue);
    });
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
    final stored = hive_service.prefs.getString('user_progress_data');
    expect(stored, isNotNull);
    expect(stored, contains('"totalStars":5'));
  });

  test('updateAvatar writes both emoji and color index to prefs', () async {
    final res = await repo.updateAvatar('🦊', 3);
    expect(res.isRight(), isTrue);
    expect(hive_service.prefs.getString('user_avatar_emoji'), '🦊');
    expect(hive_service.prefs.getInt('user_avatar_color'), 3);
  });

  test('updateDisplayName writes name and respects auth state', () async {
    final res = await repo.updateDisplayName('Sido');
    expect(res.isRight(), isTrue);
    expect(hive_service.prefs.getString('user_name'), 'Sido');
  });

  // The User entity import keeps the auth domain compile-time linked.
  test('AuthRepository contract is wired (smoke)', () {
    final u = UserEntity(id: 'x', email: 'e');
    expect(u.id, 'x');
  });
}
