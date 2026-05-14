import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';

class QuizSessionState {
  final int currentQuestion;
  final int score;
  final int? selectedAnswer;
  final bool isAnswered;
  final bool isQuizComplete;

  const QuizSessionState({
    this.currentQuestion = 0,
    this.score = 0,
    this.selectedAnswer,
    this.isAnswered = false,
    this.isQuizComplete = false,
  });

  QuizSessionState copyWith({
    int? currentQuestion,
    int? score,
    int? selectedAnswer,
    bool? isAnswered,
    bool? isQuizComplete,
    bool clearSelectedAnswer = false,
  }) {
    return QuizSessionState(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      score: score ?? this.score,
      selectedAnswer: clearSelectedAnswer
          ? null
          : (selectedAnswer ?? this.selectedAnswer),
      isAnswered: isAnswered ?? this.isAnswered,
      isQuizComplete: isQuizComplete ?? this.isQuizComplete,
    );
  }
}

class QuizSessionNotifier extends AutoDisposeNotifier<QuizSessionState> {
  @override
  QuizSessionState build() {
    return const QuizSessionState();
  }

  void selectAnswer(int index, QuizQuestion question) {
    if (state.isAnswered) return;

    final isCorrect = index == question.correctIndex;
    int newScore = state.score;
    if (isCorrect) {
      newScore++;
      HapticFeedback.mediumImpact();
      Future.delayed(
        const Duration(milliseconds: 90),
        HapticFeedback.lightImpact,
      );
    } else {
      HapticFeedback.mediumImpact();
    }

    state = state.copyWith(
      selectedAnswer: index,
      isAnswered: true,
      score: newScore,
    );
  }

  void nextQuestion(QuizModel quiz) {
    if (state.currentQuestion < quiz.questions.length - 1) {
      state = state.copyWith(
        currentQuestion: state.currentQuestion + 1,
        clearSelectedAnswer: true,
        isAnswered: false,
      );
    } else {
      state = state.copyWith(isQuizComplete: true);

      final statsNotifier = ref.read(userStatsProvider.notifier);
      statsNotifier.saveQuizResult(
        QuizResultEntity(
          quizId: quiz.id,
          score: state.score,
          totalQuestions: quiz.questions.length,
          completedAt: DateTime.now().toIso8601String(),
        ),
      );
      statsNotifier.addStars(state.score * 5);
    }
  }

  void reset() {
    state = const QuizSessionState();
  }
}

final quizSessionNotifierProvider =
    NotifierProvider.autoDispose<QuizSessionNotifier, QuizSessionState>(
      QuizSessionNotifier.new,
    );
