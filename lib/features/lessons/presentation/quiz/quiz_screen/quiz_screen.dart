import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/presentation/layout/responsive_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../../../shared/widgets/state_widgets.dart';
import '../../../../quiz/domain/quiz_scoring_rules.dart';

part 'quiz_screen_sections.dart';

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
  int _focusedIndex = 0;
  late final FocusNode _focusNode;
  List<QuizQuestion> _questions = [];
  QuizModel? _quiz;
  bool _isLoading = true;

  /// Fail-closed load state. Null when the quiz resolved; otherwise the
  /// reason no quiz is shown. A missing quiz is never replaced with an
  /// unrelated hardcoded alphabet question.
  String? _loadError;

  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuiz());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _loadQuiz() {
    // A missing quiz id is a not-found state, not an alphabet question.
    if (widget.quizId == null || widget.quizId!.trim().isEmpty) {
      setState(() {
        _loadError = 'Quiz not found.';
        _isLoading = false;
      });
      return;
    }

    try {
      final quizzesAsync = ref.read(quizzesProvider);
      if (quizzesAsync.isLoading) {
        // Content still loading: stay in the loading state; the provider
        // listener in build() reloads once content arrives.
        return;
      }
      if (quizzesAsync.hasError) {
        setState(() {
          _loadError = 'Could not load the quiz.';
          _isLoading = false;
        });
        return;
      }
      QuizModel? quiz;
      for (final candidate in quizzesAsync.valueOrNull ?? const <QuizModel>[]) {
        if (candidate.id == widget.quizId) {
          quiz = candidate;
          break;
        }
      }
      if (quiz == null) {
        setState(() {
          _loadError = 'Quiz not found.';
          _isLoading = false;
        });
        return;
      }

      // Get current mastery level for this category

      setState(() {
        _quiz = quiz;
        // In a real app, we might filter questions by level
        // For now, we use the quiz's questions, but we could augment this logic
        _questions = quiz?.questions ?? const [];
        _loadError = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Could not load the quiz.';
        _isLoading = false;
      });
    }
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
        _focusedIndex = 0;
      });
    } else {
      _showResultDialog();
    }
  }

  void _moveGrid(int dRow, int dCol) {
    if (_answered) return;
    int row = _focusedIndex ~/ 2;
    int col = _focusedIndex % 2;
    row = (row + dRow).clamp(0, 1);
    col = (col + dCol).clamp(0, 1);
    setState(() {
      _focusedIndex = row * 2 + col;
    });
  }

  void _handleEnter() {
    if (_answered) {
      _nextQuestion();
    } else {
      _answerQuestion(_focusedIndex);
    }
  }

  void _showResultDialog() {
    // Fail closed: an empty quiz has no result to persist and no progress
    // to award.
    if (_questions.isEmpty) return;
    final percentage = (_score / _questions.length * 100).round();
    final isPassing = QuizScoringRules.isPassing(_score, _questions.length);

    final stats = ref.read(userStatsProvider).value;
    final _ = stats?.categoryMastery[_quiz?.categoryId] ?? 0;

    // Persist quiz result and update streak
    final statsNotifier = ref.read(userStatsProvider.notifier);
    statsNotifier.saveQuizResult(
      QuizResultEntity(
        quizId: widget.quizId ?? '',
        score: _score,
        totalQuestions: _questions.length,
        completedAt: DateTime.now().toIso8601String(),
      ),
    );

    // Award stars based on performance
    if (isPassing) {
      statsNotifier.addStars(QuizScoringRules.calculateStars(_score));
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
    // Retry the load when quiz content arrives after the first frame.
    ref.listen(quizzesProvider, (_, _) {
      if (!mounted || !_isLoading || _quiz != null || _loadError != null) {
        return;
      }
      _loadQuiz();
    });

    if (_isLoading) {
      return const Scaffold(
        body: AppLoadingState(
          type: AppLoadingType.page,
          message: 'Loading Quiz...',
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: AppEmptyState(
          title: 'Quiz not found',
          description:
              'This quiz could not be found. It may have been removed.',
          buttonText: 'Back to Quizzes',
          onButtonPressed: () => context.go('/quizzes'),
          icon: Icons.quiz_outlined,
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: AppEmptyState(
          title: 'Quiz is Empty',
          description: 'This learning quiz does not have any questions yet.',
          buttonText: 'Back to Quizzes',
          onButtonPressed: () => context.go('/quizzes'),
          icon: Icons.quiz_outlined,
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final options = question.optionsLatin.isNotEmpty
        ? question.optionsLatin
        : question.optionsOlChiki;

    final isDesktopWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          _moveGrid(0, 1),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          _moveGrid(0, -1),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          _moveGrid(1, 0),
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => _moveGrid(-1, 0),
      const SingleActivator(LogicalKeyboardKey.digit1): () =>
          _answerQuestion(0),
      const SingleActivator(LogicalKeyboardKey.numpad1): () =>
          _answerQuestion(0),
      const SingleActivator(LogicalKeyboardKey.digit2): () =>
          _answerQuestion(1),
      const SingleActivator(LogicalKeyboardKey.numpad2): () =>
          _answerQuestion(1),
      const SingleActivator(LogicalKeyboardKey.digit3): () =>
          _answerQuestion(2),
      const SingleActivator(LogicalKeyboardKey.numpad3): () =>
          _answerQuestion(2),
      const SingleActivator(LogicalKeyboardKey.digit4): () =>
          _answerQuestion(3),
      const SingleActivator(LogicalKeyboardKey.numpad4): () =>
          _answerQuestion(3),
      const SingleActivator(LogicalKeyboardKey.enter): _handleEnter,
      const SingleActivator(LogicalKeyboardKey.numpadEnter): _handleEnter,
      const SingleActivator(LogicalKeyboardKey.space): () {
        if (_answered) _nextQuestion();
      },
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.quizBackground,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveLayout.maxNarrowWidth(context),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
                          Expanded(
                            child: _buildAnswerGrid(
                              options,
                              question.correctIndex,
                            ),
                          ),

                          // Desktop keyboard shortcut guide
                          if (isDesktopWeb && !_answered)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: const Text(
                                  'Arrow keys to navigate  •  1-4 to select  •  Enter ↵ to submit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),

                          // Next Button
                          if (_answered) _buildNextButton(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: OfflineStatusBanner(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
