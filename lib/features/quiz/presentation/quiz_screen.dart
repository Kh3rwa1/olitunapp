import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../core/config/feature_flags.dart';
import '../../../shared/models/content_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../shared/providers/providers.dart';
import '../../content/presentation/providers/audio_playback_providers.dart';

import '../data/quiz_repository.dart';
import 'providers/quiz_session_notifier.dart';
import 'widgets/listening_question_card.dart';
import 'widgets/quiz_option_tile.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_question_card.dart';
import 'widgets/quiz_feedback_panel.dart';
import 'widgets/quiz_complete_screen.dart';
import 'widgets/quiz_out_of_hearts_screen.dart';
import 'widgets/fill_blank_question_card.dart';
import 'widgets/quiz_session_hud.dart';
import 'widgets/quiz_fill_blank_options.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _started = false;

  /// Phase 7: spec §16 listening-quiz funnel events. Emitted alongside the
  /// generic quiz events, only while the audio-quizzes flag is on.
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
    if (wasAnswered) return; // selectAnswer is a no-op in that case
    _trackListeningAnswered(
      quiz: quiz,
      question: question,
      selectedIndex: index,
      isCorrect: index == question.correctIndex,
    );
  }

  void _playQuestionAudioIfAvailable(QuizQuestion question) {
    final soundEnabled = ref.read(soundEnabledProvider);
    if (!soundEnabled) return;
    final audioUrl = question.audioUrl;
    if (audioUrl != null && audioUrl.trim().isNotEmpty) {
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
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuizSessionState>(quizSessionNotifierProvider(widget.quizId), (
      prev,
      next,
    ) {
      if (next.currentQuestion != prev?.currentQuestion &&
          !next.isQuizComplete) {
        final quiz = ref
            .read(quizResultProvider(widget.quizId))
            .valueOrNull
            ?.toNullable();
        if (quiz != null && next.currentQuestion < quiz.questions.length) {
          _playQuestionAudioIfAvailable(quiz.questions[next.currentQuestion]);
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
            ref
                .read(quizSessionNotifierProvider(widget.quizId).notifier)
                .startQuiz(quiz);
            if (quiz.questions.isNotEmpty) {
              _playQuestionAudioIfAvailable(quiz.questions.first);
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
            ref
                .read(quizSessionNotifierProvider(widget.quizId).notifier)
                .startQuiz(quiz);
            if (quiz.questions.isNotEmpty) {
              _playQuestionAudioIfAvailable(quiz.questions.first);
            }
          });
        });
      });
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          final totalQs = quiz.questions.length;
          final audioQuizzesEnabled = ref
              .watch(featureFlagsProvider)
              .audioQuizzesEnabled;
          final isListeningQuestion =
              audioQuizzesEnabled &&
              question.type == 'listen_meaning' &&
              question.audioUrl != null;
          final isFillBlank =
              !isListeningQuestion && question.type == 'fill_blank';
          final correctOptionOlChiki =
              question.correctIndex >= 0 &&
                  question.correctIndex < question.optionsOlChiki.length
              ? question.optionsOlChiki[question.correctIndex]
              : '';
          final correctOptionLatin =
              question.correctIndex >= 0 &&
                  question.correctIndex < question.optionsLatin.length
              ? question.optionsLatin[question.correctIndex]
              : correctOptionOlChiki;

          Widget buildQuestionArea() {
            if (isListeningQuestion) {
              final playback = ref.watch(playbackStateProvider);
              final playbackState = playback.valueOrNull;
              final isPlayingThisAudio =
                  playbackState?.isPlaying == true &&
                  playbackState?.current?.id == question.audioUrl;
              final isLoadingThisAudio =
                  playbackState?.isLoading == true &&
                  playbackState?.current?.id == question.audioUrl;
              return ListeningQuestionCard(
                question: question,
                isPlaying: isPlayingThisAudio,
                isLoading: isLoadingThisAudio,
                playbackError: playbackState?.error,
                onPlayTap: () {
                  unawaited(
                    ref
                        .read(playbackControllerProvider)
                        .playSingle(
                          id: question.audioUrl!,
                          contentKind: 'lesson',
                          contentId: widget.quizId,
                          trackType: 'targetNormal',
                          languageCode: 'sat',
                        ),
                  );
                },
                onStopTap: () {
                  unawaited(ref.read(playbackControllerProvider).stop());
                },
              );
            }

            if (!isFillBlank) {
              final playback = ref.watch(playbackStateProvider);
              final playbackState = playback.valueOrNull;
              final hasAudio =
                  question.audioUrl != null &&
                  question.audioUrl!.trim().isNotEmpty;
              final isPlayingThisAudio =
                  hasAudio &&
                  playbackState?.isPlaying == true &&
                  playbackState?.current?.id == question.audioUrl;
              final isLoadingThisAudio =
                  hasAudio &&
                  playbackState?.isLoading == true &&
                  playbackState?.current?.id == question.audioUrl;

              return QuizQuestionCard(
                question: question,
                isPlaying: isPlayingThisAudio,
                isLoading: isLoadingThisAudio,
                onPlayAudio: hasAudio
                    ? () {
                        if (isPlayingThisAudio) {
                          unawaited(
                            ref.read(playbackControllerProvider).stop(),
                          );
                        } else {
                          unawaited(
                            ref
                                .read(playbackControllerProvider)
                                .playSingle(
                                  id: question.audioUrl!,
                                  contentKind: 'quiz_question',
                                  contentId: widget.quizId,
                                  trackType: 'targetNormal',
                                  languageCode: 'sat',
                                ),
                          );
                        }
                      }
                    : null,
              );
            }

            return FillBlankQuestionCard(
              question: question,
              selectedAnswer: state.selectedAnswer,
              isAnswered: state.isAnswered,
            );
          }

          Widget buildOptionsArea() {
            if (!isFillBlank) {
              return Column(
                children: List.generate(
                  question.optionsLatin.length,
                  (index) => QuizOptionTile(
                    index: index,
                    currentQuestion: state.currentQuestion,
                    question: question,
                    isSelected: state.selectedAnswer == index,
                    isAnswered: state.isAnswered,
                    onTap: () => _selectAnswer(index, question, quiz),
                  ),
                ),
              );
            }

            return QuizFillBlankOptions(
              question: question,
              state: state,
              isDark: isDark,
              onSelect: (index) => notifier.selectAnswer(index, question, quiz),
            );
          }

          return Scaffold(
            backgroundColor: isDark
                ? AppColors.quizDarkBackground
                : Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Close quiz',
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
              title: Text(
                quiz.title ?? AppLocalizations.of(context)!.quiz,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              actions: [
                QuizCountPill(
                  current: state.currentQuestion + 1,
                  total: totalQs,
                ),
              ],
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      QuizProgressBar(
                        current: state.currentQuestion + 1,
                        total: totalQs,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      QuizSessionHud(state: state, isDark: isDark),
                      const SizedBox(height: 28),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              buildQuestionArea(),
                              const SizedBox(height: 32),
                              buildOptionsArea(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: OfflineStatusBanner(),
                ),
              ],
            ),
            bottomNavigationBar: state.isAnswered
                ? QuizFeedbackPanel(
                    isCorrect: state.selectedAnswer == question.correctIndex,
                    correctOptionOlChiki: correctOptionOlChiki,
                    correctOptionLatin: correctOptionLatin,
                    explanation: question.explanation,
                    onContinue: () => unawaited(notifier.nextQuestion(quiz)),
                  )
                : null,
          );
        },
      ),
    );
  }
}
