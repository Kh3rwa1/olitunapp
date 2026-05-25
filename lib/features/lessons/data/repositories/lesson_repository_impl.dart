import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/observability/crash_reporting.dart';
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

  ServerFailure _recordedServerFailure(ServerException e, [StackTrace? st]) {
    final f = ServerFailure(message: e.message, code: e.code);
    CrashReporting.recordFailure(f, st);
    return f;
  }

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
  Future<Either<Failure, List<LessonEntity>>> getLessonsByCategory(
    String categoryId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLessons = await remoteDataSource.getLessonsByCategory(
          categoryId,
        );
        await localDataSource.cacheLessons(remoteLessons);
        return Right(remoteLessons.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return _getCachedLessonsByCategory(categoryId, e.message, e.code);
      }
    } else {
      return _getCachedLessonsByCategory(categoryId, 'No internet connection');
    }
  }

  static const _staticSeedLessons = [
    // Basics of Ol Chiki
    LessonEntity(
      id: 'lesson_alphabet_0',
      categoryId: 'cat_alphabets',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱢᱩᱞ',
      titleLatin: 'Basics of Ol Chiki',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
          textLatin: 'Ol Chiki is the writing system for the Santali language',
        ),
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱚ',
          textLatin: 'Letter "a" – the first letter of Ol Chiki',
        ),
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱛ',
          textLatin: 'Letter "at" – used in words like ᱛᱟᱞᱟ (below)',
        ),
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱚᱛ',
          textLatin: 'Practice: Combine ᱚ + ᱛ to form "at"',
        ),
      ],
    ),
    // Numbers 0-9
    LessonEntity(
      id: 'lesson_numbers_0_9',
      categoryId: 'cat_numbers',
      titleOlChiki: '᱐-᱙ ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers 0-9',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: '᱐',
          textLatin: '0 – Zero',
        ),
        LessonBlockEntity(type: 'text', textOlChiki: '᱑', textLatin: '1 – One'),
        LessonBlockEntity(type: 'text', textOlChiki: '᱒', textLatin: '2 – Two'),
      ],
    ),
  ];

  Future<Either<Failure, List<LessonEntity>>> _getCachedLessons(
    String originalMessage, [
    int? originalCode,
  ]) async {
    try {
      final cached = await localDataSource.getLessons();
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException {
      // Fallback to static seed lessons if both remote fetch fails and local cache is empty.
      return const Right(_staticSeedLessons);
    }
  }

  Future<Either<Failure, List<LessonEntity>>> _getCachedLessonsByCategory(
    String categoryId,
    String originalMessage, [
    int? originalCode,
  ]) async {
    try {
      final cached = await localDataSource.getLessons();
      return Right(
        cached
            .where((lesson) => lesson.categoryId == categoryId)
            .map((model) => model.toEntity())
            .toList(),
      );
    } on CacheException {
      // Fallback to static seed lessons for the specific category if cache is empty.
      return Right(
        _staticSeedLessons
            .where((lesson) => lesson.categoryId == categoryId)
            .toList(),
      );
    } catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, LessonEntity>> getLessonById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getLessonById(id);
        await localDataSource.cacheLessons([result]);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(_recordedServerFailure(e));
      }
    } else {
      try {
        final cached = await localDataSource.getLessons();
        final lesson = cached.firstWhere((l) => l.id == id);
        return Right(lesson.toEntity());
      } catch (_) {
        return const Left(NetworkFailure());
      }
    }
  }

  @override
  Future<Either<Failure, void>> createLesson(LessonEntity lesson) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.createLesson(LessonModel.fromEntity(lesson));
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_recordedServerFailure(e));
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
        return Left(_recordedServerFailure(e));
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
        return Left(_recordedServerFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
