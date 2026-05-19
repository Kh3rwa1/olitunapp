import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/observability/crash_reporting.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/entities/quiz_result_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_stats_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AuthRepository _authRepository;
  final SharedPreferences _prefs;
  static const _statsKey = 'user_progress_data';

  ProfileRepositoryImpl(this._authRepository, this._prefs);

  CacheFailure _recordedCacheFailure(Object e, [StackTrace? st]) {
    final f = CacheFailure(message: e.toString());
    CrashReporting.recordFailure(f, st);
    return f;
  }

  UserStatsEntity _mergeStats(UserStatsEntity a, UserStatsEntity b) {
    final letters = Set<String>.from(a.practicedLetters)
      ..addAll(b.practicedLetters);
    final lessons = Set<String>.from(a.completedLessons)
      ..addAll(b.completedLessons);

    final quizHistory = Map<String, QuizResultEntity>.from(a.quizHistory);
    b.quizHistory.forEach((key, resultB) {
      if (quizHistory.containsKey(key)) {
        final resultA = quizHistory[key]!;
        if (resultB.score > resultA.score) {
          quizHistory[key] = resultB;
        }
      } else {
        quizHistory[key] = resultB;
      }
    });

    final categoryMastery = Map<String, int>.from(a.categoryMastery);
    b.categoryMastery.forEach((key, valB) {
      final valA = categoryMastery[key] ?? 0;
      categoryMastery[key] = valB > valA ? valB : valA;
    });

    final totalStars = a.totalStars > b.totalStars
        ? a.totalStars
        : b.totalStars;
    final totalLearningMinutes = a.totalLearningMinutes > b.totalLearningMinutes
        ? a.totalLearningMinutes
        : b.totalLearningMinutes;
    final currentStreak = a.currentStreak > b.currentStreak
        ? a.currentStreak
        : b.currentStreak;

    String lastActiveDate = a.lastActiveDate;
    if (b.lastActiveDate.isNotEmpty) {
      if (lastActiveDate.isEmpty ||
          b.lastActiveDate.compareTo(lastActiveDate) > 0) {
        lastActiveDate = b.lastActiveDate;
      }
    }

    return UserStatsEntity(
      practicedLetters: letters,
      completedLessons: lessons,
      quizHistory: quizHistory,
      categoryMastery: categoryMastery,
      totalLearningMinutes: totalLearningMinutes,
      lastActiveDate: lastActiveDate,
      currentStreak: currentStreak,
      totalStars: totalStars,
    );
  }

  @override
  Future<Either<Failure, UserStatsEntity>> getUserStats() async {
    try {
      final storedLocal = _prefs.getString(_statsKey);
      UserStatsEntity? localStats;
      if (storedLocal != null) {
        localStats = UserStatsModel.fromJson(jsonDecode(storedLocal));
      }

      final loggedInResult = await _authRepository.isLoggedIn();
      final isLoggedIn = loggedInResult.getOrElse((_) => false);

      if (isLoggedIn) {
        final prefsResult = await _authRepository.getUserPrefs();
        return await prefsResult.fold(
          (failure) {
            return Right(
              localStats ??
                  const UserStatsEntity(
                    practicedLetters: {},
                    completedLessons: {},
                    quizHistory: {},
                    categoryMastery: {},
                    totalLearningMinutes: 0,
                    lastActiveDate: '',
                    currentStreak: 0,
                    totalStars: 0,
                  ),
            );
          },
          (cloudPrefs) async {
            final cloudProgressData = cloudPrefs[_statsKey];
            if (cloudProgressData != null &&
                cloudProgressData is String &&
                cloudProgressData.isNotEmpty) {
              final cloudStats = UserStatsModel.fromJson(
                jsonDecode(cloudProgressData),
              );

              if (localStats != null) {
                final resolvedStats = _mergeStats(localStats, cloudStats);
                await _prefs.setString(
                  _statsKey,
                  jsonEncode(UserStatsModel.fromEntity(resolvedStats).toJson()),
                );
                final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
                  ..[_statsKey] = jsonEncode(
                    UserStatsModel.fromEntity(resolvedStats).toJson(),
                  );
                await _authRepository.updateUserPrefs(cloudUpdate);
                return Right(resolvedStats);
              } else {
                await _prefs.setString(
                  _statsKey,
                  jsonEncode(UserStatsModel.fromEntity(cloudStats).toJson()),
                );
                return Right(cloudStats);
              }
            } else {
              if (localStats != null) {
                final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
                  ..[_statsKey] = jsonEncode(
                    UserStatsModel.fromEntity(localStats).toJson(),
                  );
                await _authRepository.updateUserPrefs(cloudUpdate);
                return Right(localStats);
              }
            }

            return const Right(
              UserStatsEntity(
                practicedLetters: {},
                completedLessons: {},
                quizHistory: {},
                categoryMastery: {},
                totalLearningMinutes: 0,
                lastActiveDate: '',
                currentStreak: 0,
                totalStars: 0,
              ),
            );
          },
        );
      }

      return Right(
        localStats ??
            const UserStatsEntity(
              practicedLetters: {},
              completedLessons: {},
              quizHistory: {},
              categoryMastery: {},
              totalLearningMinutes: 0,
              lastActiveDate: '',
              currentStreak: 0,
              totalStars: 0,
            ),
      );
    } catch (e) {
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserStats(UserStatsEntity stats) async {
    try {
      final model = UserStatsModel.fromEntity(stats);
      final jsonStr = jsonEncode(model.toJson());
      await _prefs.setString(_statsKey, jsonStr);

      final loggedInResult = await _authRepository.isLoggedIn();
      await loggedInResult.fold((failure) => null, (isLoggedIn) async {
        if (isLoggedIn) {
          final prefsResult = await _authRepository.getUserPrefs();
          await prefsResult.fold((failure) => null, (cloudPrefs) async {
            final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
              ..[_statsKey] = jsonStr;
            await _authRepository.updateUserPrefs(cloudUpdate);
          });
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String name) async {
    try {
      await _prefs.setString('user_name', name);
      final result = await _authRepository.isLoggedIn();
      await result.fold(
        (failure) async {
          CrashReporting.recordFailure(failure);
        },
        (isLoggedIn) async {
          if (isLoggedIn) {
            final syncResult = await _authRepository.updateDisplayName(name);
            syncResult.fold(CrashReporting.recordFailure, (_) {});
          }
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateAvatar(
    String emoji,
    int colorIndex,
  ) async {
    await _prefs.setString('user_avatar_emoji', emoji);
    await _prefs.setInt('user_avatar_color', colorIndex);
    return const Right(null);
  }
}
