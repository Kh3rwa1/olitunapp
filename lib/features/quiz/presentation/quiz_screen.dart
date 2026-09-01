import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../core/config/feature_flags.dart';
import '../../../shared/models/content_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../core/analytics/analytics_service.dart';
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

  @override
  Widget build(BuildContext context) {
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
              return QuizQuestionCard(question: question);
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

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Select the missing word:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 16,
                  children: List.generate(question.optionsOlChiki.length, (
                    index,
                  ) {
                    final isCorrect = index == question.correctIndex;
                    final isCurrentSelection = state.selectedAnswer == index;

                    Color chipColor;
                    Color textColor;
                    BorderSide borderSide;

                    if (state.isAnswered) {
                      if (isCorrect) {
                        chipColor = AppColors.success;
                        textColor = Colors.white;
                        borderSide = BorderSide.none;
                      } else if (isCurrentSelection) {
                        chipColor = AppColors.error;
                        textColor = Colors.white;
                        borderSide = BorderSide.none;
                      } else {
                        chipColor = isDark
                            ? AppColors.quizDarkBubble
                            : AppColors.quizLightBubble;
                        textColor = isDark ? Colors.white30 : Colors.black26;
                        borderSide = BorderSide.none;
                      }
                    } else {
                      if (isCurrentSelection) {
                        chipColor = isDark
                            ? AppColors.quizDarkCardAlt
                            : Colors.grey.shade100;
                        textColor = Colors.transparent;
                        borderSide = BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                          width: 1.5,
                        );
                      } else {
                        chipColor = isDark
                            ? AppColors.quizDarkCard
                            : Colors.white;
                        textColor = isDark ? Colors.white : Colors.black87;
                        borderSide = BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          width: 1.5,
                        );
                      }
                    }

                    return Semantics(
                          button: true,
                          enabled: !state.isAnswered && !isCurrentSelection,
                          selected: isCurrentSelection,
                          label:
                              'Missing word option ${index + 1}: ${question.optionsOlChiki[index]}',
                          value: state.isAnswered
                              ? (isCorrect
                                    ? 'Correct answer'
                                    : (isCurrentSelection
                                          ? 'Incorrect answer'
                                          : ''))
                              : null,
                          child: ExcludeSemantics(
                            child: GestureDetector(
                              onTap: (state.isAnswered || isCurrentSelection)
                                  ? null
                                  : () => notifier.selectAnswer(
                                      index,
                                      question,
                                      quiz,
                                    ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: chipColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.fromBorderSide(borderSide),
                                  boxShadow:
                                      (!state.isAnswered && !isCurrentSelection)
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: isDark ? 0.25 : 0.08,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  question.optionsOlChiki[index],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'OlChiki',
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate(
                          key: ValueKey(
                            'chip-$index-${state.selectedAnswer}-${state.isAnswered}',
                          ),
                        )
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          duration: 150.ms,
                        );
                  }),
                ),
              ],
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
                _QuizCountPill(
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
                      _QuizSessionHud(state: state, isDark: isDark),
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

class _QuizCountPill extends StatelessWidget {
  const _QuizCountPill({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quiz progress',
      value: 'Question $current of $total',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$current/$total',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizSessionHud extends StatelessWidget {
  const _QuizSessionHud({required this.state, required this.isDark});

  final QuizSessionState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final showCombo = state.comboStreak > 0;

    return Semantics(
      container: true,
      label: 'Quiz session stats',
      value: showCombo
          ? '${state.hearts} hearts, ${state.comboStreak} answer combo, ${state.comboMultiplier} times multiplier'
          : '${state.hearts} hearts',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: _HudChip(
                icon: Icons.favorite_rounded,
                label: '${state.hearts}',
                accent: AppColors.accentTerracotta,
                isDark: isDark,
              ),
            ),
            if (showCombo) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _HudChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${state.comboStreak}',
                  accent: AppColors.accentOchre,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HudChip(
                  icon: Icons.bolt_rounded,
                  label: 'x${state.comboMultiplier}',
                  accent: AppColors.accentGold,
                  isDark: isDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
