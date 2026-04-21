import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
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
      return Left(ServerFailure(message: originalMessage, code: originalCode));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCategoryById(id);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createCategory(CategoryEntity category) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.createCategory(CategoryModel.fromEntity(category));
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateCategory(CategoryModel.fromEntity(category));
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
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
        return Left(ServerFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
