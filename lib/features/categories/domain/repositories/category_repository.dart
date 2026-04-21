import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id);
  Future<Either<Failure, void>> createCategory(CategoryEntity category);
  Future<Either<Failure, void>> updateCategory(CategoryEntity category);
  Future<Either<Failure, void>> deleteCategory(String id);
}
