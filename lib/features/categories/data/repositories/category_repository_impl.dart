import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/observability/crash_reporting.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final CategoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CategoryRepositoryImpl({
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
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteCategories = await remoteDataSource.getCategories();
        await localDataSource.cacheCategories(remoteCategories);
        return Right(remoteCategories.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return _getCachedCategories(e.message, e.code);
      }
    } else {
      return _getCachedCategories('No internet connection');
    }
  }

  Future<Either<Failure, List<CategoryEntity>>> _getCachedCategories(
    String originalMessage, [
    int? originalCode,
  ]) async {
    try {
      final cached = await localDataSource.getCategories();
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException {
      // Fallback to static seed categories if both remote fetch fails and local cache is empty.
      // This ensures guest/offline mode has active paths on the very first startup.
      const staticSeedCategories = [
        CategoryEntity(
          id: 'cat_alphabets',
          titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
          titleLatin: 'Alphabets',
          iconName: 'alphabet',
          gradientPreset: 'sky',
          totalLessons: 5,
        ),
        CategoryEntity(
          id: 'cat_numbers',
          titleOlChiki: 'ᱮᱞᱠᱷᱟ',
          titleLatin: 'Numbers',
          iconName: 'numbers',
          gradientPreset: 'peach',
          order: 1,
          totalLessons: 2,
        ),
        CategoryEntity(
          id: 'cat_vocab',
          titleOlChiki: 'ᱥᱟᱹᱵᱟᱹᱫᱽ',
          titleLatin: 'Vocabulary',
          iconName: 'vocabulary',
          gradientPreset: 'rose',
          order: 2,
          totalLessons: 5,
        ),
        CategoryEntity(
          id: 'cat_sentences',
          titleOlChiki: 'ᱨᱚᱲ ᱛᱮᱭᱟᱨ',
          titleLatin: 'Sentences',
          iconName: 'sentences',
          gradientPreset: 'emerald',
          order: 3,
          totalLessons: 1,
        ),
        CategoryEntity(
          id: 'cat_greetings',
          titleOlChiki: 'ᱡᱚᱦᱟᱨ ᱜᱮ',
          titleLatin: 'Greetings',
          iconName: 'greetings',
          gradientPreset: 'indigo',
          order: 4,
          totalLessons: 1,
        ),
      ];
      return const Right(staticSeedCategories);
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCategoryById(id);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(_recordedServerFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createCategory(CategoryEntity category) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.createCategory(
          CategoryModel.fromEntity(category),
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_recordedServerFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateCategory(
          CategoryModel.fromEntity(category),
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_recordedServerFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCategory(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(_recordedServerFailure(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
