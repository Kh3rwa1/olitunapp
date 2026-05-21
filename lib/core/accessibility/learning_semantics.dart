class LearningSemantics {
  const LearningSemantics._();

  static String olChikiText({
    required String text,
    String? latin,
    String? meaning,
  }) {
    return _join([
      'Ol Chiki text $text',
      if (_hasValue(latin)) 'Latin reading $latin',
      if (_hasValue(meaning)) 'Meaning $meaning',
    ]);
  }

  static String quizQuestion({required String prompt, String? latin}) {
    return _join([
      'Quiz question, Ol Chiki prompt $prompt',
      if (_hasValue(latin)) 'Question text $latin',
    ]);
  }

  static String quizOption({
    required int index,
    required String option,
    bool isSelected = false,
    bool isAnswered = false,
    bool isCorrect = false,
  }) {
    final letter = String.fromCharCode(65 + index);
    return _join([
      'Answer $letter, $option',
      if (isSelected) 'selected',
      if (isAnswered && isCorrect) 'correct',
      if (isAnswered && isSelected && !isCorrect) 'incorrect',
    ]);
  }

  static String strokeOrder(String glyph) {
    return 'Stroke order animation for Ol Chiki character $glyph';
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _join(List<String> parts) => parts.join(', ');
}
