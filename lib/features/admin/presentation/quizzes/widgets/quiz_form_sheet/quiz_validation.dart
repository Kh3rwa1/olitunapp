class QuizValidation {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    return null;
  }

  static String? validateOrder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Order is required';
    }
    if (int.tryParse(value) == null) {
      return 'Order must be a valid number';
    }
    return null;
  }

  static String? validatePassingScore(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Passing score is required';
    }
    final score = int.tryParse(value);
    if (score == null || score < 0 || score > 100) {
      return 'Must be between 0 and 100';
    }
    return null;
  }
}
