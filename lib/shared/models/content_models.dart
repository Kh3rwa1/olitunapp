import 'package:cloud_firestore/cloud_firestore.dart';

// ============== CATEGORY MODEL ==============
class CategoryModel {
  final String id;
  final String titleOlChiki;
  final String titleLatin;
  final String? iconUrl;
  final String? iconName;
  final String gradientPreset;
  final int order;
  final bool isActive;
  final int totalLessons;
  final String? description;

  CategoryModel({
    required this.id,
    required this.titleOlChiki,
    required this.titleLatin,
    this.iconUrl,
    this.iconName,
    this.gradientPreset = 'skyBlue',
    this.order = 0,
    this.isActive = true,
    this.totalLessons = 0,
    this.description,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return CategoryModel(
      id: docId,
      titleOlChiki: data['titleOlChiki'] as String? ?? '',
      titleLatin: data['titleLatin'] as String? ?? '',
      iconUrl: data['iconUrl'] as String?,
      iconName: data['iconName'] as String?,
      gradientPreset: data['gradientPreset'] as String? ?? 'skyBlue',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      totalLessons: data['totalLessons'] as int? ?? 0,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titleOlChiki': titleOlChiki,
      'titleLatin': titleLatin,
      'iconUrl': iconUrl,
      'iconName': iconName,
      'gradientPreset': gradientPreset,
      'order': order,
      'isActive': isActive,
      'totalLessons': totalLessons,
      'description': description,
    };
  }

  // Convenience getters for backwards compatibility
  String get titleEn => titleLatin;
  String get icon => iconName ?? 'book';

  CategoryModel copyWith({
    String? titleOlChiki,
    String? titleLatin,
    String? iconUrl,
    String? iconName,
    String? gradientPreset,
    int? order,
    bool? isActive,
    int? totalLessons,
    String? description,
  }) {
    return CategoryModel(
      id: id,
      titleOlChiki: titleOlChiki ?? this.titleOlChiki,
      titleLatin: titleLatin ?? this.titleLatin,
      iconUrl: iconUrl ?? this.iconUrl,
      iconName: iconName ?? this.iconName,
      gradientPreset: gradientPreset ?? this.gradientPreset,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      totalLessons: totalLessons ?? this.totalLessons,
      description: description ?? this.description,
    );
  }
}

// ============== FEATURED BANNER MODEL ==============
class FeaturedBannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String gradientPreset;
  final String? targetRoute;
  final int order;
  final bool isActive;

  FeaturedBannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.gradientPreset = 'skyBlue',
    this.targetRoute,
    this.order = 0,
    this.isActive = true,
  });

  factory FeaturedBannerModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return FeaturedBannerModel(
      id: docId,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String?,
      imageUrl: data['imageUrl'] as String?,
      gradientPreset: data['gradientPreset'] as String? ?? 'skyBlue',
      targetRoute: data['targetRoute'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'gradientPreset': gradientPreset,
      'targetRoute': targetRoute,
      'order': order,
      'isActive': isActive,
    };
  }
}

// ============== LETTER MODEL ==============
class LetterModel {
  final String id;
  final String charOlChiki;
  final String transliterationLatin;
  final String? exampleWordOlChiki;
  final String? exampleWordLatin;
  final String? imageUrl;
  final String? audioUrl;
  final int order;
  final bool isActive;
  final String? pronunciation;

  LetterModel({
    required this.id,
    required this.charOlChiki,
    required this.transliterationLatin,
    this.exampleWordOlChiki,
    this.exampleWordLatin,
    this.imageUrl,
    this.audioUrl,
    this.order = 0,
    this.isActive = true,
    this.pronunciation,
  });

  factory LetterModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return LetterModel(
      id: docId,
      charOlChiki: data['charOlChiki'] as String? ?? '',
      transliterationLatin: data['transliterationLatin'] as String? ?? '',
      exampleWordOlChiki: data['exampleWordOlChiki'] as String?,
      exampleWordLatin: data['exampleWordLatin'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      pronunciation: data['pronunciation'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'charOlChiki': charOlChiki,
      'transliterationLatin': transliterationLatin,
      'exampleWordOlChiki': exampleWordOlChiki,
      'exampleWordLatin': exampleWordLatin,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'order': order,
      'isActive': isActive,
      'pronunciation': pronunciation,
    };
  }
}

// ============== LESSON MODEL ==============
class LessonModel {
  final String id;
  final String categoryId;
  final String titleOlChiki;
  final String titleLatin;
  final String level;
  final int order;
  final bool isActive;
  final List<LessonBlock> blocks;
  final int estimatedMinutes;
  final String? thumbnailUrl;

