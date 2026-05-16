import 'dart:convert';

// ============== QUIZ MODEL ==============
class QuizModel {
  final String id;
  final String? categoryId;
  final String level;
  final int order;
  final bool isActive;
  final List<QuizQuestion> questions;
  final String? title;
  final int passingScore;

  QuizModel({
    required this.id,
    this.categoryId,
    this.level = 'beginner',
    this.order = 0,
    this.isActive = true,
    this.questions = const [],
    this.title,
    this.passingScore = 70,
  });

  factory QuizModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    final questionsData = _decodeQuizQuestions(data['questions']);
    return QuizModel(
      id: docId ?? data['id'] as String? ?? '',
      categoryId: data['categoryId'] as String?,
      level: data['level'] as String? ?? 'beginner',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      questions: questionsData
          .whereType<Map>()
          .map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q)))
          .toList(),
      title: data['title'] as String?,
      passingScore: data['passingScore'] as int? ?? 70,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'level': level,
      'order': order,
      'isActive': isActive,
      'questions': questions.map((q) => q.toMap()).toList(),
      'title': title,
      'passingScore': passingScore,
    };
  }

  QuizModel copyWith({
    String? id,
    String? categoryId,
    String? level,
    int? order,
    bool? isActive,
    List<QuizQuestion>? questions,
    String? title,
    int? passingScore,
  }) {
    return QuizModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      level: level ?? this.level,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      questions: questions ?? this.questions,
      title: title ?? this.title,
      passingScore: passingScore ?? this.passingScore,
    );
  }
}

class QuizQuestion {
  /// Question type: 'mcq' (multiple choice) or 'fill_blank' (fill in the blank)
  final String type;
  final String promptOlChiki;
  final String? promptLatin;
  final List<String> optionsOlChiki;
  final List<String> optionsLatin;
  final int correctIndex;
  final String? explanation;
  final String? audioUrl;
  final String? imageUrl;

  // Fill-in-the-blank fields: sentence with ___ placeholder
  final String? blankSentenceOlChiki;
  final String? blankSentenceLatin;
  final String? correctAnswer;
  final List<String> distractors;

  QuizQuestion({
    this.type = 'mcq',
    required this.promptOlChiki,
    this.promptLatin,
    this.optionsOlChiki = const [],
    this.optionsLatin = const [],
    this.correctIndex = 0,
    this.explanation,
    this.audioUrl,
    this.imageUrl,
    this.blankSentenceOlChiki,
    this.blankSentenceLatin,
    this.correctAnswer,
    this.distractors = const [],
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    return QuizQuestion(
      type: data['type'] as String? ?? 'mcq',
      promptOlChiki: data['promptOlChiki'] as String? ?? '',
      promptLatin: data['promptLatin'] as String?,
      optionsOlChiki: List<String>.from(data['optionsOlChiki'] as List? ?? []),
      optionsLatin: List<String>.from(data['optionsLatin'] as List? ?? []),
      correctIndex: data['correctIndex'] as int? ?? 0,
      explanation: data['explanation'] as String?,
      audioUrl: data['audioUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
      blankSentenceOlChiki: data['blankSentenceOlChiki'] as String?,
      blankSentenceLatin: data['blankSentenceLatin'] as String?,
      correctAnswer: data['correctAnswer'] as String?,
      distractors: List<String>.from(data['distractors'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'promptOlChiki': promptOlChiki,
      'promptLatin': promptLatin,
      'optionsOlChiki': optionsOlChiki,
      'optionsLatin': optionsLatin,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'blankSentenceOlChiki': blankSentenceOlChiki,
      'blankSentenceLatin': blankSentenceLatin,
      'correctAnswer': correctAnswer,
      'distractors': distractors,
    };
  }
}

List<dynamic> _decodeQuizQuestions(dynamic value) {
  if (value is List<dynamic>) return value;
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      return decoded is List<dynamic> ? decoded : const [];
    } catch (_) {
      return const [];
    }
  }
  return const [];
}
