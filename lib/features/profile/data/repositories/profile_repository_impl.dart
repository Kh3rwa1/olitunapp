import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/observability/crash_reporting.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_stats_model.dart';
import 'progress_merge_crdt.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AuthRepository _authRepository;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const _cloudStatsKey = 'user_progress_data';
  static const _legacyStatsKey = 'user_progress_data';

  ProfileRepositoryImpl(
    this._authRepository,
    this._prefs, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  CacheFailure _recordedCacheFailure(Object e, [StackTrace? st]) {
    final f = CacheFailure(message: e.toString());
    CrashReporting.recordFailure(f, st);
    return f;
  }

  Future<String> _resolveStatsKey() async {
    try {
      final userResult = await _authRepository.getCurrentUser();
      final user = userResult.fold((_) => null, (u) => u);
      if (user != null && user.id.isNotEmpty) {
        return 'user_stats_${user.id}';
      }
    } catch (_) {}
    return 'user_stats_guest';
  }

  Future<String> _resolveSyncKey() async {
    try {
      final userResult = await _authRepository.getCurrentUser();
      final user = userResult.fold((_) => null, (u) => u);
      if (user != null && user.id.isNotEmpty) {
        return 'is_stats_synced_${user.id}';
      }
    } catch (_) {}
    return 'is_stats_synced_guest';
  }

  UserStatsEntity? _readLocalStats(String statsKey) {
    var stored = _prefs.getString(statsKey);
    if (stored == null && statsKey == 'user_stats_guest') {
      stored = _prefs.getString(_legacyStatsKey);
    }
    if (stored == null || stored.isEmpty) return null;
    return UserStatsModel.fromJson(jsonDecode(stored));
  }

  Future<void> _writeLocalStats(String statsKey, UserStatsEntity stats) async {
    final jsonStr = jsonEncode(UserStatsModel.fromEntity(stats).toJson());
    await _prefs.setString(statsKey, jsonStr);
    if (statsKey == 'user_stats_guest') {
      await _prefs.setString(_legacyStatsKey, jsonStr);
    }
  }

  Future<void> _setStatsSynced(String syncKey, bool synced) async {
    await _prefs.setBool(syncKey, synced);
    await _prefs.setBool('is_stats_synced', synced);
  }

  bool _getStatsSynced(String syncKey) {
    return _prefs.getBool(syncKey) ?? _prefs.getBool('is_stats_synced') ?? true;
  }

  UserStatsEntity _emptyStats({int syncEpoch = 0}) {
    return UserStatsEntity(
      practicedLetters: const {},
      completedLessons: const {},
      quizHistory: const {},
      categoryMastery: const {},
      totalLearningMinutes: 0,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 0,
      syncEpoch: syncEpoch,
    );
  }

  UserStatsEntity _mergeStats(UserStatsEntity a, UserStatsEntity b) {
    return mergeProgressStats(a, b, asOf: _clock());
  }

  @override
  Future<Either<Failure, UserStatsEntity>> getUserStats() async {
    try {
      final statsKey = await _resolveStatsKey();
      final syncKey = await _resolveSyncKey();
      final localStats = _readLocalStats(statsKey);

      final loggedInResult = await _authRepository.isLoggedIn();
      final isLoggedIn = loggedInResult.getOrElse((_) => false);

      if (isLoggedIn) {
        final prefsResult = await _authRepository.getUserPrefs();
        return await prefsResult.fold(
          (failure) => Right(localStats ?? _emptyStats()),
          (cloudPrefs) async {
            final cloudProgressData = cloudPrefs[_cloudStatsKey];
            if (cloudProgressData != null &&
                cloudProgressData is String &&
                cloudProgressData.isNotEmpty) {
              final cloudStats = UserStatsModel.fromJson(
                jsonDecode(cloudProgressData),
              );

              if (localStats != null) {
                final resolvedStats = _mergeStats(localStats, cloudStats);
                await _writeLocalStats(statsKey, resolvedStats);
                final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
                  ..[_cloudStatsKey] = jsonEncode(
                    UserStatsModel.fromEntity(resolvedStats).toJson(),
                  );
                final cloudResult = await _authRepository.updateUserPrefs(
                  cloudUpdate,
                );
                await cloudResult.fold(
                  (failure) async => await _setStatsSynced(syncKey, false),
                  (_) async => await _setStatsSynced(syncKey, true),
                );
                return Right(resolvedStats);
              } else {
                await _writeLocalStats(statsKey, cloudStats);
                await _setStatsSynced(syncKey, true);
                return Right(cloudStats);
              }
            } else {
              final currentLocal = localStats;
              if (currentLocal != null) {
                final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
                  ..[_cloudStatsKey] = jsonEncode(
                    UserStatsModel.fromEntity(currentLocal).toJson(),
                  );
                final cloudResult = await _authRepository.updateUserPrefs(
                  cloudUpdate,
                );
                await cloudResult.fold(
                  (failure) async => await _setStatsSynced(syncKey, false),
                  (_) async => await _setStatsSynced(syncKey, true),
                );
                return Right(currentLocal);
              }
            }

            await _setStatsSynced(syncKey, true);
            return Right(_emptyStats());
          },
        );
      }

      await _setStatsSynced(syncKey, true);
      return Right(localStats ?? _emptyStats());
    } catch (e) {
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserStatsEntity>> updateUserStats(
    UserStatsEntity stats,
  ) async {
    try {
      final statsKey = await _resolveStatsKey();
      final syncKey = await _resolveSyncKey();

      await _writeLocalStats(statsKey, stats);

      final loggedInResult = await _authRepository.isLoggedIn();
      final isLoggedIn = loggedInResult.getOrElse((_) => false);
      UserStatsEntity finalStats = stats;
      bool synced = false;

      if (isLoggedIn) {
        final prefsResult = await _authRepository.getUserPrefs();
        await prefsResult.fold((failure) => null, (cloudPrefs) async {
          final cloudProgressData = cloudPrefs[_cloudStatsKey];
          if (cloudProgressData != null &&
              cloudProgressData is String &&
              cloudProgressData.isNotEmpty) {
            final cloudStats = UserStatsModel.fromJson(
              jsonDecode(cloudProgressData),
            );
            finalStats = _mergeStats(stats, cloudStats);
          } else {
            finalStats = _mergeStats(
              stats,
              _emptyStats(syncEpoch: stats.syncEpoch),
            );
          }
          await _writeLocalStats(statsKey, finalStats);

          final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
            ..[_cloudStatsKey] = jsonEncode(
              UserStatsModel.fromEntity(finalStats).toJson(),
            );
          final updateResult = await _authRepository.updateUserPrefs(
            cloudUpdate,
          );
          updateResult.fold((failure) => null, (_) {
            synced = true;
          });
        });
      } else {
        finalStats = _mergeStats(
          stats,
          _emptyStats(syncEpoch: stats.syncEpoch),
        );
        await _writeLocalStats(statsKey, finalStats);
        synced = true;
      }

      await _setStatsSynced(syncKey, synced);
      return Right(finalStats);
    } catch (e) {
      final syncKey = await _resolveSyncKey();
      await _setStatsSynced(syncKey, false);
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserStatsEntity>> resetUserStats() async {
    try {
      final statsKey = await _resolveStatsKey();
      final syncKey = await _resolveSyncKey();
      final localStats = _readLocalStats(statsKey);
      var nextEpoch = (localStats?.syncEpoch ?? 0) + 1;

      final loggedInResult = await _authRepository.isLoggedIn();
      final isLoggedIn = loggedInResult.getOrElse((_) => false);
      Map<String, dynamic>? cloudPrefs;

      if (isLoggedIn) {
        final prefsResult = await _authRepository.getUserPrefs();
        prefsResult.fold((failure) => null, (prefs) {
          cloudPrefs = prefs;
          final cloudProgressData = prefs[_cloudStatsKey];
          if (cloudProgressData is String && cloudProgressData.isNotEmpty) {
            final cloudStats = UserStatsModel.fromJson(
              jsonDecode(cloudProgressData),
            );
            if (cloudStats.syncEpoch >= nextEpoch) {
              nextEpoch = cloudStats.syncEpoch + 1;
            }
          }
        });
      }

      final resetStats = _emptyStats(syncEpoch: nextEpoch);
      await _writeLocalStats(statsKey, resetStats);

      if (!isLoggedIn) {
        await _setStatsSynced(syncKey, true);
        return Right(resetStats);
      }

      if (cloudPrefs == null) {
        await _setStatsSynced(syncKey, false);
        return Right(resetStats);
      }

      final cloudUpdate = Map<String, dynamic>.from(cloudPrefs!)
        ..[_cloudStatsKey] = jsonEncode(
          UserStatsModel.fromEntity(resetStats).toJson(),
        );
      final updateResult = await _authRepository.updateUserPrefs(cloudUpdate);
      await updateResult.fold(
        (failure) async => await _setStatsSynced(syncKey, false),
        (_) async => await _setStatsSynced(syncKey, true),
      );
      return Right(resetStats);
    } catch (e) {
      final syncKey = await _resolveSyncKey();
      await _setStatsSynced(syncKey, false);
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> syncPendingStats() async {
    try {
      final statsKey = await _resolveStatsKey();
      final syncKey = await _resolveSyncKey();
      final isSynced = _getStatsSynced(syncKey);
      if (isSynced) {
        return const Right(null);
      }

      final loggedInResult = await _authRepository.isLoggedIn();
      final isLoggedIn = loggedInResult.getOrElse((_) => false);
      if (!isLoggedIn) {
        await _setStatsSynced(syncKey, true);
        return const Right(null);
      }

      final localStats = _readLocalStats(statsKey);
      if (localStats == null) {
        await _setStatsSynced(syncKey, true);
        return const Right(null);
      }

      final prefsResult = await _authRepository.getUserPrefs();
      return await prefsResult.fold(Left.new, (cloudPrefs) async {
        UserStatsEntity finalStats = localStats;
        final cloudProgressData = cloudPrefs[_cloudStatsKey];
        if (cloudProgressData != null &&
            cloudProgressData is String &&
            cloudProgressData.isNotEmpty) {
          final cloudStats = UserStatsModel.fromJson(
            jsonDecode(cloudProgressData),
          );
          finalStats = _mergeStats(localStats, cloudStats);
        }

        await _writeLocalStats(statsKey, finalStats);

        final cloudUpdate = Map<String, dynamic>.from(cloudPrefs)
          ..[_cloudStatsKey] = jsonEncode(
            UserStatsModel.fromEntity(finalStats).toJson(),
          );
        final updateResult = await _authRepository.updateUserPrefs(cloudUpdate);
        return await updateResult.fold(Left.new, (_) async {
          await _setStatsSynced(syncKey, true);
          return const Right(null);
        });
      });
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
