import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  bool _isQuizComplete = false;

  @override
  Widget build(BuildContext context) {
    final quizzes = ref.watch(quizzesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return quizzes.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (data) {
        final quiz = data.firstWhere(
          (q) => q.id == widget.quizId,
          orElse: () =>
              data.isNotEmpty ? data.first : throw Exception('No quiz found'),
        );

        if (quiz.questions.isEmpty) {
          return _buildEmptyQuiz(context, isDark);
        }

        if (_isQuizComplete) {
          return _buildQuizComplete(context, isDark, quiz.questions.length);
        }

        final question = quiz.questions[_currentQuestion];
        final totalQuestions = quiz.questions.length;

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
              quiz.title ?? 'Quiz',
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
                  '${_currentQuestion + 1}/$totalQuestions',
                  style: TextStyle(
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
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentQuestion + 1) / totalQuestions,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 40),

                // Question
                Expanded(
                  child: Column(
                    children: [
                      Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  question.promptOlChiki,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'OlChiki',
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (question.promptLatin != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      question.promptLatin!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.95, 0.95)),

                      const SizedBox(height: 32),

                      // Options
                      Expanded(
                        child: ListView.builder(
                          itemCount: question.optionsLatin.length,
                          itemBuilder: (context, index) {
                            final isSelected = _selectedAnswer == index;
                            final isCorrect = index == question.correctIndex;

                            Color bgColor;
                            if (_isAnswered) {
                              if (isCorrect) {
                                bgColor = AppColors.success;
                              } else if (isSelected && !isCorrect) {
                                bgColor = AppColors.error;
                              } else {
                                bgColor = isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white;
                              }
                            } else {
                              bgColor = isSelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.white);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PressableScale(
                                enabled: !_isAnswered,
                                haptic: HapticIntensity.none,
                                onTap: _isAnswered
                                    ? null
                                    : () => _selectAnswer(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                                ? Colors.white10
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  )),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected && !_isAnswered
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 15,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: (_isAnswered && isCorrect)
                                              ? Colors.white
                                              : (isSelected
                                                    ? AppColors.primary
                                                    : Colors.transparent),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                isSelected ||
                                                    (_isAnswered && isCorrect)
                                                ? Colors.transparent
                                                : (isDark
                                                      ? Colors.white24
                                                      : Colors.black12),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + index),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: (_isAnswered && isCorrect)
                                                  ? AppColors.success
                                                  : (isSelected
                                                        ? Colors.white
                                                        : (isDark
                                                              ? Colors.white54
                                                              : Colors
                                                                    .black45)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          question.optionsLatin[index],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                (_isAnswered &&
                                                    (isCorrect || isSelected))
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white
                                                      : Colors.black),
                                          ),
                                        ),
                                      ),
                                      if (_isAnswered && isCorrect)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                        ),
                                      if (_isAnswered &&
                                          isSelected &&
                                          !isCorrect)
                                        const Icon(
                                          Icons.cancel_rounded,
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                                .animate(
                                  key: ValueKey(
                                    'opt-$_currentQuestion-$index-$_isAnswered',
                                  ),
                                )
                                .fadeIn(
                                  delay: _isAnswered
                                      ? Duration.zero
                                      : (index * 80).ms,
                                  duration: 300.ms,
                                )
                                .then()
                                .swap(
                                  builder: (context, child) {
                                    if (!_isAnswered) return child;
                                    if (isCorrect) {
                                      // Brief scale pulse on the right answer.
                                      return child
                                          .animate()
                                          .scaleXY(
                                            begin: 1.0,
                                            end: 1.04,
                                            duration: 180.ms,
                                            curve: const Cubic(
                                              0.34,
                                              1.56,
                                              0.64,
                                              1.0,
                                            ),
                                          )
                                          .then()
                                          .scaleXY(
                                            begin: 1.0,
                                            end: 1 / 1.04,
                                            duration: 220.ms,
                                          );
                                    }
                                    if (isSelected && !isCorrect) {
                                      // Damped horizontal shake on wrong.
                                      return child
                                          .animate()
                                          .shakeX(
                                            hz: 6,
                                            amount: 4,
                                            duration: 360.ms,
                                          );
                                    }
                                    return child;
                                  },
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Continue button
                if (_isAnswered)
                  PressableScale(
                    onTap: _nextQuestion,
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
                      child: const Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
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

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
      final quizzes = ref.read(quizzesProvider);
      quizzes.whenData((data) {
        final quiz = data.firstWhere((q) => q.id == widget.quizId);
        final isCorrect =
            index == quiz.questions[_currentQuestion].correctIndex;
        if (isCorrect) {
          _score++;
          // Crisp double-tap haptic for "right answer" satisfaction.
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 90), () {
            HapticFeedback.lightImpact();
          });
        } else {
          // Medium single thump for "wrong" — firm but not punitive.
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  void _nextQuestion() {
    final quizzes = ref.read(quizzesProvider);
    quizzes.whenData((data) {
      final quiz = data.firstWhere((q) => q.id == widget.quizId);

      if (_currentQuestion < quiz.questions.length - 1) {
        setState(() {
          _currentQuestion++;
          _selectedAnswer = null;
          _isAnswered = false;
        });
      } else {
        setState(() {
          _isQuizComplete = true;
        });
        final statsNotifier = ref.read(userStatsProvider.notifier);
        statsNotifier.saveQuizResult(QuizResultEntity(
          quizId: quiz.id,
          score: _score,
          totalQuestions: quiz.questions.length,
          completedAt: DateTime.now().toIso8601String(),
        ));
        statsNotifier.addStars(_score * 5);
      }
    });
  }

  Widget _buildEmptyQuiz(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizComplete(
    BuildContext context,
    bool isDark,
    int totalQuestions,
  ) {
    final percentage = (_score / totalQuestions * 100).round();
    final isPassing = percentage >= 70;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      body: Stack(
        children: [
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: isPassing
                          ? AppColors.premiumGreen
                          : AppColors.premiumOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isPassing
                                      ? AppColors.success
                                      : AppColors.warning)
                                  .withValues(alpha: 0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPassing
                          ? Icons.emoji_events_rounded
                          : Icons.refresh_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 36),
              Text(
                isPassing ? 'Well Done!' : 'Keep Practicing',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 16),
              Text(
                'You scored $_score out of $totalQuestions',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 12),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: isPassing ? AppColors.success : AppColors.warning,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '+${_score * 5} Stars',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
              const Spacer(),
              GestureDetector(
                    onTap: () => context.go('/'),
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
                      child: const Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 400.ms)
                  .slideY(begin: 0.3),
            ],
          ),
        ),
      ),
          if (isPassing)
            const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}
