import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/providers/quizzes_provider.dart';

class QuizRepository {
  final Ref _ref;

  QuizRepository(this._ref);

  Future<Either<Failure, QuizModel>> getQuiz(String quizId) async {
    return quizFromState(quizId, _ref.read(quizzesProvider));
  }

  Either<Failure, QuizModel> quizFromState(
    String quizId,
    AsyncValue<List<QuizModel>> quizzesAsync,
  ) {
    return quizzesAsync.when(
      loading: () =>
          const Left(CacheFailure(message: 'Quizzes are still loading.')),
      error: (error, _) => Left(_failureFromQuizLoad(error)),
      data: (quizzes) {
        for (final quiz in quizzes) {
          if (quiz.id == quizId) return Right(quiz);
        }

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

final quizResultProvider =
    Provider.family<AsyncValue<Either<Failure, QuizModel>>, String>((
      ref,
      quizId,
    ) {
      final repo = ref.watch(quizRepositoryProvider);
      final quizzesAsync = ref.watch(quizzesProvider);

      if (quizzesAsync.isLoading) {
        return const AsyncValue.loading();
      }

      return AsyncValue.data(repo.quizFromState(quizId, quizzesAsync));
    });
