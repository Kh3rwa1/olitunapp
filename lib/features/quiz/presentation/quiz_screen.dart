import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                            onTap: () =>
                                notifier.selectAnswer(index, question, quiz),
                          ),
                        ),
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
