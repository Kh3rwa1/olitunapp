import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';
import '../../../home/presentation/providers/mission_providers.dart';
import '../../domain/quiz_scoring_rules.dart';
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
  final bool hasStarted;
  final List<int> questionOrder;
  final List<List<int>> optionOrders;

  bool get isOutOfHearts => hearts <= 0 && isAnswered;

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
    this.hasStarted = false,
    this.questionOrder = const [],
    this.optionOrders = const [],
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
    bool? hasStarted,
    List<int>? questionOrder,
    List<List<int>>? optionOrders,
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
      hasStarted: hasStarted ?? this.hasStarted,
      questionOrder: questionOrder ?? this.questionOrder,
      optionOrders: optionOrders ?? this.optionOrders,
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
    final origIdx = current.questionOrder.isNotEmpty
        ? current.questionOrder[current.currentQuestion]
        : current.currentQuestion;
    incorrectIndices.add(origIdx);
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

  void startQuiz(QuizModel quiz, {Random? testRng}) {
    if (state.hasStarted) return;

    final rng =
        testRng ??
        Random(DateTime.now().millisecondsSinceEpoch ^ quiz.id.hashCode);
    final questionOrder = List<int>.generate(quiz.questions.length, (i) => i)
      ..shuffle(rng);
    final optionOrders = quiz.questions.map((q) {
      return List<int>.generate(q.optionsLatin.length, (i) => i)..shuffle(rng);
    }).toList();

    state = state.copyWith(
      hasStarted: true,
      questionOrder: questionOrder,
      optionOrders: optionOrders,
    );

    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.quizAttempted,
            source: 'quiz_session',
            sourceId: quiz.id,
            metadata: {
              'categoryId': quiz.categoryId,
              'title': quiz.title,
              'questionCount': quiz.questions.length,
              'passingScore': quiz.passingScore,
            },
          ),
    );
  }

  QuizQuestion displayedQuestion(QuizModel quiz) {
    if (state.questionOrder.isEmpty ||
        state.currentQuestion >= state.questionOrder.length) {
      return quiz.questions[state.currentQuestion];
    }
    final origIdx = state.questionOrder[state.currentQuestion];
    final raw = quiz.questions[origIdx];

    if (state.optionOrders.isEmpty ||
        state.currentQuestion >= state.optionOrders.length) {
      return raw;
    }
    final perm = state.optionOrders[state.currentQuestion];
    final newOptionsLatin = perm.map((i) => raw.optionsLatin[i]).toList();
    final newOptionsOlChiki = perm.map((i) => raw.optionsOlChiki[i]).toList();
    final newCorrectIndex = perm.indexOf(raw.correctIndex);
    return raw.copyWith(
      optionsLatin: newOptionsLatin,
      optionsOlChiki: newOptionsOlChiki,
      correctIndex: newCorrectIndex,
    );
  }

  void selectAnswer(int index, QuizQuestion question, QuizModel quiz) {
    if (state.isAnswered || state.hearts <= 0) return;

    final isCorrect = index == question.correctIndex;
    final scoredState = applyQuizAnswerResult(state, isCorrect: isCorrect);

    final origIdx = state.questionOrder.isNotEmpty
        ? state.questionOrder[state.currentQuestion]
        : state.currentQuestion;

    if (isCorrect) {
      if (_shouldUseHaptics) HapticFeedback.lightImpact();
    } else {
      ref
          .read(mistakeProvider.notifier)
          .recordMistake(
            quizId: quiz.id,
            questionIndex: origIdx,
            question: question,
            wrongAnswer: index < question.optionsLatin.length
                ? question.optionsLatin[index]
                : index < question.optionsOlChiki.length
                ? question.optionsOlChiki[index]
                : '',
          );
      if (_shouldUseHaptics) HapticFeedback.mediumImpact();
    }

    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.quizQuestionAnswered,
            source: 'quiz_session',
            sourceId: quiz.id,
            metadata: {
              'questionIndex': origIdx,
              'isCorrect': isCorrect,
              'selectedIndex': index,
              'correctIndex': question.correctIndex,
              'comboBefore': state.comboStreak,
              'heartsAfter': scoredState.hearts,
            },
          ),
    );

    state = scoredState.copyWith(selectedAnswer: index, isAnswered: true);

    if (state.isOutOfHearts) {
      _persistFailure(quiz);
    }
  }

  Future<void> _persistFailure(QuizModel quiz) async {
    try {
      final statsNotifier = ref.read(userStatsProvider.notifier);
      final completedAt = DateTime.now().toIso8601String();
      await statsNotifier.saveQuizResult(
        QuizResultEntity(
          quizId: quiz.id,
          score: state.score,
          totalQuestions: quiz.questions.length,
          completedAt: completedAt,
          failedNoHearts: true,
        ),
      );
      await statsNotifier.addStars(
        QuizScoringRules.calculateStars(state.score, bonusStars: state.bonusStars),
      );

      unawaited(
        ref
            .read(learningAnalyticsServiceProvider)
            .track(
              'quizFailedNoHearts',
              source: 'quiz_session',
              sourceId: quiz.id,
              metadata: {
                'questionsAnswered': state.currentQuestion + 1,
                'score': state.score,
              },
            ),
      );
    } catch (e, st) {
      AppLogger.debug('Failed to persist quiz failure: $e\n$st');
    }
  }

  bool get _shouldUseHaptics {
    return ref.read(soundEnabledProvider) &&
        !ref.read(reduceVisualEffectsProvider);
  }

  void nextQuestion(QuizModel quiz) {
    if (state.isOutOfHearts) return;
    if (state.currentQuestion < quiz.questions.length - 1) {
      state = state.copyWith(
        currentQuestion: state.currentQuestion + 1,
        clearSelectedAnswer: true,
        isAnswered: false,
      );
    } else {
      state = state.copyWith(isQuizComplete: true);

      try {
        final statsNotifier = ref.read(userStatsProvider.notifier);
        final completedAt = DateTime.now().toIso8601String();
        statsNotifier.saveQuizResult(
          QuizResultEntity(
            quizId: quiz.id,
            score: state.score,
            totalQuestions: quiz.questions.length,
            completedAt: completedAt,
          ),
        );
        statsNotifier.addStars(
          QuizScoringRules.calculateStars(state.score, bonusStars: state.bonusStars),
        );
        ref.read(quizTakenTodayProvider.notifier).setCompleted(true);
      } catch (e, st) {
        AppLogger.debug('Failed to finish quiz: $e\n$st');
      }
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
