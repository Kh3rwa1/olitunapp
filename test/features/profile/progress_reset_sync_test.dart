import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/profile/data/models/user_stats_model.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';

class _Auth extends Mock implements AuthRepository {}

const _progress = UserStatsEntity(
  practicedLetters: {'ᱚ'},
  completedLessons: {'lesson-1'},
  quizHistory: {},
  categoryMastery: {'alphabets': 20},
  totalLearningMinutes: 12,
  lastActiveDate: '2026-09-05',
  currentStreak: 3,
  totalStars: 40,
);

const _empty = UserStatsEntity(
  practicedLetters: {},
  completedLessons: {},
  quizHistory: {},
  categoryMastery: {},
  totalLearningMinutes: 0,
  lastActiveDate: '',
  currentStreak: 0,
  totalStars: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy payloads default to sync epoch zero', () {
    final json = UserStatsModel.fromEntity(_progress).toJson()
      ..remove('syncEpoch');
    expect(UserStatsModel.fromJson(json).syncEpoch, 0);
  });

  test('sync epoch round-trips through the model', () {
    final model = UserStatsModel.fromEntity(_progress.copyWith(syncEpoch: 7));
    expect(UserStatsModel.fromJson(model.toJson()).syncEpoch, 7);
  });

  test('offline reset advances the epoch and persists empty progress', () async {
    SharedPreferences.setMockInitialValues({
      'user_progress_data': jsonEncode(UserStatsModel.fromEntity(_progress).toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = _Auth();
    when(auth.isLoggedIn).thenAnswer((_) async => const Right(false));
    final repo = ProfileRepositoryImpl(auth, prefs);

    final result = await repo.updateUserStats(_empty);
    final reset = result.getRight().toNullable()!;

    expect(reset.syncEpoch, 1);
    expect(reset.totalStars, 0);
    expect(reset.completedLessons, isEmpty);
    final stored = UserStatsModel.fromJson(
      jsonDecode(prefs.getString('user_progress_data')!) as Map<String, dynamic>,
    );
    expect(stored.syncEpoch, 1);
    expect(stored.practicedLetters, isEmpty);
  });

  test('cloud progress from an older epoch cannot restore a reset', () async {
    final reset = _empty.copyWith(syncEpoch: 2);
    SharedPreferences.setMockInitialValues({
      'user_progress_data': jsonEncode(UserStatsModel.fromEntity(reset).toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = _Auth();
    when(auth.isLoggedIn).thenAnswer((_) async => const Right(true));
    when(auth.getUserPrefs).thenAnswer((_) async => Right({
      'user_progress_data': jsonEncode(UserStatsModel.fromEntity(_progress.copyWith(syncEpoch: 1)).toJson()),
    }));
    when(() => auth.updateUserPrefs(any())).thenAnswer((_) async => const Right(null));

    final result = await ProfileRepositoryImpl(auth, prefs).getUserStats();
    final resolved = result.getRight().toNullable()!;
    expect(resolved.syncEpoch, 2);
    expect(resolved.totalStars, 0);
    expect(resolved.completedLessons, isEmpty);
  });

  test('logged-in reset is uploaded instead of unioned with cloud data', () async {
    SharedPreferences.setMockInitialValues({
      'user_progress_data': jsonEncode(UserStatsModel.fromEntity(_progress).toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = _Auth();
    when(auth.isLoggedIn).thenAnswer((_) async => const Right(true));
    when(auth.getUserPrefs).thenAnswer((_) async => Right({
      'user_progress_data': jsonEncode(UserStatsModel.fromEntity(_progress).toJson()),
    }));
    when(() => auth.updateUserPrefs(any())).thenAnswer((_) async => const Right(null));

    final result = await ProfileRepositoryImpl(auth, prefs).updateUserStats(_empty);
    final reset = result.getRight().toNullable()!;
    expect(reset.syncEpoch, 1);
    expect(reset.totalStars, 0);

    final uploaded = verify(() => auth.updateUserPrefs(captureAny())).captured.single as Map<String, dynamic>;
    final cloud = UserStatsModel.fromJson(
      jsonDecode(uploaded['user_progress_data'] as String) as Map<String, dynamic>,
    );
    expect(cloud.syncEpoch, 1);
    expect(cloud.practicedLetters, isEmpty);
  });
}
