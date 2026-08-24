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

<<<<<<< HEAD
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
  Future<List<LessonModel>> _revalidateLessons({String? categoryId}) {
    final key = categoryId == null ? 'all' : 'cat_$categoryId';

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
=======
  @override
  Future<Either<Failure, List<LessonEntity>>> getLessons() async {
    if (await networkInfo.isConnected) {
      final List<LessonModel> remoteLessons;
      try {
        remoteLessons = await remoteDataSource.getLessons();
>>>>>>> origin/hardening/release-candidate-10-of-10
      } catch (e, st) {
        if (e is ServerException) {
          _recordedServerFailure(e, st);
        }
        return <LessonModel>[];
      } finally {
        _inFlightRefreshes.remove(key);
      }
<<<<<<< HEAD
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
=======

      try {
        await localDataSource.cacheLessons(remoteLessons);
      } catch (cacheErr, cacheSt) {
        CrashReporting.recordFailure(
          CacheFailure(message: 'Failed to cache remote lessons: $cacheErr'),
          cacheSt,
        );
      }

      return Right(remoteLessons.map((m) => m.toEntity()).toList());
    } else {
      return _getCachedLessons('No internet connection');
>>>>>>> origin/hardening/release-candidate-10-of-10
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
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }
    }

    // 2. Cache was empty for category -> fetch from remote
    if (await networkInfo.isConnected) {
      final List<LessonModel> remoteLessons;
      try {
<<<<<<< HEAD
        final remote = await _revalidateLessons(categoryId: categoryId);
        if (remote.isNotEmpty) {
          return Right(remote.map((m) => m.toEntity()).toList());
        }
=======
        remoteLessons = await remoteDataSource.getLessonsByCategory(categoryId);
>>>>>>> origin/hardening/release-candidate-10-of-10
      } catch (e, st) {
        if (e is ServerException) {
          _recordedServerFailure(e, st);
        }
      }
<<<<<<< HEAD
=======

      try {
        await localDataSource.cacheLessons(remoteLessons);
      } catch (cacheErr, cacheSt) {
        CrashReporting.recordFailure(
          CacheFailure(message: 'Failed to cache category lessons: $cacheErr'),
          cacheSt,
        );
      }

      return Right(remoteLessons.map((m) => m.toEntity()).toList());
    } else {
      return _getCachedLessonsByCategory(categoryId, 'No internet connection');
>>>>>>> origin/hardening/release-candidate-10-of-10
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

<<<<<<< HEAD
  @override
  Future<Either<Failure, LessonEntity>> getLessonById(String id) async {
    // Check local cache first
=======
  Future<Either<Failure, List<LessonEntity>>> _getCachedLessons(
    String originalMessage,
  ) async {
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
    String originalMessage,
  ) async {
    try {
      final cached = await localDataSource.getLessons();
      return Right(
        cached
            .where((lesson) {
              if (categoryId == 'cat_vocab' ||
                  categoryId == 'cat_words' ||
                  categoryId == 'seed_words') {
                return lesson.categoryId == 'cat_vocab' ||
                    lesson.categoryId == 'cat_words' ||
                    lesson.categoryId == 'seed_words';
              }
              if (categoryId == 'cat_sentences' ||
                  categoryId == 'seed_sentences') {
                return lesson.categoryId == 'cat_sentences' ||
                    lesson.categoryId == 'seed_sentences';
              }
              return lesson.categoryId == categoryId;
            })
            .map((model) => model.toEntity())
            .toList(),
      );
    } on CacheException {
      // Fallback to static seed lessons for the specific category if cache is empty.
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
    } catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, LessonEntity>> getLessonById(String id) async {
    if (await networkInfo.isConnected) {
      final LessonModel result;
      try {
        result = await remoteDataSource.getLessonById(id);
      } catch (e, st) {
        if (e is ServerException) {
          _recordedServerFailure(e, st);
        }
        return _getCachedLessonById(id);
      }

      try {
        await localDataSource.cacheLessons([result]);
      } catch (cacheErr, cacheSt) {
        CrashReporting.recordFailure(
          CacheFailure(message: 'Failed to cache lesson by id: $cacheErr'),
          cacheSt,
        );
      }

      return Right(result.toEntity());
    } else {
      return _getCachedLessonById(id);
    }
  }

  Future<Either<Failure, LessonEntity>> _getCachedLessonById(String id) async {
>>>>>>> origin/hardening/release-candidate-10-of-10
    try {
      final cached = await localDataSource.getLessons();
      final lesson = cached.firstWhere((l) => l.id == id);
      return Right(lesson.toEntity());
    } catch (_) {
      // Try remote if online
      if (await networkInfo.isConnected) {
        try {
          final result = await remoteDataSource.getLessonById(id);
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
            _recordedServerFailure(e, st);
          }
        }
      }

      // Seed fallback
      try {
        final seed = _staticSeedLessons.firstWhere((l) => l.id == id);
        return Right(seed);
      } catch (_) {
        return const Left(CacheFailure(message: 'Lesson not found in cache'));
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
