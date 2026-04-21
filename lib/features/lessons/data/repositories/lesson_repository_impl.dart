import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/lesson_local_datasource.dart';
import '../datasources/lesson_remote_datasource.dart';
import '../models/lesson_model.dart';

class LessonRepositoryImpl implements LessonRepository {
  final LessonRemoteDataSource remoteDataSource;
  final LessonLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  LessonRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<LessonEntity>>> getLessons() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLessons = await remoteDataSource.getLessons();
        await localDataSource.cacheLessons(remoteLessons);
        return Right(remoteLessons.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return _getCachedLessons(e.message, e.code);
      }
    } else {
      return _getCachedLessons('No internet connection');
    }
  }

  @override
  Future<Either<Failure, List<LessonEntity>>> getLessonsByCategory(String categoryId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLessons = await remoteDataSource.getLessonsByCategory(categoryId);
        // We only cache the "all lessons" for now, or we could implement category-specific caching
        return Right(remoteLessons.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      }
    } else {
      // Fallback to local filtering of all cached lessons
      try {
        final cached = await localDataSource.getLessons();
        return Right(cached
            .where((l) => l.categoryId == categoryId)
            .map((m) => m.toEntity())
            .toList());
      } catch (_) {
        return const Left(NetworkFailure());
      }
    }
  }

  Future<Either<Failure, List<LessonEntity>>> _getCachedLessons(
    String originalMessage, [
    int? originalCode,
  ]) async {
    try {
      final cached = await localDataSource.getLessons();
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException {
      return Left(ServerFailure(message: originalMessage, code: originalCode));
    }
  }

  @override
  Future<Either<Failure, LessonEntity>> getLessonById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getLessonById(id);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createLesson(LessonEntity lesson) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.createLesson(LessonModel.fromEntity(lesson));
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateLesson(LessonEntity lesson) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateLesson(LessonModel.fromEntity(lesson));
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteLesson(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteLesson(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
