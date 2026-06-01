import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/providers/providers.dart';
import '../../lessons/domain/entities/lesson_entity.dart';
import '../domain/lesson_quiz_generator.dart';

class QuizRepository {
  final Ref _ref;

  QuizRepository(this._ref);

  Future<Either<Failure, QuizModel>> getQuiz(String quizId) async {
    return quizFromState(quizId, _ref.read(quizzesByIdProvider));
  }

  Either<Failure, QuizModel> quizFromState(
    String quizId,
    AsyncValue<Map<String, QuizModel>> quizzesMapAsync,
  ) {
    return quizzesMapAsync.when(
      loading: () =>
          const Left(CacheFailure(message: 'Quizzes are still loading.')),
      error: (error, _) => Left(_failureFromQuizLoad(error)),
      data: (quizzesMap) {
        final quiz = quizzesMap[quizId];
        if (quiz != null) return Right(quiz);

        return Left(
          ServerFailure(message: 'Quiz "$quizId" was not found.', code: 404),
        );
      },
    );
  }

  Failure _failureFromQuizLoad(Object error) {
    if (error is AppwriteException) {
      if (error.code == 0 || error.type == 'network_failure') {
        return const NetworkFailure();
      }

      return ServerFailure(
        message: error.message ?? 'Failed to load quiz.',
        code: error.code,
      );
    }

    return ServerFailure(message: error.toString());
  }
}

final quizRepositoryProvider = Provider(QuizRepository.new);

final dynamicLessonQuizProvider = Provider.family<QuizModel, LessonEntity>((
  ref,
  lesson,
) {
  return LessonQuizGenerator.generate(lesson);
});

final quizResultProvider =
    Provider.family<AsyncValue<Either<Failure, QuizModel>>, String>((
      ref,
      quizId,
    ) {
      if (quizId.startsWith('dynamic_quiz_')) {
        final lessonId = quizId.substring('dynamic_quiz_'.length);
        final lessonsAsync = ref.watch(learnerLessonsProvider);

        if (lessonsAsync.isLoading) {
          return const AsyncValue.loading();
        }

        final lessons = lessonsAsync.valueOrNull ?? [];
        final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;

        if (lesson == null) {
          return const AsyncValue.data(
            Left(ServerFailure(message: 'Lesson not found.')),
          );
        }

        final dynamicQuiz = LessonQuizGenerator.generate(lesson);
        return AsyncValue.data(Right(dynamicQuiz));
      }

      final repo = ref.watch(quizRepositoryProvider);
      final quizzesMapAsync = ref.watch(quizzesByIdProvider);

      if (quizzesMapAsync.isLoading) {
        return const AsyncValue.loading();
      }

      return AsyncValue.data(repo.quizFromState(quizId, quizzesMapAsync));
    });
