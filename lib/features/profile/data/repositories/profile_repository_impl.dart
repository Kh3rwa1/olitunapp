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

  CacheFailure _failure(Object e, [StackTrace? st]) {
    final failure = CacheFailure(message: e.toString());
    CrashReporting.recordFailure(failure, st);
    return failure;
  }

  UserStatsEntity get _empty => const UserStatsEntity(practicedLetters: {}, completedLessons: {}, quizHistory: {}, categoryMastery: {}, totalLearningMinutes: 0, lastActiveDate: '', currentStreak: 0, totalStars: 0);
  bool _isEmpty(UserStatsEntity s) => s.practicedLetters.isEmpty && s.completedLessons.isEmpty && s.quizHistory.isEmpty && s.categoryMastery.isEmpty && s.completedMissionsDates.isEmpty && s.practiceDates.isEmpty && s.totalLearningMinutes == 0 && s.lastActiveDate.isEmpty && s.currentStreak == 0 && s.totalStars == 0;
  String _encode(UserStatsEntity s) => jsonEncode(UserStatsModel.fromEntity(s).toJson());
  UserStatsEntity _decode(String s) => UserStatsModel.fromJson(jsonDecode(s));

  UserStatsEntity _merge(UserStatsEntity a, UserStatsEntity b) {
    if (a.syncEpoch != b.syncEpoch) return a.syncEpoch > b.syncEpoch ? a : b;
    final quizzes = Map<String, QuizResultEntity>.from(a.quizHistory);
    b.quizHistory.forEach((key, value) {
      final old = quizzes[key];
      if (old == null || value.score > old.score) quizzes[key] = value;
    });
    if (quizzes.length > 50) {
      final keys = quizzes.keys.toList()..sort((x, y) => quizzes[y]!.completedAt.compareTo(quizzes[x]!.completedAt));
      final keep = keys.take(50).toSet();
      quizzes.removeWhere((key, _) => !keep.contains(key));
    }
    final mastery = Map<String, int>.from(a.categoryMastery);
    b.categoryMastery.forEach((key, value) {
      if (value > (mastery[key] ?? 0)) mastery[key] = value;
    });
    final lastDate = a.lastActiveDate.compareTo(b.lastActiveDate) >= 0 ? a.lastActiveDate : b.lastActiveDate;
    return UserStatsEntity(
      practicedLetters: {...a.practicedLetters, ...b.practicedLetters},
      completedLessons: {...a.completedLessons, ...b.completedLessons},
      quizHistory: quizzes,
      categoryMastery: mastery,
      completedMissionsDates: {...a.completedMissionsDates, ...b.completedMissionsDates},
      practiceDates: {...a.practiceDates, ...b.practiceDates},
      totalLearningMinutes: a.totalLearningMinutes > b.totalLearningMinutes ? a.totalLearningMinutes : b.totalLearningMinutes,
      lastActiveDate: lastDate,
      currentStreak: a.currentStreak > b.currentStreak ? a.currentStreak : b.currentStreak,
      totalStars: a.totalStars > b.totalStars ? a.totalStars : b.totalStars,
      syncEpoch: a.syncEpoch,
    );
  }

  Future<bool> _loggedIn() async => (await _authRepository.isLoggedIn()).getOrElse((_) => false);
  Future<void> _setSynced(bool value) => _prefs.setBool('is_stats_synced', value);

  @override
  Future<Either<Failure, UserStatsEntity>> getUserStats() async {
    try {
      final rawLocal = _prefs.getString(_statsKey);
      final local = rawLocal == null ? null : _decode(rawLocal);
      if (!await _loggedIn()) {
        await _setSynced(true);
        return Right(local ?? _empty);
      }
      final cloudResult = await _authRepository.getUserPrefs();
      return await cloudResult.fold((_) async => Right(local ?? _empty), (cloudPrefs) async {
        final rawCloud = cloudPrefs[_statsKey];
        final cloud = rawCloud is String && rawCloud.isNotEmpty ? _decode(rawCloud) : null;
        final resolved = local == null ? (cloud ?? _empty) : cloud == null ? local : _merge(local, cloud);
        await _prefs.setString(_statsKey, _encode(resolved));
        if (local != null || cloud == null) {
          final result = await _authRepository.updateUserPrefs({...cloudPrefs, _statsKey: _encode(resolved)});
          await result.fold((_) => _setSynced(false), (_) => _setSynced(true));
        } else {
          await _setSynced(true);
        }
        return Right(resolved);
      });
    } catch (e, st) {
      return Left(_failure(e, st));
    }
  }

  @override
  Future<Either<Failure, UserStatsEntity>> updateUserStats(UserStatsEntity stats) async {
    try {
      final rawLocal = _prefs.getString(_statsKey);
      final previous = rawLocal == null ? null : _decode(rawLocal);
      var submitted = stats;
      if (_isEmpty(stats) && previous != null && !_isEmpty(previous) && stats.syncEpoch <= previous.syncEpoch) {
        submitted = stats.copyWith(syncEpoch: previous.syncEpoch + 1);
      }
      await _prefs.setString(_statsKey, _encode(submitted));
      if (!await _loggedIn()) {
        await _setSynced(true);
        return Right(submitted);
      }
      var finalStats = submitted;
      var synced = false;
      final cloudResult = await _authRepository.getUserPrefs();
      await cloudResult.fold((_) {}, (cloudPrefs) async {
        final rawCloud = cloudPrefs[_statsKey];
        if (rawCloud is String && rawCloud.isNotEmpty) {
          final cloud = _decode(rawCloud);
          if (_isEmpty(submitted) && !_isEmpty(cloud) && submitted.syncEpoch <= cloud.syncEpoch) {
            submitted = submitted.copyWith(syncEpoch: cloud.syncEpoch + 1);
          }
          finalStats = _merge(submitted, cloud);
        }
        await _prefs.setString(_statsKey, _encode(finalStats));
        final result = await _authRepository.updateUserPrefs({...cloudPrefs, _statsKey: _encode(finalStats)});
        result.fold((_) {}, (_) => synced = true);
      });
      await _setSynced(synced);
      return Right(finalStats);
    } catch (e, st) {
      await _setSynced(false);
      return Left(_failure(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> syncPendingStats() async {
    try {
      if (_prefs.getBool('is_stats_synced') ?? true) return const Right(null);
      if (!await _loggedIn()) { await _setSynced(true); return const Right(null); }
      final raw = _prefs.getString(_statsKey);
      if (raw == null) { await _setSynced(true); return const Right(null); }
      final local = _decode(raw);
      final cloudResult = await _authRepository.getUserPrefs();
      return await cloudResult.fold(Left.new, (cloudPrefs) async {
        final rawCloud = cloudPrefs[_statsKey];
        final resolved = rawCloud is String && rawCloud.isNotEmpty ? _merge(local, _decode(rawCloud)) : local;
        await _prefs.setString(_statsKey, _encode(resolved));
        final result = await _authRepository.updateUserPrefs({...cloudPrefs, _statsKey: _encode(resolved)});
        return result.fold(Left.new, (_) async { await _setSynced(true); return const Right(null); });
      });
    } catch (e, st) { return Left(_failure(e, st)); }
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String name) async {
    try {
      await _prefs.setString('user_name', name);
      final status = await _authRepository.isLoggedIn();
      await status.fold((f) async => CrashReporting.recordFailure(f), (loggedIn) async {
        if (loggedIn) (await _authRepository.updateDisplayName(name)).fold(CrashReporting.recordFailure, (_) {});
      });
      return const Right(null);
    } catch (e, st) { return Left(_failure(e, st)); }
  }

  @override
  Future<Either<Failure, void>> updateAvatar(String emoji, int colorIndex) async {
    await _prefs.setString('user_avatar_emoji', emoji);
    await _prefs.setInt('user_avatar_color', colorIndex);
    return const Right(null);
  }
}
