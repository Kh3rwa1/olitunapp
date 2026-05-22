import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/quiz/data/quiz_repository.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/quizzes_provider.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  final quiz = QuizModel(
    id: 'quiz_letters',
    categoryId: 'letters',
    title: 'Letters',
    questions: [
      QuizQuestion(
        promptOlChiki: 'ᱚ',
        promptLatin: 'Choose the sound',
        optionsOlChiki: ['ᱚ', 'ᱟ'],
        optionsLatin: ['o', 'a'],
      ),
    ],
  );

  ProviderContainer containerWith(AsyncValue<List<QuizModel>> state) {
    final container = ProviderContainer(
      overrides: [
        quizzesProvider.overrideWith((ref) => _TestQuizzesNotifier(state)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('QuizRepository', () {
    test('returns quiz as Either Right when found', () async {
      final repo = containerWith(
        AsyncValue.data([quiz]),
      ).read(quizRepositoryProvider);

      final result = await repo.getQuiz('quiz_letters');

      result.fold(
        (failure) => fail('Expected quiz, got ${failure.message}'),
        (loaded) => expect(loaded.id, 'quiz_letters'),
      );
    });

    test('returns typed 404 failure when quiz is missing', () async {
      final repo = containerWith(
        AsyncValue.data([quiz]),
      ).read(quizRepositoryProvider);

      final result = await repo.getQuiz('missing_quiz');

      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.code, 404);
        expect(failure.message, contains('missing_quiz'));
      }, (_) => fail('Expected missing quiz failure'));
    });

    test('maps Appwrite network errors to NetworkFailure', () async {
      final repo = containerWith(
        AsyncValue.error(
          AppwriteException('offline', 0, 'network_failure'),
          StackTrace.current,
        ),
      ).read(quizRepositoryProvider);

      final result = await repo.getQuiz('quiz_letters');

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected network failure'),
      );
    });
  });
}

class _TestQuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>>
    with Mock
    implements QuizzesNotifier {
  _TestQuizzesNotifier(super.state);
}
