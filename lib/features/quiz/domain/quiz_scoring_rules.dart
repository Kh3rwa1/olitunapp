class QuizScoringRules {
  /// The number of stars awarded per correct answer.
  static const int starsPerCorrectAnswer = 5;

  /// The minimum score ratio required to pass a quiz.
  static const double passingThreshold = 0.7;

  /// Calculates total stars earned based on correct answer score and optional bonus stars.
  static int calculateStars(int score, {int bonusStars = 0}) {
    return (score * starsPerCorrectAnswer) + bonusStars;
  }

  /// Determines if a score is passing based on total questions.
  static bool isPassing(int score, int totalQuestions) {
    if (totalQuestions <= 0) return false;
    return (score / totalQuestions) >= passingThreshold;
  }
}
