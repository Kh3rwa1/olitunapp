import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_stats_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserStatsEntity>> getUserStats();
  Future<Either<Failure, UserStatsEntity>> updateUserStats(
    UserStatsEntity stats,
  );
  Future<Either<Failure, UserStatsEntity>> resetUserStats();
  Future<Either<Failure, void>> updateDisplayName(String name);

  /// Persists the selected Lottie avatar id (see [kProfileAvatars]) and the
  /// background palette index. Unknown ids resolve to the default avatar.
  Future<Either<Failure, void>> updateAvatar(String avatarId, int colorIndex);
  Future<Either<Failure, void>> syncPendingStats();
}
