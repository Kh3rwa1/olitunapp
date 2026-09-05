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

  test('normal empty update merges cloud progress and is not a reset', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _Auth();
    when(auth.isLoggedIn).thenAnswer((_) async => const Right(true));
    when(auth.getUserPrefs).thenAnswer(
      (_) async => Right({
        'user_progress_data': jsonEncode(
          UserStatsModel.fromEntity(_progress).toJson(),
        ),
      }),
    );
    when(() => auth.updateUserPrefs(any())).thenAnswer(
      (_) async => const Right(null),
    );

    final result = await ProfileRepositoryImpl(
      auth,
      prefs,
    ).updateUserStats(_empty);
    final merged = result.getRight().toNullable()!;
    expect(merged.totalStars, 40);
    expect(merged.completedLessons, {'lesson-1'});
    expect(merged.syncEpoch, 0);
  });

  test('explicit offline reset advances epoch and persists empty data', () async {
    SharedPreferences.setMockInitialValues({
      'user_progress_data': jsonEncode(
        UserStatsModel.fromEntity(_progress).toJson(),
      ),
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = _Auth();
    when(auth.isLoggedIn).thenAnswer((_) async => const Right(false));

    final result = await ProfileRepositoryImpl(auth, prefs).resetUserStats();
    final reset = result.getRight().toNullable()!;
    expect(reset.syncEpoch, 1);
    expect(reset.totalStars, 0);
    expect(reset.completedLessons, isEmpty);
  });

  test('explicit logged-in reset wins over cloud and uploads', () async {
    SharedPreferences.setMockInitialValues({
      'user_progress_data': jsonEncode(
        UserStatsModel.fromEntity(_progress).toJson(),
      ),
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = _Auth();
    when(auth.isLoggedIn).thenAnswer((_) async => const Right(true));
    when(auth.getUserPrefs).thenAnswer(
      (_) async => Right({
        'user_progress_data': jsonEncode(
          UserStatsModel.fromEntity(
            _progress.copyWith(syncEpoch: 4),
          ).toJson(),
        ),
      }),
    );
    when(() => auth.updateUserPrefs(any())).thenAnswer(
      (_) async => const Right(null),
    );

    final result = await ProfileRepositoryImpl(auth, prefs).resetUserStats();
    final reset = result.getRight().toNullable()!;
    expect(reset.syncEpoch, 5);
    expect(reset.totalStars, 0);

    final uploaded = verify(
      () => auth.updateUserPrefs(captureAny()),
    ).captured.single as Map<String, dynamic>;
    final cloud = UserStatsModel.fromJson(
      jsonDecode(uploaded['user_progress_data'] as String)
          as Map<String, dynamic>,
    );
    expect(cloud.syncEpoch, 5);
    expect(cloud.practicedLetters, isEmpty);
  });

  test('older cloud epoch cannot restore reset progress', () async {
    final reset = _empty.copyWith(syncEpoch: 2);
    SharedPreferences.setMockInitialValues({
      'user_progress_data': jsonEncode(
        UserStatsModel.fromEntity(reset).toJson(),
      ),
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = _Auth();
    when(auth.isLoggedIn).thenAnswer((_) async => const Right(true));
    when(auth.getUserPrefs).thenAnswer(
      (_) async => Right({
        'user_progress_data': jsonEncode(
          UserStatsModel.fromEntity(
            _progress.copyWith(syncEpoch: 1),
          ).toJson(),
        ),
      }),
    );
    when(() => auth.updateUserPrefs(any())).thenAnswer(
      (_) async => const Right(null),
    );

    final result = await ProfileRepositoryImpl(auth, prefs).getUserStats();
    final resolved = result.getRight().toNullable()!;
    expect(resolved.syncEpoch, 2);
    expect(resolved.totalStars, 0);
    expect(resolved.completedLessons, isEmpty);
  });
}
