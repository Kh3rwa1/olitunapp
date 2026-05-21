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
                final cloudResult = await _authRepository.updateUserPrefs(cloudUpdate);
                await cloudResult.fold(
                  (failure) async => await _prefs.setBool('is_stats_synced', false),
                  (_) async => await _prefs.setBool('is_stats_synced', true),
                );
                return Right(resolvedStats);
              } else {
                await _prefs.setString(
                  _statsKey,
                  jsonEncode(UserStatsModel.fromEntity(cloudStats).toJson()),
                );
                await _prefs.setBool('is_stats_synced', true);
                return Right(cloudStats);
              }
            } else {
              if (localStats != null) {
                final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
                  ..[_statsKey] = jsonEncode(
                    UserStatsModel.fromEntity(localStats).toJson(),
                  );
                final cloudResult = await _authRepository.updateUserPrefs(cloudUpdate);
                await cloudResult.fold(
                  (failure) async => await _prefs.setBool('is_stats_synced', false),
                  (_) async => await _prefs.setBool('is_stats_synced', true),
                );
                return Right(localStats);
              }
            }

            await _prefs.setBool('is_stats_synced', true);
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

      await _prefs.setBool('is_stats_synced', true);
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
  Future<Either<Failure, UserStatsEntity>> updateUserStats(UserStatsEntity stats) async {
    try {
      final model = UserStatsModel.fromEntity(stats);
      final jsonStr = jsonEncode(model.toJson());
      await _prefs.setString(_statsKey, jsonStr);

      final loggedInResult = await _authRepository.isLoggedIn();
      final isLoggedIn = loggedInResult.getOrElse((_) => false);
      UserStatsEntity finalStats = stats;
      bool synced = false;

      if (isLoggedIn) {
        final prefsResult = await _authRepository.getUserPrefs();
        await prefsResult.fold(
          (failure) => null,
          (cloudPrefs) async {
            final cloudProgressData = cloudPrefs[_statsKey];
            if (cloudProgressData != null &&
                cloudProgressData is String &&
                cloudProgressData.isNotEmpty) {
              final cloudStats = UserStatsModel.fromJson(
                jsonDecode(cloudProgressData),
              );
              finalStats = _mergeStats(stats, cloudStats);
            }
            final finalJsonStr = jsonEncode(
              UserStatsModel.fromEntity(finalStats).toJson(),
            );
            await _prefs.setString(_statsKey, finalJsonStr);

            final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
              ..[_statsKey] = finalJsonStr;
            final updateResult = await _authRepository.updateUserPrefs(cloudUpdate);
            updateResult.fold(
              (failure) => null,
              (_) {
                synced = true;
              },
            );
          },
        );
      } else {
        synced = true;
      }

      await _prefs.setBool('is_stats_synced', synced);
      return Right(finalStats);
    } catch (e) {
      await _prefs.setBool('is_stats_synced', false);
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> syncPendingStats() async {
    try {
      final isSynced = _prefs.getBool('is_stats_synced') ?? true;
      if (isSynced) {
        return const Right(null);
      }

      final loggedInResult = await _authRepository.isLoggedIn();
      final isLoggedIn = loggedInResult.getOrElse((_) => false);
      if (!isLoggedIn) {
        await _prefs.setBool('is_stats_synced', true);
        return const Right(null);
      }

      final storedLocal = _prefs.getString(_statsKey);
      if (storedLocal == null) {
        await _prefs.setBool('is_stats_synced', true);
        return const Right(null);
      }

      final localStats = UserStatsModel.fromJson(jsonDecode(storedLocal));

      final prefsResult = await _authRepository.getUserPrefs();
      return await prefsResult.fold(
        Left.new,
        (cloudPrefs) async {
          UserStatsEntity finalStats = localStats;
          final cloudProgressData = cloudPrefs[_statsKey];
          if (cloudProgressData != null &&
              cloudProgressData is String &&
              cloudProgressData.isNotEmpty) {
            final cloudStats = UserStatsModel.fromJson(
              jsonDecode(cloudProgressData),
            );
            finalStats = _mergeStats(localStats, cloudStats);
          }

          final finalJsonStr = jsonEncode(
            UserStatsModel.fromEntity(finalStats).toJson(),
          );
          await _prefs.setString(_statsKey, finalJsonStr);

          final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
            ..[_statsKey] = finalJsonStr;
          final updateResult = await _authRepository.updateUserPrefs(cloudUpdate);
          return await updateResult.fold(
            Left.new,
            (_) async {
              await _prefs.setBool('is_stats_synced', true);
              return const Right(null);
            },
          );
        },
      );
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
