import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/audio/playback_controller.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/error/failures.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../content/presentation/providers/audio_playback_providers.dart';
import '../../lessons/domain/lesson_quiz_progression.dart';
import '../data/quiz_repository.dart';
import 'providers/quiz_session_notifier.dart';
import 'widgets/quiz_active_view.dart';
import 'widgets/quiz_complete_screen.dart';
import 'widgets/quiz_out_of_hearts_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String? lessonId;

  const QuizScreen({super.key, required this.quizId, this.lessonId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _started = false;
  bool _linkedLessonCompletionRecorded = false;
  late final PlaybackController _playback;

  @override
  void initState() {
    super.initState();
    _playback = ref.read(playbackControllerProvider);
  }

  void _recordLinkedLessonCompletion(QuizModel quiz, QuizSessionState session) {
    if (_linkedLessonCompletionRecorded) return;
    final linkedLesson = LessonQuizProgression.linkedPassingLesson(
      lessonId: widget.lessonId,
      quizId: quiz.id,
      score: session.score,
      totalQuestions: quiz.questions.length,
      lessons: () => ref.read(learnerLessonsProvider).valueOrNull ?? const [],
    );
    if (linkedLesson == null) return;

    _linkedLessonCompletionRecorded = true;
    unawaited(
      ref
          .read(userStatsProvider.notifier)
          .completeLesson(
            linkedLesson.id,
            categoryId: linkedLesson.categoryId,
            estimatedMinutes: linkedLesson.estimatedMinutes,
          ),
    );
  }

  void _trackListeningStarted(QuizModel quiz) {
    if (!ref.read(featureFlagsProvider).audioQuizzesEnabled) return;
    if (!quiz.id.startsWith('listening_quiz_')) return;
    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.listeningQuizStarted,
            source: 'quiz_session',
            sourceId: quiz.id,
            metadata: {
              'categoryId': quiz.categoryId,
              'title': quiz.title,
              'questionCount': quiz.questions.length,
            },
          ),
    );
  }

  void _trackListeningAnswered({
    required QuizModel quiz,
    required QuizQuestion question,
    required int selectedIndex,
    required bool isCorrect,
  }) {
    if (!ref.read(featureFlagsProvider).audioQuizzesEnabled) return;
    if (question.type != 'listen_meaning') return;
    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.listeningQuizAnswered,
            source: 'quiz_session',
            sourceId: quiz.id,
            metadata: {
              'isCorrect': isCorrect,
              'selectedIndex': selectedIndex,
              'correctIndex': question.correctIndex,
              'hasAudio': question.audioUrl != null,
            },
          ),
    );
  }

  void _selectAnswer(int index, QuizQuestion question, QuizModel quiz) {
    final notifier = ref.read(
      quizSessionNotifierProvider(widget.quizId).notifier,
    );
    final wasAnswered = ref
        .read(quizSessionNotifierProvider(widget.quizId))
        .isAnswered;
    notifier.selectAnswer(index, question, quiz);
    if (wasAnswered) return;
    _trackListeningAnswered(
      quiz: quiz,
      question: question,
      selectedIndex: index,
      isCorrect: index == question.correctIndex,
    );
  }

  void _playQuestionAudioIfAvailable(QuizQuestion question) {
    final soundEnabled = ref.read(soundEnabledProvider);
    final audioUrl = question.audioUrl;
    if (!soundEnabled || audioUrl == null || audioUrl.trim().isEmpty) {
      unawaited(ref.read(playbackControllerProvider).stop());
      return;
    }
    unawaited(
      ref
          .read(playbackControllerProvider)
          .playSingle(
            id: audioUrl,
            contentKind: 'quiz_question',
            contentId: widget.quizId,
            trackType: 'targetNormal',
            languageCode: 'sat',
          ),
    );
  }

  @override
  void dispose() {
    _playback.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuizSessionState>(quizSessionNotifierProvider(widget.quizId), (
      prev,
      next,
    ) {
      if (next.isQuizComplete && prev?.isQuizComplete != true) {
        final quiz = ref
            .read(quizResultProvider(widget.quizId))
            .valueOrNull
            ?.toNullable();
        if (quiz != null) _recordLinkedLessonCompletion(quiz, next);
      }
      if (next.isQuizComplete || next.isOutOfHearts) {
        unawaited(ref.read(playbackControllerProvider).stop());
        return;
      }
      if (next.currentQuestion != prev?.currentQuestion) {
        final quiz = ref
            .read(quizResultProvider(widget.quizId))
            .valueOrNull
            ?.toNullable();
        if (quiz != null && next.currentQuestion < quiz.questions.length) {
          final notifier = ref.read(
            quizSessionNotifierProvider(widget.quizId).notifier,
          );
          final displayed = notifier.displayedQuestion(quiz);
          _playQuestionAudioIfAvailable(displayed);
        }
      }
    });

    ref.listen<AsyncValue<Either<Failure, QuizModel>>>(
      quizResultProvider(widget.quizId),
      (prev, next) {
        if (_started) return;
        next.whenData((result) {
          result.fold((_) {}, (quiz) {
            if (quiz.questions.isEmpty) return;
            _started = true;
            _trackListeningStarted(quiz);
            final notifier = ref.read(
              quizSessionNotifierProvider(widget.quizId).notifier,
            );
            notifier.startQuiz(quiz);
            if (quiz.questions.isNotEmpty) {
              final displayed = notifier.displayedQuestion(quiz);
              _playQuestionAudioIfAvailable(displayed);
            }
          });
        });
      },
    );

    final quizAsync = ref.watch(quizResultProvider(widget.quizId));

    if (!_started) {
      quizAsync.whenData((result) {
        result.fold((_) {}, (quiz) {
          if (quiz.questions.isEmpty) return;
          _started = true;
          _trackListeningStarted(quiz);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final notifier = ref.read(
              quizSessionNotifierProvider(widget.quizId).notifier,
            );
            notifier.startQuiz(quiz);
            if (quiz.questions.isNotEmpty) {
              final displayed = notifier.displayedQuestion(quiz);
              _playQuestionAudioIfAvailable(displayed);
            }
          });
        });
      });
    }

    return quizAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingState(
          type: AppLoadingType.page,
          message: 'Loading Quiz...',
        ),
      ),
      error: (error, stack) => Scaffold(
        body: AppErrorState(
          message: 'Could not load the quiz.',
          onRetry: () => ref.invalidate(quizResultProvider(widget.quizId)),
        ),
      ),
      data: (quizResult) => quizResult.fold(
        (failure) => Scaffold(
          body: AppErrorState(
            message: failure.message,
            onRetry: () => ref.invalidate(quizResultProvider(widget.quizId)),
          ),
        ),
        (quiz) {
          if (quiz.questions.isEmpty) {
            return Scaffold(
              body: AppEmptyState(
                title: 'Quiz is Empty',
                description:
                    'This learning quiz does not have any questions yet.',
                buttonText: 'Back to Home',
                onButtonPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
                icon: Icons.quiz_outlined,
              ),
            );
          }

          final state = ref.watch(quizSessionNotifierProvider(widget.quizId));
          if (state.isQuizComplete) {
            return QuizCompleteScreen(
              score: state.score,
              totalQuestions: quiz.questions.length,
              bestCombo: state.bestCombo,
              bonusStars: state.bonusStars,
              incorrectQuestionIndices: state.incorrectQuestionIndices,
              questions: quiz.questions,
            );
          }
          if (state.isOutOfHearts) {
            return QuizOutOfHeartsScreen(
              score: state.score,
              totalQuestions: quiz.questions.length,
              bonusStars: state.bonusStars,
              incorrectQuestionIndices: state.incorrectQuestionIndices,
              questions: quiz.questions,
              quizId: widget.quizId,
            );
          }

          final notifier = ref.read(
            quizSessionNotifierProvider(widget.quizId).notifier,
          );
          final question = notifier.displayedQuestion(quiz);
          return QuizActiveView(
            quizId: widget.quizId,
            quiz: quiz,
            state: state,
            question: question,
            onSelectAnswer: (index) => _selectAnswer(index, question, quiz),
            onContinue: () => unawaited(notifier.nextQuestion(quiz)),
          );
        },
      ),
    );
  }
}
