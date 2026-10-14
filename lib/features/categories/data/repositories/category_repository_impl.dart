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

  static const List<CategoryEntity> _staticSeedCategories = [
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
      totalLessons: 4,
    ),
    CategoryEntity(
      id: 'cat_vocab',
      titleOlChiki: 'ᱥᱟᱹᱵᱟᱹᱫᱽ',
      titleLatin: 'Vocabulary',
      iconName: 'vocabulary',
      gradientPreset: 'rose',
      order: 2,
      totalLessons: 14,
    ),
    CategoryEntity(
      id: 'cat_sentences',
      titleOlChiki: 'ᱨᱚᱲ ᱛᱮᱭᱟᱨ',
      titleLatin: 'Sentences',
      iconName: 'sentences',
      gradientPreset: 'emerald',
      order: 3,
      totalLessons: 23,
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

  Future<Either<Failure, List<CategoryEntity>>> _getCachedCategories(
    String originalMessage, [
    int? originalCode,
  ]) async {
    try {
      final cached = await localDataSource.getCategories();
      if (cached.isNotEmpty) {
        return Right(cached.map((m) => m.toEntity()).toList());
      }
    } catch (_) {}
    return const Right(_staticSeedCategories);
  }

  @override
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCategoryById(id);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return _getCachedCategoryById(id, e);
      }
    } else {
      return _getCachedCategoryById(id);
    }
  }

  Future<Either<Failure, CategoryEntity>> _getCachedCategoryById(
    String id, [
    ServerException? e,
  ]) async {
    try {
      final categories = await localDataSource.getCategories();
      final match = categories.where((c) => c.id == id).firstOrNull;
      if (match != null) return Right(match.toEntity());
    } catch (_) {}
    final seed = _staticSeedCategories.where((c) => c.id == id).firstOrNull;
    if (seed != null) return Right(seed);
    if (e != null) return Left(_recordedServerFailure(e));
    return const Left(NetworkFailure());
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