  LessonModel({
    required this.id,
    required this.categoryId,
    required this.titleOlChiki,
    required this.titleLatin,
    this.level = 'beginner',
    this.order = 0,
    this.isActive = true,
    this.blocks = const [],
    this.estimatedMinutes = 5,
    this.thumbnailUrl,
  });

  factory LessonModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final blocksData = data['blocks'] as List<dynamic>? ?? [];
    return LessonModel(
      id: docId,
      categoryId: data['categoryId'] as String? ?? '',
      titleOlChiki: data['titleOlChiki'] as String? ?? '',
      titleLatin: data['titleLatin'] as String? ?? '',
      level: data['level'] as String? ?? 'beginner',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      blocks: blocksData.map((b) => LessonBlock.fromMap(b as Map<String, dynamic>)).toList(),
      estimatedMinutes: data['estimatedMinutes'] as int? ?? 5,
      thumbnailUrl: data['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'titleOlChiki': titleOlChiki,
      'titleLatin': titleLatin,
      'level': level,
      'order': order,
      'isActive': isActive,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'estimatedMinutes': estimatedMinutes,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class LessonBlock {
  final String type; // text, image, audio, quiz
  final String? textOlChiki;
  final String? textLatin;
  final String? imageUrl;
  final String? audioUrl;
  final String? quizRefId;

  LessonBlock({
    required this.type,
    this.textOlChiki,
    this.textLatin,
    this.imageUrl,
    this.audioUrl,
    this.quizRefId,
  });

  factory LessonBlock.fromMap(Map<String, dynamic> data) {
    return LessonBlock(
      type: data['type'] as String? ?? 'text',
      textOlChiki: data['textOlChiki'] as String?,
      textLatin: data['textLatin'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      quizRefId: data['quizRefId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'textOlChiki': textOlChiki,
      'textLatin': textLatin,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'quizRefId': quizRefId,
    };
  }
}

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

  factory QuizModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final questionsData = data['questions'] as List<dynamic>? ?? [];
    return QuizModel(
      id: docId,
      categoryId: data['categoryId'] as String?,
      level: data['level'] as String? ?? 'beginner',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      questions: questionsData.map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>)).toList(),
      title: data['title'] as String?,
      passingScore: data['passingScore'] as int? ?? 70,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'level': level,
      'order': order,
      'isActive': isActive,
      'questions': questions.map((q) => q.toMap()).toList(),
      'title': title,
      'passingScore': passingScore,
    };
  }
}

class QuizQuestion {
  final String promptOlChiki;
  final String? promptLatin;
  final List<String> optionsOlChiki;
  final List<String> optionsLatin;
  final int correctIndex;
  final String? explanation;
  final String? audioUrl;
  final String? imageUrl;

  QuizQuestion({
    required this.promptOlChiki,
    this.promptLatin,
    required this.optionsOlChiki,
    required this.optionsLatin,
    required this.correctIndex,
    this.explanation,
    this.audioUrl,
    this.imageUrl,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    return QuizQuestion(
      promptOlChiki: data['promptOlChiki'] as String? ?? '',
      promptLatin: data['promptLatin'] as String?,
      optionsOlChiki: List<String>.from(data['optionsOlChiki'] as List? ?? []),
      optionsLatin: List<String>.from(data['optionsLatin'] as List? ?? []),
      correctIndex: data['correctIndex'] as int? ?? 0,
      explanation: data['explanation'] as String?,
      audioUrl: data['audioUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'promptOlChiki': promptOlChiki,
      'promptLatin': promptLatin,
      'optionsOlChiki': optionsOlChiki,
      'optionsLatin': optionsLatin,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
    };
  }
}

// ============== STICKER MODEL ==============
class StickerModel {
  final String id;
  final String name;
  final String imageUrl;
  final String? category;
  final bool isActive;

  StickerModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.category,
    this.isActive = true,
  });

  factory StickerModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return StickerModel(
      id: docId,
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      category: data['category'] as String?,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
    };
  }
}

// ============== USER PROGRESS MODEL ==============
class UserProgressModel {
  final String categoryId;
  final double percent;
  final DateTime updatedAt;
  final int completedLessons;
  final int totalLessons;

  UserProgressModel({
    required this.categoryId,
    this.percent = 0,
    required this.updatedAt,
    this.completedLessons = 0,
    this.totalLessons = 0,
  });

  factory UserProgressModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserProgressModel(
      categoryId: docId,
      percent: (data['percent'] as num?)?.toDouble() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedLessons: data['completedLessons'] as int? ?? 0,
      totalLessons: data['totalLessons'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'percent': percent,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
    };
  }
}
