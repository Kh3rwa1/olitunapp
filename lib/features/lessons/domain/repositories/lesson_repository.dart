import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/lesson_entity.dart';

abstract class LessonRepository {
  Future<Either<Failure, List<LessonEntity>>> getLessons();
  Future<Either<Failure, List<LessonEntity>>> getLessonsByCategory(
    String categoryId,
  );
  Future<Either<Failure, LessonEntity>> getLessonById(String id);
  Future<Either<Failure, void>> createLesson(LessonEntity lesson);
  Future<Either<Failure, void>> updateLesson(LessonEntity lesson);
  Future<Either<Failure, void>> deleteLesson(String id);
}
