import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/account_scope.dart';
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
  Future<void> _operations = Future<void>.value();

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

  Future<Either<Failure, T>> _inScope<T>(
    Future<Either<Failure, T>> Function(AccountScope scope) operation,
  ) {
    // Capture before even waiting for earlier operations. Never re-resolve in
    // a catch handler, and never turn auth/network failure into guest identity.
    final scope = AccountScope.capture(_prefs);
    final pending = _operations.then(
      (_) => scope.run(() async {
        try {
          scope.check();
          final result = await operation(scope);
          scope.check();
          return result;
        } catch (e, st) {
          return Left<Failure, T>(_recordedCacheFailure(e, st));
        }
      }),
    );
    _operations = pending.then((_) {}, onError: (Object _) {});
    return pending;
  }

  UserStatsEntity? _readLocalStats(AccountScope scope) {
    scope.check();
    var stored = _prefs.getString(scope.statsKey);
    // Legacy unowned data belongs ONLY to the guest namespace. Never promote
    // it on login: it may contain progress from a previously signed-in account.
    if (stored == null && scope.isGuest) {
      stored = _prefs.getString(_legacyStatsKey);
    }
    if (stored == null || stored.isEmpty) return null;
    return UserStatsModel.fromJson(jsonDecode(stored));
  }

  Future<void> _writeLocalStats(
    AccountScope scope,
    UserStatsEntity stats,
  ) async {
    // Mark dirty before persisting data so a crash cannot leave new data clean.
    await _setStatsSynced(scope, scope.isGuest);
    scope.check();
    final jsonStr = jsonEncode(UserStatsModel.fromEntity(stats).toJson());
    if (!await _prefs.setString(scope.statsKey, jsonStr)) {
      throw StateError('Could not persist progress');
    }
    scope.check();
    if (scope.isGuest) {
      if (!await _prefs.setString(_legacyStatsKey, jsonStr)) {
        throw StateError('Could not persist guest progress');
      }
      scope.check();
    }
  }

  Future<void> _setStatsSynced(AccountScope scope, bool synced) async {
    scope.check();
    if (!await _prefs.setBool(scope.syncKey, synced)) {
      throw StateError('Could not persist progress sync status');
    }
    scope.check();
    // Compatibility mirror for the current UI only; never read as ownership
    // or as an account's authoritative pending flag.
    await _prefs.setBool('is_stats_synced', synced);
    scope.check();
  }

  UserStatsEntity _emptyStats({int syncEpoch = 0}) => UserStatsEntity(
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

  UserStatsEntity _mergeStats(UserStatsEntity a, UserStatsEntity b) =>
      mergeProgressStats(a, b, asOf: _clock());

  UserStatsEntity? _cloudStats(Map<String, dynamic> prefs) {
    final data = prefs[_cloudStatsKey];
    return data is String && data.isNotEmpty
        ? UserStatsModel.fromJson(jsonDecode(data))
        : null;
  }

  Future<Either<Failure, void>> _upload(
    AccountScope scope,
    Map<String, dynamic> cloudPrefs,
    UserStatsEntity stats,
  ) async {
    scope.check();
    final result = await _authRepository.updateUserPrefs(
      Map<String, dynamic>.from(cloudPrefs)
        ..[_cloudStatsKey] = jsonEncode(
          UserStatsModel.fromEntity(stats).toJson(),
        ),
    );
    scope.check();
    await _setStatsSynced(scope, result.isRight());
    return result;
  }

  @override
  Future<Either<Failure, UserStatsEntity>> getUserStats() =>
      _inScope((scope) async {
        final local = _readLocalStats(scope);
        if (scope.isGuest) {
          await _setStatsSynced(scope, true);
          return Right(local ?? _emptyStats());
        }
        final response = await _authRepository.getUserPrefs();
        scope.check();
        return response.fold(
          (failure) async {
            // Offline/transient failure preserves both owner and pending state.
            return Right<Failure, UserStatsEntity>(local ?? _emptyStats());
          },
          (cloudPrefs) async {
            final cloud = _cloudStats(cloudPrefs);
            final resolved = local == null
                ? cloud ?? _emptyStats()
                : cloud == null
                ? local
                : _mergeStats(local, cloud);
            if (local != null || cloud != null) {
              await _writeLocalStats(scope, resolved);
            }
            if (local != null) {
              await _upload(scope, cloudPrefs, resolved);
            } else {
              await _setStatsSynced(scope, true);
            }
            return Right<Failure, UserStatsEntity>(resolved);
          },
        );
      });

  @override
  Future<Either<Failure, UserStatsEntity>> updateUserStats(
    UserStatsEntity stats,
  ) => _inScope((scope) async {
    var resolved = _mergeStats(stats, _emptyStats(syncEpoch: stats.syncEpoch));
    await _writeLocalStats(scope, resolved);
    if (!scope.isGuest) {
      final response = await _authRepository.getUserPrefs();
      scope.check();
      await response.fold((_) async {}, (cloudPrefs) async {
        final cloud = _cloudStats(cloudPrefs);
        if (cloud != null) resolved = _mergeStats(resolved, cloud);
        await _writeLocalStats(scope, resolved);
        await _upload(scope, cloudPrefs, resolved);
      });
    }
    return Right(resolved);
  });

  @override
  Future<Either<Failure, UserStatsEntity>> resetUserStats() =>
      _inScope((scope) async {
        var epoch = (_readLocalStats(scope)?.syncEpoch ?? 0) + 1;
        Map<String, dynamic>? cloudPrefs;
        if (!scope.isGuest) {
          final response = await _authRepository.getUserPrefs();
          scope.check();
          response.fold((_) {}, (prefs) {
            cloudPrefs = prefs;
            final cloudEpoch = _cloudStats(prefs)?.syncEpoch ?? 0;
            if (cloudEpoch >= epoch) epoch = cloudEpoch + 1;
          });
        }
        final reset = _emptyStats(syncEpoch: epoch);
        await _writeLocalStats(scope, reset);
        if (cloudPrefs != null) await _upload(scope, cloudPrefs!, reset);
        return Right(reset);
      });

  @override
  Future<Either<Failure, void>> syncPendingStats() => _inScope((scope) async {
    if (scope.isGuest) return const Right(null);
    final local = _readLocalStats(scope);
    // Missing account flag with existing scoped data is conservatively dirty.
    // A legacy global flag from another account must not suppress this sync.
    if ((_prefs.getBool(scope.syncKey) ?? (local == null)) || local == null) {
      return const Right(null);
    }
    final response = await _authRepository.getUserPrefs();
    scope.check();
    return response.fold((failure) async => Left<Failure, void>(failure), (
      cloudPrefs,
    ) async {
      final cloud = _cloudStats(cloudPrefs);
      final resolved = cloud == null ? local : _mergeStats(local, cloud);
      await _writeLocalStats(scope, resolved);
      return _upload(scope, cloudPrefs, resolved);
    });
  });

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
