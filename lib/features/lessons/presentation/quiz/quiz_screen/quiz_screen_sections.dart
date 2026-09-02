part of 'quiz_screen.dart';

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
}
