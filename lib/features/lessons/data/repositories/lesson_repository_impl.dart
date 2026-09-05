import 'dart:async';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
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

  /// In-flight request deduplication map to prevent redundant concurrent fetches.
  final Map<String, Future<List<LessonModel>>> _inFlightRefreshes = {};

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

  /// Validates remote lesson models before committing them to persistent cache.
  List<LessonModel> _validateRemoteLessons(List<LessonModel> lessons) {
    return lessons.where((m) {
      final isValid =
          m.id.trim().isNotEmpty &&
          m.categoryId.trim().isNotEmpty &&
          (m.titleLatin.trim().isNotEmpty || m.titleOlChiki.trim().isNotEmpty);
      if (!isValid) {
        AppLogger.warning(
          'LessonRepositoryImpl: Discarded invalid remote lesson: ${m.id}',
        );
      }
      return isValid;
    }).toList();
  }

  /// Triggers an in-flight deduplicated background revalidation.
  /// If a fetch for [categoryId] is already in progress, returns the existing Future.
  Future<List<LessonModel>> _revalidateLessons({String? categoryId}) {
    final key = categoryId ?? '__all__';
    if (_inFlightRefreshes.containsKey(key)) {
      return _inFlightRefreshes[key]!;
    }

    final future = () async {
      try {
        final isConnected = await networkInfo.isConnected;
        if (!isConnected) return <LessonModel>[];

        final List<LessonModel> remoteLessons;
        if (categoryId == null) {
          remoteLessons = await remoteDataSource.getLessons();
        } else {
          remoteLessons = await remoteDataSource.getLessonsByCategory(
            categoryId,
          );
        }

        final validLessons = _validateRemoteLessons(remoteLessons);
        if (validLessons.isNotEmpty) {
          try {
            await localDataSource.cacheLessons(validLessons);
          } catch (cacheErr, cacheSt) {
            AppLogger.warning(
              'LessonRepositoryImpl: Failed to write validated cache: $cacheErr',
            );
            CrashReporting.recordFailure(
              CacheFailure(message: 'Atomic cache write failed: $cacheErr'),
              cacheSt,
            );
          }
        }
        return validLessons;
      } catch (e, st) {
        if (e is ServerException) {
          _recordedServerFailure(e, st);
        }
        return <LessonModel>[];
      } finally {
        _inFlightRefreshes.remove(key);
      }
    }();

    _inFlightRefreshes[key] = future;
    return future;
  }

  @override
  Future<Either<Failure, List<LessonEntity>>> getLessons() async {
    // 1. True Cache-First: Check local persistent storage immediately
    try {
      final cached = await localDataSource.getLessons();
      if (cached.isNotEmpty) {
        // Trigger background revalidation opportunistically without blocking the user
        unawaited(_revalidateLessons());
        return Right(cached.map((m) => m.toEntity()).toList());
      }
    } catch (_) {
      // Local cache empty or unreadable; proceed to remote fetch with seed fallback
    }

    // 2. Cache was empty -> fetch from remote
    if (await networkInfo.isConnected) {
      try {
        final remote = await _revalidateLessons();
        if (remote.isNotEmpty) {
          return Right(remote.map((m) => m.toEntity()).toList());
        }
      } catch (e, st) {
        if (e is ServerException) {
          _recordedServerFailure(e, st);
        }
      }
    }

    // 3. Fallback to bundled static seed lessons so offline experience never breaks
    return const Right(_staticSeedLessons);
  }

  @override
  Future<Either<Failure, List<LessonEntity>>> getLessonsByCategory(
    String categoryId,
  ) async {
    // 1. True Cache-First: Read category lessons from local storage immediately
    try {
      final cached = await localDataSource.getLessons();
      final filtered = cached.where((lesson) {
        if (categoryId == 'cat_vocab' ||
            categoryId == 'cat_words' ||
            categoryId == 'seed_words') {
          return lesson.categoryId == 'cat_vocab' ||
              lesson.categoryId == 'cat_words' ||
              lesson.categoryId == 'seed_words';
        }
        if (categoryId == 'cat_sentences' || categoryId == 'seed_sentences') {
          return lesson.categoryId == 'cat_sentences' ||
              lesson.categoryId == 'seed_sentences';
        }
        return lesson.categoryId == categoryId;
      }).toList();

      if (filtered.isNotEmpty) {
        // Trigger in-flight deduplicated background revalidation
        unawaited(_revalidateLessons(categoryId: categoryId));
        return Right(filtered.map((m) => m.toEntity()).toList());
      }
    } on CacheException {
      // Proceed to remote fetch
    } catch (_) {
      // Cache read failed: surface an offline network state, otherwise
      // fall through to the remote fetch / seed fallback below.
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }
    }

    // 2. Cache was empty for category -> fetch from remote
    if (await networkInfo.isConnected) {
      try {
        final remote = await _revalidateLessons(categoryId: categoryId);
        if (remote.isNotEmpty) {
          return Right(remote.map((m) => m.toEntity()).toList());
        }
      } catch (e, st) {
        if (e is ServerException) {
          _recordedServerFailure(e, st);
        }
      }
    }

    // 3. Fallback to static seed lessons for the category
    return Right(
      _staticSeedLessons.where((lesson) {
        if (categoryId == 'cat_vocab' ||
            categoryId == 'cat_words' ||
            categoryId == 'seed_words') {
          return lesson.categoryId == 'cat_vocab';
        }
        if (categoryId == 'cat_sentences' || categoryId == 'seed_sentences') {
          return lesson.categoryId == 'cat_sentences';
        }
        return lesson.categoryId == categoryId;
      }).toList(),
    );
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
    // Vocabulary / Words
    LessonEntity(
      id: 'lesson_words_basics',
      categoryId: 'cat_vocab',
      titleOlChiki: 'ᱢᱩᱞ ᱥᱟᱹᱵᱟᱹᱫᱽ',
      titleLatin: 'Basic Words',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱡᱚᱦᱟᱨ',
          textLatin: 'Johar – Hello / Greetings',
        ),
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
          textLatin: 'Sarhaw – Thank you',
        ),
      ],
    ),
    // Sentences
    LessonEntity(
      id: 'lesson_sentences_basics',
      categoryId: 'cat_sentences',
      titleOlChiki: 'ᱨᱚᱲ ᱛᱮᱭᱟᱨ ᱢᱩᱞ',
      titleLatin: 'Simple Sentences',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱟᱢ ᱪᱮᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
          textLatin: 'Am celeka menama? – How are you?',
        ),
      ],
    ),
    // Greetings & Stories
    LessonEntity(
      id: 'lesson_greetings_basics',
      categoryId: 'cat_greetings',
      titleOlChiki: 'ᱡᱚᱦᱟᱨ ᱢᱩᱞ',
      titleLatin: 'Greetings & Phrases',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ',
          textLatin: 'Sagun Setag – Good morning',
        ),
      ],
    ),
  ];

  @override
  Future<Either<Failure, LessonEntity>> getLessonById(String id) async {
    // Check local cache first
    try {
      final cached = await localDataSource.getLessons();
      final lesson = cached.firstWhere((l) => l.id == id);
      if (!lesson.isLocked && lesson.blocks.isNotEmpty) {
        return Right(lesson.toEntity());
      }
    } catch (_) {
      // Cache miss; proceed to authorized remote retrieval
    }

    // Try remote if online
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAuthorizedLesson(id);
        if (result.isLocked) {
          // Do not cache locked lesson content as playable
          return Right(result.toEntity());
        }
        try {
          await localDataSource.cacheLessons([result]);
        } catch (cacheErr, cacheSt) {
          AppLogger.warning(
            'LessonRepositoryImpl: Failed to cache lesson by id: $cacheErr',
          );
          CrashReporting.recordFailure(
            CacheFailure(message: 'Failed to cache lesson: $cacheErr'),
            cacheSt,
          );
        }
        return Right(result.toEntity());
      } catch (e, st) {
        if (e is ServerException) {
          if (e.code == 403) {
            return const Left(
              AuthFailure(message: 'Access denied to protected lesson.'),
            );
          }
          _recordedServerFailure(e, st);
        }
      }
    }

    // Seed fallback
    try {
      final seed = _staticSeedLessons.firstWhere((l) => l.id == id);
      return Right(seed);
    } catch (_) {
      // Not in the seed either — surface the miss as a cache failure.
      return const Left(CacheFailure(message: 'Lesson not found in cache'));
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
