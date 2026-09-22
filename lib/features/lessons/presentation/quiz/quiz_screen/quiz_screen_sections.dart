part of 'quiz_screen.dart';

// Kid-friendly card colors
const List<Color> _cardColors = [
  AppColors.quizCardA,
  AppColors.quizCardB,
  AppColors.quizCardC,
  AppColors.quizCardD,
];

const List<Color> _badgeColors = [
  AppColors.quizBadgeA,
  AppColors.quizBadgeB,
  AppColors.quizBadgeC,
  AppColors.quizBadgeD,
];

/// Extracted UI builders for [_QuizScreenState] (header, progress dots,
/// question card). Kept as an extension so the moved code uses `state`,
/// `context`, and private members verbatim.
extension _QuizScreenSections on _QuizScreenState {
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
          isFocused: _focusedIndex == index,
        );
      }),
    );
  }

  Widget _buildAnswerCard({
    required int index,
    required String text,
    required int correctIndex,
    required bool isFocused,
  }) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == correctIndex;
    final letter = String.fromCharCode(65 + index);
    final isDesktopWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    Color cardBg = _cardColors[index % 4];
    final Color badgeColor = _badgeColors[index % 4];
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
    } else if (isFocused) {
      borderColor = AppColors.primary;
    }

    final hasHighlightBorder =
        (_answered && (isSelected || isCorrect)) || (!_answered && isFocused);

    return GestureDetector(
          onTap: () => _answerQuestion(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: hasHighlightBorder ? 3 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isFocused && !_answered
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : badgeColor.withValues(alpha: 0.15),
                  blurRadius: isFocused && !_answered ? 16 : 12,
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

                // Desktop shortcut badge
                if (isDesktopWeb && !_answered)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: isFocused ? 0.15 : 0.05,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isFocused ? AppColors.primary : Colors.black12,
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isFocused ? AppColors.primary : Colors.black45,
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
    final isDesktopWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.quizNextButton,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCoral.withValues(alpha: 0.4),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentQuestionIndex < _questions.length - 1
                  ? 'Next Question'
                  : 'Finish Quiz',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (isDesktopWeb) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Enter ↵',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }
}
