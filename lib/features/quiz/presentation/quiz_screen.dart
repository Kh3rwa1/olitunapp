import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/motion/motion.dart';
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
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (quiz) {
        if (quiz == null) {
          return const QuizEmptyView(isNotFound: true);
        }
        if (quiz.questions.isEmpty) {
          return const QuizEmptyView();
        }

        final state = ref.watch(quizSessionNotifierProvider);
        if (state.isQuizComplete) {
          return QuizCompleteScreen(
            score: state.score,
            totalQuestions: quiz.questions.length,
          );
        }

        final notifier = ref.read(quizSessionNotifierProvider.notifier);
        final question = quiz.questions[state.currentQuestion];
        final totalQs = quiz.questions.length;

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
              onPressed: () => context.go('/'),
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
                      QuizQuestionCard(question: question),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView.builder(
                          itemCount: question.optionsLatin.length,
                          itemBuilder: (_, index) => QuizOptionTile(
                            index: index,
                            currentQuestion: state.currentQuestion,
                            question: question,
                            isSelected: state.selectedAnswer == index,
                            isAnswered: state.isAnswered,
                            onTap: () => notifier.selectAnswer(index, question),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isAnswered)
                  PressableScale(
                    onTap: () => notifier.nextQuestion(quiz),
                    haptic: HapticIntensity.selection,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.continueButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        );
      },
    );
  }
}
