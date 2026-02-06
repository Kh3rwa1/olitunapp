import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String? quizId;
  const QuizScreen({super.key, this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedOptionIndex;

  // Dynamic questions list
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer loading to allow provider access
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuiz());
  }

  void _loadQuiz() {
    if (widget.quizId == null) {
      // Fallback to hardcoded for testing/legacy
      _loadHardcoded();
      return;
    }

    final quizzes = ref.read(quizzesProvider).value ?? [];
    try {
      final quiz = quizzes.firstWhere((q) => q.id == widget.quizId);
      setState(() {
        _questions = quiz.questions;
        _isLoading = false;
      });
    } catch (e) {
      // Quiz not found or empty
      _loadHardcoded();
    }
  }

  void _loadHardcoded() {
    setState(() {
      _questions = [
        QuizQuestion(
          promptOlChiki: 'Which letter represents the sound "La"?',
          optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱞ'],
          optionsLatin: [],
          correctIndex: 0,
        ),
        QuizQuestion(
          promptOlChiki: 'Which number is "5"?',
          optionsOlChiki: ['᱑', '᱒', '᱕', '᱑᱐'],
          optionsLatin: [],
          correctIndex: 2,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quiz Complete! 🎉'),
        content: Text(
          'You scored $_score out of ${_questions.length}!',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Back to Home'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentQuestionIndex = 0;
                _score = 0;
                _answered = false;
                _selectedOptionIndex = null;
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Error')),
        body: const Center(child: Text('No questions found for this quiz.')),
      );
    }

    final question = _questions[_currentQuestionIndex];
    // Use Ol Chiki options by default, fallback to Latin if needed
    final options = question.optionsOlChiki.isNotEmpty
        ? question.optionsOlChiki
        : question.optionsLatin;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Quiz (${_currentQuestionIndex + 1}/${_questions.length})'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 40),

            // Question Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                question.promptOlChiki,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),

            // Options
            ...List.generate(options.length, (index) {
              final isSelected = _selectedOptionIndex == index;
              final hasAnswered = _answered;
              final isCorrect = index == question.correctIndex;

              Color? cardColor;
              if (hasAnswered) {
                if (isSelected) {
                  cardColor = isCorrect ? Colors.green[100] : Colors.red[100];
                } else if (isCorrect) {
                  cardColor = Colors.green[100];
                } else {
                  cardColor = isDark ? const Color(0xFF2C3E50) : Colors.white;
                }
              } else {
                cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => _answerQuestion(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasAnswered && (isSelected || isCorrect)
                            ? (isCorrect ? Colors.green : Colors.red)
                            : Colors.grey.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C...
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            options[index],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (hasAnswered && isSelected)
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            if (_answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
