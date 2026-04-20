import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String? quizId;
  const QuizScreen({super.key, this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedOptionIndex;
  List<QuizQuestion> _questions = [];
  QuizModel? _quiz;
  bool _isLoading = true;

  late AnimationController _celebrationController;

  // Kid-friendly card colors
  static const List<Color> _cardColors = [
    AppColors.quizCardA,
    AppColors.quizCardB,
    AppColors.quizCardC,
    AppColors.quizCardD,
  ];

  static const List<Color> _badgeColors = [
    AppColors.quizBadgeA,
    AppColors.quizBadgeB,
    AppColors.quizBadgeC,
    AppColors.quizBadgeD,
  ];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuiz());
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _loadQuiz() {
    if (widget.quizId == null) {
      _loadHardcoded();
      return;
    }

    try {
      final quiz = ref
          .read(quizzesProvider)
          .value
          ?.firstWhere((q) => q.id == widget.quizId);
      if (quiz == null) {
        _loadHardcoded();
        return;
      }

      // Get current mastery level for this category

      setState(() {
        _quiz = quiz;
        // In a real app, we might filter questions by level
        // For now, we use the quiz's questions, but we could augment this logic
        _questions = quiz.questions;
        _isLoading = false;
      });
    } catch (e) {
      _loadHardcoded();
    }
  }

  void _loadHardcoded() {
    setState(() {
      _questions = [
        QuizQuestion(
          promptOlChiki: 'ᱚ',
          promptLatin: 'Which sound does this letter make?',
          optionsOlChiki: ['a', 'i', 'u', 'o'],
          optionsLatin: ['a', 'i', 'u', 'o'],
          correctIndex: 0,
        ),
      ];
      _isLoading = false;
    });
  }

  void _answerQuestion(int index) {
    if (_answered) return;

    final correctIndex = _questions[_currentQuestionIndex].correctIndex;
    final isCorrect = index == correctIndex;

    setState(() {
      _answered = true;
      _selectedOptionIndex = index;
      if (isCorrect) {
        _score++;
        HapticFeedback.mediumImpact();
        _celebrationController.forward(from: 0);
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedOptionIndex = null;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final percentage = (_score / _questions.length * 100).round();
    final isPassing = percentage >= 70;

    final startingMastery =
        ref.read(progressProvider).categoryMastery[_quiz?.categoryId] ?? 0;

    // Persist quiz result and update streak
    final progressNotifier = ref.read(progressProvider.notifier);
    progressNotifier.completeQuiz(
      widget.quizId ?? '',
      _score,
      _questions.length,
      categoryId: _quiz?.categoryId,
    );

    final finalMastery =
        ref.read(progressProvider).categoryMastery[_quiz?.categoryId] ?? 0;
    final leveledUp = finalMastery > startingMastery;

    // Award stars based on performance
    if (isPassing) {
      progressNotifier.addStars(_score * 5); // 5 stars per correct answer
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.quizBackground,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy/Stars
              Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: isPassing
                          ? AppColors.premiumGreen
                          : AppColors.peachGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPassing ? AppColors.primary : Colors.orange)
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPassing
                          ? Icons.emoji_events_rounded
                          : Icons.refresh_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .scale(begin: const Offset(0, 0), curve: Curves.elasticOut)
                  .then()
                  .shake(hz: 2, rotation: 0.05),
              const SizedBox(height: 24),
              Text(
                isPassing ? 'Amazing! 🎉' : 'Keep Trying! 💪',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You scored $_score out of ${_questions.length}',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              // Score percentage
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isPassing
                      ? AppColors.quizCorrect.withValues(alpha: 0.15)
                      : AppColors.quizIncorrect.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isPassing
                        ? AppColors.quizCorrect
                        : AppColors.quizIncorrect,
                  ),
                ),
              ),
              if (leveledUp) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Level Up: ${_quiz?.level ?? ""} Mastering! 🎖️',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ).animate().shimmer(delay: 1.seconds).scale(delay: 1.2.seconds),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/quizzes');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.quizNextButton,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF6B4B,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _currentQuestionIndex = 0;
                            _score = 0;
                            _answered = false;
                            _selectedOptionIndex = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.quizBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.quizBackground,
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions found.')),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final options = question.optionsLatin.isNotEmpty
        ? question.optionsLatin
        : question.optionsOlChiki;

    return Scaffold(
      backgroundColor: AppColors.quizBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 16),

              // Progress Dots
              _buildProgressDots(),
              const SizedBox(height: 24),

              // Question Card with Ol Chiki character
              _buildQuestionCard(question),
              const SizedBox(height: 32),

              // 2x2 Answer Grid
              Expanded(child: _buildAnswerGrid(options, question.correctIndex)),

              // Next Button
              if (_answered) _buildNextButton(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Back Button
        GestureDetector(
          onTap: () => context.go('/quizzes'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
        ),
        const Spacer(),
        // Question Counter
        Text(
          '${_currentQuestionIndex + 1}/${_questions.length}Q',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        // Stars/Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.quizBadgeA,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.quizBadgeA.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_questions.length, (index) {
        final isCompleted = index < _currentQuestionIndex;
        final isCurrent = index == _currentQuestionIndex;

        Color dotColor;
        if (isCompleted) {
          dotColor = AppColors.quizCorrect;
        } else if (isCurrent) {
          dotColor = AppColors.quizBadgeB;
        } else {
          dotColor = Colors.grey[300]!;
        }

        return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 28 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(6),
              ),
            )
            .animate(target: isCurrent ? 1 : 0)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
      }),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Large Ol Chiki character
              Text(
                question.promptOlChiki,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Question text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    question.promptLatin ?? 'Select the correct answer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 8),
                  // Audio button placeholder
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, curve: Curves.easeOut);
  }

  Widget _buildAnswerGrid(List<String> options, int correctIndex) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(options.length.clamp(0, 4), (index) {
        return _buildAnswerCard(
          index: index,
          text: options[index],
          correctIndex: correctIndex,
        );
      }),
    );
  }

  Widget _buildAnswerCard({
    required int index,
    required String text,
    required int correctIndex,
  }) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == correctIndex;
    final letter = String.fromCharCode(65 + index);

    Color cardBg = _cardColors[index % 4];
    Color badgeColor = _badgeColors[index % 4];
    Color borderColor = Colors.transparent;

    if (_answered) {
      if (isSelected) {
        cardBg = isCorrect
            ? AppColors.quizCorrect.withValues(alpha: 0.2)
            : AppColors.quizIncorrect.withValues(alpha: 0.2);
        borderColor = isCorrect
            ? AppColors.quizCorrect
            : AppColors.quizIncorrect;
      } else if (isCorrect) {
        cardBg = AppColors.quizCorrect.withValues(alpha: 0.15);
        borderColor = AppColors.quizCorrect;
      }
    }

    return GestureDetector(
          onTap: () => _answerQuestion(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: _answered && (isSelected || isCorrect) ? 3 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Letter badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Answer text
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Feedback icon
                if (_answered && (isSelected || isCorrect))
                  Positioned(
                    top: 12,
                    right: 12,
                    child:
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppColors.quizCorrect
                                : AppColors.quizIncorrect,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ).animate().scale(
                          begin: const Offset(0, 0),
                          curve: Curves.elasticOut,
                        ),
                  ),
              ],
            ),
          ),
        )
        .animate(delay: (index * 80).ms)
        .fadeIn()
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.quizNextButton,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B4B).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _currentQuestionIndex < _questions.length - 1
              ? 'Next Question'
              : 'Finish Quiz',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }
}
