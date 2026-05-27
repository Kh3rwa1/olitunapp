import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../shared/models/content_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../data/quiz_repository.dart';
import 'providers/quiz_session_notifier.dart';
import 'widgets/quiz_option_tile.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_question_card.dart';
import 'widgets/quiz_feedback_panel.dart';
import 'widgets/quiz_complete_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _started = false;

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
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

          final notifier = ref.read(
            quizSessionNotifierProvider(widget.quizId).notifier,
          );
          final question = quiz.questions[state.currentQuestion];
          final totalQs = quiz.questions.length;
          final isFillBlank = question.type == 'fill_blank';

          Widget buildQuestionArea() {
            if (!isFillBlank) {
              return QuizQuestionCard(question: question);
            }

            final parts =
                question.blankSentenceOlChiki?.split('___') ?? ['', ''];

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.quizDarkCard, AppColors.quizDarkCardAlt]
                      : [AppColors.quizLightSuccessSurface, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.05 : 0.08,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      question.promptOlChiki,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (question.promptLatin != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      question.promptLatin!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 36),

                  // Premium Duolingo Mascot Speech Bubble representation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(
                              'assets/images/olitun_mascot.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.quizDarkBubble
                                : AppColors.quizLightBubble,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (parts.isNotEmpty &&
                                  parts[0].trim().isNotEmpty)
                                Text(
                                  parts[0].trim(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'OlChiki',
                                  ),
                                ),

                              // Blank/Pulsing Slot or Filled option
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: state.selectedAnswer != null
                                      ? (state.isAnswered
                                            ? (state.selectedAnswer ==
                                                      question.correctIndex
                                                  ? AppColors.success
                                                  : AppColors.error)
                                            : AppColors.primary)
                                      : (isDark
                                            ? AppColors.quizDarkCardAlt
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: state.selectedAnswer != null
                                        ? Colors.transparent
                                        : AppColors.primary,
                                    style: state.selectedAnswer != null
                                        ? BorderStyle.none
                                        : BorderStyle.solid,
                                    width: 2,
                                  ),
                                  boxShadow: state.selectedAnswer != null
                                      ? [
                                          BoxShadow(
                                            color:
                                                (state.isAnswered
                                                        ? (state.selectedAnswer ==
                                                                  question
                                                                      .correctIndex
                                                              ? AppColors
                                                                    .success
                                                              : AppColors.error)
                                                        : AppColors.primary)
                                                    .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  state.selectedAnswer != null
                                      ? question.optionsOlChiki[state
                                            .selectedAnswer!]
                                      : ' ── ', // Empty blank line placeholder
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'OlChiki',
                                    color: state.selectedAnswer != null
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                              ),

                              if (parts.length > 1 &&
                                  parts[1].trim().isNotEmpty)
                                Text(
                                  parts[1].trim(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'OlChiki',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (question.blankSentenceLatin != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Translation: "${question.blankSentenceLatin}"',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 450.ms).scale(begin: const Offset(0.96, 0.96));
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
                    onTap: () => notifier.selectAnswer(index, question, quiz),
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
                    correctOptionOlChiki:
                        question.optionsOlChiki[question.correctIndex],
                    correctOptionLatin:
                        question.optionsLatin[question.correctIndex],
                    explanation: question.explanation,
                    onContinue: () => notifier.nextQuestion(quiz),
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
    return Semantics(
      container: true,
      label: 'Quiz session stats',
      value:
          '${state.hearts} hearts, ${state.comboStreak} answer combo, ${state.comboMultiplier} times multiplier',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: _HudChip(
                icon: Icons.favorite_rounded,
                label: '${state.hearts}',
                accent: AppColors.duoRed,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HudChip(
                icon: Icons.local_fire_department_rounded,
                label: '${state.comboStreak}',
                accent: AppColors.duoOrange,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HudChip(
                icon: Icons.bolt_rounded,
                label: 'x${state.comboMultiplier}',
                accent: AppColors.duoYellow,
                isDark: isDark,
              ),
            ),
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
