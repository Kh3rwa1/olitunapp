import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/quiz_repository.dart';
import 'providers/quiz_session_notifier.dart';
import 'widgets/quiz_complete_screen.dart';
import 'widgets/quiz_empty_view.dart';
import 'widgets/quiz_option_tile.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_question_card.dart';

class QuizScreen extends ConsumerWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizFutureProvider(quizId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return quizAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => _QuizStateScaffold(
        isDark: isDark,
        icon: Icons.cloud_off_rounded,
        title: 'Could not load quiz',
        message: 'Check your connection and try again.',
        primaryLabel: 'Try again',
        primaryIcon: Icons.refresh_rounded,
        onPrimary: () => ref.invalidate(quizFutureProvider(quizId)),
        onClose: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      data: (quiz) {
        if (quiz == null) {
          return const QuizEmptyView(isNotFound: true);
        }
        if (quiz.questions.isEmpty) {
          return const QuizEmptyView();
        }

        final state = ref.watch(quizSessionNotifierProvider(quizId));
        if (state.isQuizComplete) {
          return QuizCompleteScreen(
            score: state.score,
            totalQuestions: quiz.questions.length,
          );
        }

        final notifier = ref.read(quizSessionNotifierProvider(quizId).notifier);
        final question = quiz.questions[state.currentQuestion];
        final totalQs = quiz.questions.length;
        final isFillBlank = question.type == 'fill_blank';

        Widget buildQuestionArea() {
          if (!isFillBlank) {
            return QuizQuestionCard(question: question);
          }

          final parts = question.blankSentenceOlChiki?.split('___') ?? ['', ''];
          
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF152232), const Color(0xFF0F1A24)]
                    : [const Color(0xFFF0FDF4), Colors.white],
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
                  color: AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  question.promptOlChiki,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: 0.5,
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
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🦉', // AAA Duolingo style Mascot owl
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2C3E) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (parts.isNotEmpty && parts[0].trim().isNotEmpty)
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: state.selectedAnswer != null
                                    ? (state.isAnswered
                                        ? (state.selectedAnswer == question.correctIndex
                                            ? AppColors.success
                                            : AppColors.error)
                                        : AppColors.primary)
                                    : (isDark ? const Color(0xFF0F1A24) : Colors.white),
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
                                          color: (state.isAnswered
                                              ? (state.selectedAnswer == question.correctIndex
                                                  ? AppColors.success
                                                  : AppColors.error)
                                              : AppColors.primary)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                state.selectedAnswer != null
                                    ? question.optionsOlChiki[state.selectedAnswer!]
                                    : '      ', // Empty blank
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

                            if (parts.length > 1 && parts[1].trim().isNotEmpty)
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
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
            return ListView.builder(
              itemCount: question.optionsLatin.length,
              itemBuilder: (_, index) => QuizOptionTile(
                index: index,
                currentQuestion: state.currentQuestion,
                question: question,
                isSelected: state.selectedAnswer == index,
                isAnswered: state.isAnswered,
                onTap: () => notifier.selectAnswer(index, question, quiz),
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
                children: List.generate(
                  question.optionsOlChiki.length,
                  (index) {
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
                        chipColor = isDark ? const Color(0xFF1C2C3E) : const Color(0xFFF3F4F6);
                        textColor = isDark ? Colors.white30 : Colors.black26;
                        borderSide = BorderSide.none;
                      }
                    } else {
                      if (isCurrentSelection) {
                        chipColor = isDark ? const Color(0xFF0F1A24) : Colors.grey.shade100;
                        textColor = Colors.transparent;
                        borderSide = BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                          width: 1.5,
                        );
                      } else {
                        chipColor = isDark ? const Color(0xFF152232) : Colors.white;
                        textColor = isDark ? Colors.white : Colors.black87;
                        borderSide = BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          width: 1.5,
                        );
                      }
                    }

                    return GestureDetector(
                      onTap: (state.isAnswered || isCurrentSelection)
                          ? null
                          : () => notifier.selectAnswer(index, question, quiz),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.fromBorderSide(borderSide),
                          boxShadow: (!state.isAnswered && !isCurrentSelection)
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 3),
                                  )
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
                    ).animate(key: ValueKey('chip-$index-${state.selectedAnswer}-${state.isAnswered}')).scale(
                          begin: const Offset(0.95, 0.95),
                          duration: 150.ms,
                        );
                  },
                ),
              ),
            ],
          );
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
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
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.currentQuestion + 1}/$totalQs',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                QuizProgressBar(
                  current: state.currentQuestion + 1,
                  total: totalQs,
                  isDark: isDark,
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Column(
                    children: [
                      buildQuestionArea(),
                      const SizedBox(height: 32),
                      Expanded(
                        child: buildOptionsArea(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuizStateScaffold extends StatelessWidget {
  const _QuizStateScaffold({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.onClose,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: onClose,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onPrimary,
                icon: Icon(primaryIcon),
                label: Text(primaryLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
