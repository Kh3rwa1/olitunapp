import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/widgets/confetti_overlay.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/repositories/content_repository.dart';
import '../../../shared/models/content_models.dart';

final quizProvider = FutureProvider.family<QuizModel?, String>((ref, quizId) async {
  final contentRepo = ContentRepository();
  return contentRepo.getQuiz(quizId);
});

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizScreen({
    super.key,
    required this.quizId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  int _correctCount = 0;
  bool _showConfetti = false;
  bool _quizComplete = false;

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.quizId));

    return Stack(
      children: [
        BubbleBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: CircleIconButton(
                icon: Icons.close_rounded,
                onPressed: () => _showExitDialog(context),
              ),
              title: quizAsync.when(
                data: (quiz) => quiz != null
                    ? Text('Question ${_currentQuestionIndex + 1}/${quiz.questions.length}')
                    : const Text('Quiz'),
                loading: () => const ShimmerText(width: 100),
                error: (_, __) => const Text('Quiz'),
              ),
              actions: [
                CircleIconButton(
                  icon: Icons.volume_up_rounded,
                  onPressed: () {
                    // Toggle sound
                  },
                ),
                const SizedBox(width: AppConstants.spacingS),
              ],
            ),
            body: quizAsync.when(
              data: (quiz) {
                if (quiz == null) {
                  return const Center(child: Text('Quiz not found'));
                }

                if (_quizComplete) {
                  return _buildResultScreen(context, quiz);
                }

                if (quiz.questions.isEmpty) {
                  return const Center(child: Text('No questions available'));
                }

                final question = quiz.questions[_currentQuestionIndex];
                return _buildQuestionScreen(context, quiz, question);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ),
        
        // Confetti overlay
        ConfettiOverlay(
          show: _showConfetti,
          onComplete: () {
            if (mounted) {
              setState(() {
                _showConfetti = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuestionScreen(
    BuildContext context,
    QuizModel quiz,
    QuizQuestion question,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scriptMode = 'both'; // TODO: Get from provider

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          children: [
            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentQuestionIndex + 1) / quiz.questions.length,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // Question card
            SoftCard(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  // Ol Chiki prompt
                  if (question.promptOlChiki.isNotEmpty &&
                      (scriptMode == 'olchiki' || scriptMode == 'both'))
                    Text(
                      question.promptOlChiki,
                      style: const TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  
                  // Latin prompt
                  if (question.promptLatin != null &&
                      question.promptLatin!.isNotEmpty &&
                      (scriptMode == 'latin' || scriptMode == 'both')) ...[
                    if (scriptMode == 'both')
                      const SizedBox(height: AppConstants.spacingS),
                    Text(
                      question.promptLatin!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scriptMode == 'both'
                            ? (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight)
                            : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // Options
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppConstants.spacingM,
                  mainAxisSpacing: AppConstants.spacingM,
                  childAspectRatio: 1.5,
                ),
                itemCount: question.optionsOlChiki.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedAnswer == index;
                  final isCorrect = index == question.correctIndex;

                  String optionText;
                  if (scriptMode == 'olchiki') {
                    optionText = question.optionsOlChiki[index];
                  } else if (scriptMode == 'latin') {
                    optionText = question.optionsLatin[index];
                  } else {
                    optionText = '${question.optionsOlChiki[index]}\n${question.optionsLatin[index]}';
                  }

                  return _OptionCard(
                    text: optionText,
                    isSelected: isSelected,
                    isCorrect: _showResult ? isCorrect : null,
                    showResult: _showResult,
                    onTap: _showResult
                        ? null
                        : () => _selectAnswer(index, question.correctIndex),
                  );
                },
              ),
            ),

            // Continue button (shows after answering)
            if (_showResult) ...[
              const SizedBox(height: AppConstants.spacingM),
              PrimaryButton(
                text: _currentQuestionIndex < quiz.questions.length - 1
                    ? 'Next Question'
                    : 'See Results',
                onPressed: () => _nextQuestion(quiz),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context, QuizModel quiz) {
    final percentage = (_correctCount / quiz.questions.length * 100).round();
    final passed = percentage >= quiz.passingScore;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Result icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: passed ? AppColors.mintGradient : AppColors.coralGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.coloredShadow(
                  passed ? AppColors.success : AppColors.error,
                ),
              ),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // Result text
            Text(
              passed ? 'Congratulations!' : 'Keep Practicing!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'You got $_correctCount out of ${quiz.questions.length} correct',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // Score card
            SoftCard(
              width: 200,
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: passed ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Text(
                    passed ? 'Well Done!' : 'Try Again',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // Stars earned
            if (passed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 32),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(
                    '+${(percentage / 10).round()} Stars',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accentYellow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            const Spacer(),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Try Again',
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex = 0;
                        _selectedAnswer = null;
                        _showResult = false;
                        _correctCount = 0;
                        _quizComplete = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: PrimaryButton(
                    text: 'Done',
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(int index, int correctIndex) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedAnswer = index;
      _showResult = true;
      if (index == correctIndex) {
        _correctCount++;
        _showConfetti = true;
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _nextQuestion(QuizModel quiz) {
    if (_currentQuestionIndex < quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showResult = false;
      });
    } else {
      setState(() {
        _quizComplete = true;
      });
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrect;
  final bool showResult;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.text,
    required this.isSelected,
    this.isCorrect,
    this.showResult = false,
    this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.fastAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (widget.showResult && widget.isSelected) {
      if (widget.isCorrect == true) {
        bgColor = AppColors.success.withValues(alpha: 0.15);
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else {
        bgColor = AppColors.error.withValues(alpha: 0.15);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      }
    } else if (widget.showResult && widget.isCorrect == true) {
      bgColor = AppColors.success.withValues(alpha: 0.15);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (widget.isSelected) {
      bgColor = AppColors.primaryCyan.withValues(alpha: 0.15);
      borderColor = AppColors.primaryCyan;
      textColor = AppColors.primaryCyan;
    } else {
      bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: AppConstants.normalAnimation,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: widget.isSelected ? AppColors.softShadow : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontFamily: widget.text.contains('ᱚ') ? 'OlChiki' : 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
