import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_stats_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserStatsEntity>> getUserStats();
  Future<Either<Failure, void>> updateUserStats(UserStatsEntity stats);
  Future<Either<Failure, void>> updateDisplayName(String name);
  Future<Either<Failure, void>> updateAvatar(String emoji, int colorIndex);
}
