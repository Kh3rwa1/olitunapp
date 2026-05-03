import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/observability/crash_reporting.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_stats_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AuthRepository _authRepository;
  static const _statsKey = 'user_progress_data';

  ProfileRepositoryImpl(this._authRepository);

  CacheFailure _recordedCacheFailure(Object e, [StackTrace? st]) {
    final f = CacheFailure(message: e.toString());
    CrashReporting.recordFailure(f, st);
    return f;
  }

  @override
  Future<Either<Failure, UserStatsEntity>> getUserStats() async {
    try {
      final stored = prefs.getString(_statsKey);
      if (stored != null) {
        final model = UserStatsModel.fromJson(jsonDecode(stored));
        return Right(model);
      }
      return const Right(UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
      ));
    } catch (e) {
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserStats(UserStatsEntity stats) async {
    try {
      final model = UserStatsModel.fromEntity(stats);
      await prefs.setString(_statsKey, jsonEncode(model.toJson()));
      
      // Sync with cloud if logged in
      final loggedIn = await _authRepository.isLoggedIn();
      await loggedIn.fold(
        (failure) => null,
        (isLoggedIn) async {
          if (isLoggedIn) {
            // This assumes the legacy updatePrefs exists or we use a new domain method
            // For now, we'll assume the AuthRepository handles it or we add it there.
          }
        },
      );
      
      return const Right(null);
    } catch (e) {
      return Left(_recordedCacheFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String name) async {
    await prefs.setString('user_name', name);
    final result = await _authRepository.isLoggedIn();
    return await result.fold(
      (failure) => Left(failure),
      (isLoggedIn) async {
        if (isLoggedIn) {
          // We need updateDisplayName in AuthRepository
          // For now, return Right as we updated local
          return const Right(null);
        }
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, void>> updateAvatar(String emoji, int colorIndex) async {
    await prefs.setString('user_avatar_emoji', emoji);
    await prefs.setInt('user_avatar_color', colorIndex);
    return const Right(null);
  }
}
