import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';
import '../../../home/presentation/providers/mission_providers.dart';
import 'mistake_provider.dart';

class QuizSessionState {
  final int currentQuestion;
  final int score;
  final int? selectedAnswer;
  final bool isAnswered;
  final bool isQuizComplete;
  final int hearts;
  final int comboStreak;
  final int bestCombo;
  final int comboMultiplier;
  final int bonusStars;
  final List<int> incorrectQuestionIndices;

  const QuizSessionState({
    this.currentQuestion = 0,
    this.score = 0,
    this.selectedAnswer,
    this.isAnswered = false,
    this.isQuizComplete = false,
    this.hearts = 3,
    this.comboStreak = 0,
    this.bestCombo = 0,
    this.comboMultiplier = 1,
    this.bonusStars = 0,
    this.incorrectQuestionIndices = const [],
  });

  QuizSessionState copyWith({
    int? currentQuestion,
    int? score,
    int? selectedAnswer,
    bool? isAnswered,
    bool? isQuizComplete,
    int? hearts,
    int? comboStreak,
    int? bestCombo,
    int? comboMultiplier,
    int? bonusStars,
    List<int>? incorrectQuestionIndices,
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
      hearts: hearts ?? this.hearts,
      comboStreak: comboStreak ?? this.comboStreak,
      bestCombo: bestCombo ?? this.bestCombo,
      comboMultiplier: comboMultiplier ?? this.comboMultiplier,
      bonusStars: bonusStars ?? this.bonusStars,
      incorrectQuestionIndices:
          incorrectQuestionIndices ?? this.incorrectQuestionIndices,
    );
  }
}

QuizSessionState applyQuizAnswerResult(
  QuizSessionState current, {
  required bool isCorrect,
}) {
  var newScore = current.score;
  var hearts = current.hearts;
  var comboStreak = current.comboStreak;
  var bestCombo = current.bestCombo;
  var comboMultiplier = current.comboMultiplier;
  var bonusStars = current.bonusStars;
  final incorrectIndices = List<int>.from(current.incorrectQuestionIndices);

  if (isCorrect) {
    newScore++;
    comboStreak++;
    bestCombo = bestCombo > comboStreak ? bestCombo : comboStreak;
    comboMultiplier = (1 + (comboStreak ~/ 3)).clamp(1, 4);
    bonusStars += (comboMultiplier - 1) * 2;
  } else {
    hearts = (hearts - 1).clamp(0, 3);
    comboStreak = 0;
    comboMultiplier = 1;
    incorrectIndices.add(current.currentQuestion);
  }

  return current.copyWith(
    score: newScore,
    hearts: hearts,
    comboStreak: comboStreak,
    bestCombo: bestCombo,
    comboMultiplier: comboMultiplier,
    bonusStars: bonusStars,
    incorrectQuestionIndices: incorrectIndices,
  );
}

class QuizSessionNotifier
    extends AutoDisposeFamilyNotifier<QuizSessionState, String> {
  @override
  QuizSessionState build(String quizId) {
    return const QuizSessionState();
  }

  void selectAnswer(int index, QuizQuestion question, QuizModel quiz) {
    if (state.isAnswered) return;

    final isCorrect = index == question.correctIndex;
    final scoredState = applyQuizAnswerResult(state, isCorrect: isCorrect);

    if (isCorrect) {
      if (_shouldUseHaptics) HapticFeedback.lightImpact();
    } else {
      ref
          .read(mistakeProvider.notifier)
          .recordMistake(
            quizId: quiz.id,
            questionIndex: state.currentQuestion,
            question: question,
            wrongAnswer: index < question.optionsLatin.length
                ? question.optionsLatin[index]
                : index < question.optionsOlChiki.length
                ? question.optionsOlChiki[index]
                : '',
          );
      if (_shouldUseHaptics) HapticFeedback.mediumImpact();
    }

    state = scoredState.copyWith(selectedAnswer: index, isAnswered: true);
  }

  bool get _shouldUseHaptics {
    return ref.read(soundEnabledProvider) &&
        !ref.read(reduceVisualEffectsProvider);
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
      statsNotifier.addStars((state.score * 5) + state.bonusStars);
      ref.read(quizTakenTodayProvider.notifier).setCompleted(true);
    }
  }

  void reset() {
    state = const QuizSessionState();
  }
}

final quizSessionNotifierProvider = NotifierProvider.autoDispose
    .family<QuizSessionNotifier, QuizSessionState, String>(
      QuizSessionNotifier.new,
    );
