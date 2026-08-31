import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/providers/providers.dart';
import '../../lessons/domain/entities/lesson_entity.dart';
import '../domain/lesson_quiz_generator.dart';
import '../domain/listening_quiz_generator.dart';

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

/// Phase 7: client-side listening quiz for a lesson (audio-bearing blocks
/// only). Renders nothing when the lesson has no playable audio.
final listeningLessonQuizProvider = Provider.family<QuizModel, LessonEntity>((
  ref,
  lesson,
) {
  return ListeningQuizGenerator.generate(lesson);
});

/// True when a listening quiz can be generated for [lessonId] — used to
/// decide whether the lesson flow should offer a listening CTA at all.
final lessonHasListeningQuizProvider = Provider.family<bool, String>((
  ref,
  lessonId,
) {
  final lessons = ref.watch(learnerLessonsProvider).valueOrNull ?? [];
  final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;
  return lesson != null && ListeningQuizGenerator.canGenerate(lesson);
});

final quizResultProvider =
    Provider.family<AsyncValue<Either<Failure, QuizModel>>, String>((
      ref,
      quizId,
    ) {
      if (quizId.startsWith('listening_quiz_')) {
        final lessonId = quizId.substring('listening_quiz_'.length);
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

        final listeningQuiz = ListeningQuizGenerator.generate(lesson);
        if (listeningQuiz.questions.isEmpty) {
          // Spec §14 line 680: exclude incomplete questions from published
          // quiz pools. A lesson without playable audio has no listening
          // quiz — surface a not-found rather than an empty experience.
          return const AsyncValue.data(
            Left(ServerFailure(message: 'No listening quiz available.')),
          );
        }
        return AsyncValue.data(Right(listeningQuiz));
      }

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
