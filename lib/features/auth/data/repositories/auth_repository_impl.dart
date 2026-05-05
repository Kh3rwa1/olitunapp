import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/observability/crash_reporting.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  ServerFailure _serverFailure(ServerException e, [StackTrace? st]) {
    final f = ServerFailure(message: e.message, code: e.code);
    CrashReporting.recordFailure(f, st);
    return f;
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.signUpWithEmail(
          email: email,
          password: password,
          name: name,
        );
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.signInWithEmail(
          email: email,
          password: password,
        );
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signOut();
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final result = await remoteDataSource.getCurrentUser();
      return Right(result?.toEntity());
    } on ServerException catch (e) {
      return Left(_serverFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final result = await remoteDataSource.isLoggedIn();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendVerificationEmail() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendVerificationEmail();
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteAccount();
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String name) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateDisplayName(name);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> sendOtp(String email) async {
    if (await networkInfo.isConnected) {
      try {
        final userId = await remoteDataSource.sendOtp(email);
        return Right(userId);
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String userId,
    required String secret,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.verifyOtp(
          userId: userId,
          secret: secret,
        );
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signInWithGoogle();
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_serverFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
