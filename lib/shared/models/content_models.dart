// ============== CATEGORY MODEL ==============
class CategoryModel {
  final String id;
  final String titleOlChiki;
  final String titleLatin;
  final String? iconUrl;
  final String? iconName;
  final String? animationUrl;
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
    this.animationUrl,
    this.gradientPreset = 'skyBlue',
    this.order = 0,
    this.isActive = true,
    this.totalLessons = 0,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return CategoryModel(
      id: docId ?? data['id'] as String? ?? '',
      titleOlChiki: data['titleOlChiki'] as String? ?? '',
      titleLatin: data['titleLatin'] as String? ?? '',
      iconUrl: data['iconUrl'] as String?,
      iconName: data['iconName'] as String?,
      animationUrl: data['animationUrl'] as String?,
      gradientPreset: data['gradientPreset'] as String? ?? 'skyBlue',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      totalLessons: data['totalLessons'] as int? ?? 0,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleOlChiki': titleOlChiki,
      'titleLatin': titleLatin,
      'iconUrl': iconUrl,
      'iconName': iconName,
      'animationUrl': animationUrl,
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
    String? id,
    String? titleOlChiki,
    String? titleLatin,
    String? iconUrl,
    String? iconName,
    String? animationUrl,
    String? gradientPreset,
    int? order,
    bool? isActive,
    int? totalLessons,
    String? description,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      titleOlChiki: titleOlChiki ?? this.titleOlChiki,
      titleLatin: titleLatin ?? this.titleLatin,
      iconUrl: iconUrl ?? this.iconUrl,
      iconName: iconName ?? this.iconName,
      animationUrl: animationUrl ?? this.animationUrl,
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
  final String? animationUrl;
  final String gradientPreset;
  final String? targetRoute;
  final int order;
  final bool isActive;

  FeaturedBannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.animationUrl,
    this.gradientPreset = 'skyBlue',
    this.targetRoute,
    this.order = 0,
    this.isActive = true,
  });

  factory FeaturedBannerModel.fromJson(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return FeaturedBannerModel(
      id: docId ?? data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String?,
      imageUrl: data['imageUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      gradientPreset: data['gradientPreset'] as String? ?? 'skyBlue',
      targetRoute: data['targetRoute'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'animationUrl': animationUrl,
      'gradientPreset': gradientPreset,
      'targetRoute': targetRoute,
      'order': order,
      'isActive': isActive,
    };
  }

  FeaturedBannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? animationUrl,
    String? gradientPreset,
    String? targetRoute,
    int? order,
    bool? isActive,
  }) {
    return FeaturedBannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      gradientPreset: gradientPreset ?? this.gradientPreset,
      targetRoute: targetRoute ?? this.targetRoute,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
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
  final String? animationUrl;
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
    this.animationUrl,
    this.order = 0,
    this.isActive = true,
    this.pronunciation,
  });

  // Convenience getters for backwards compatibility
  String get character => charOlChiki;
  String get romanization => transliterationLatin;

  factory LetterModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return LetterModel(
      id: docId ?? data['id'] as String? ?? '',
      charOlChiki:
          data['charOlChiki'] as String? ?? data['character'] as String? ?? '',
      transliterationLatin:
          data['transliterationLatin'] as String? ??
          data['romanization'] as String? ??
          '',
      exampleWordOlChiki: data['exampleWordOlChiki'] as String?,
      exampleWordLatin: data['exampleWordLatin'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      pronunciation: data['pronunciation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'charOlChiki': charOlChiki,
      'transliterationLatin': transliterationLatin,
      'exampleWordOlChiki': exampleWordOlChiki,
      'exampleWordLatin': exampleWordLatin,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'animationUrl': animationUrl,
      'order': order,
      'isActive': isActive,
      'pronunciation': pronunciation,
    };
  }

  LetterModel copyWith({
    String? id,
    String? charOlChiki,
    String? transliterationLatin,
    String? exampleWordOlChiki,
    String? exampleWordLatin,
    String? imageUrl,
    String? audioUrl,
    String? animationUrl,
    int? order,
    bool? isActive,
    String? pronunciation,
  }) {
    return LetterModel(
      id: id ?? this.id,
      charOlChiki: charOlChiki ?? this.charOlChiki,
      transliterationLatin: transliterationLatin ?? this.transliterationLatin,
      exampleWordOlChiki: exampleWordOlChiki ?? this.exampleWordOlChiki,
      exampleWordLatin: exampleWordLatin ?? this.exampleWordLatin,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      pronunciation: pronunciation ?? this.pronunciation,
    );
  }
}

// ============== NUMBER MODEL ==============
class NumberModel {
  final String id;
  final String numeral; // Ol Chiki numeral: ᱑, ᱒, etc.
  final int value; // Numeric value: 1, 2, etc.
  final String nameOlChiki; // Name in Ol Chiki: ᱢᱤᱛ
  final String nameLatin; // Name in Latin: mit (one)
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
  final String? pronunciation;
  final int order;
  final bool isActive;

  NumberModel({
    required this.id,
    required this.numeral,
    required this.value,
    required this.nameOlChiki,
    required this.nameLatin,
    this.imageUrl,
    this.audioUrl,
    this.animationUrl,
    this.pronunciation,
    this.order = 0,
    this.isActive = true,
  });

  factory NumberModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return NumberModel(
      id: docId ?? data['id'] as String? ?? '',
      numeral: data['numeral'] as String? ?? '',
      value: data['value'] as int? ?? 0,
      nameOlChiki: data['nameOlChiki'] as String? ?? '',
      nameLatin: data['nameLatin'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      pronunciation: data['pronunciation'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numeral': numeral,
      'value': value,
      'nameOlChiki': nameOlChiki,
      'nameLatin': nameLatin,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'animationUrl': animationUrl,
      'pronunciation': pronunciation,
      'order': order,
      'isActive': isActive,
    };
  }
}

// ============== WORD MODEL ==============
class WordModel {
  final String id;
  final String wordOlChiki; // Word in Ol Chiki: ᱡᱚᱦᱟᱨ
  final String wordLatin; // Word in Latin: johar
  final String meaning; // English meaning: hello
  final String? usage; // Usage hint
  final String? category; // greetings, family, etc.
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
  final String? pronunciation;
  final int order;
  final bool isActive;

  WordModel({
    required this.id,
    required this.wordOlChiki,
    required this.wordLatin,
    required this.meaning,
    this.usage,
    this.category,
    this.imageUrl,
    this.audioUrl,
    this.animationUrl,
    this.pronunciation,
    this.order = 0,
    this.isActive = true,
  });

  factory WordModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return WordModel(
      id: docId ?? data['id'] as String? ?? '',
      wordOlChiki: data['wordOlChiki'] as String? ?? '',
      wordLatin: data['wordLatin'] as String? ?? '',
      meaning: data['meaning'] as String? ?? '',
      usage: data['usage'] as String?,
      category: data['category'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      pronunciation: data['pronunciation'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wordOlChiki': wordOlChiki,
      'wordLatin': wordLatin,
      'meaning': meaning,
      'usage': usage,
      'category': category,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'animationUrl': animationUrl,
      'pronunciation': pronunciation,
      'order': order,
      'isActive': isActive,
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
  final String? description;
  final String? audioUrl;
  final bool isPremium;

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
    this.description,
    this.audioUrl,
    this.isPremium = false,
  });

  // Convenience getters for backwards compatibility
  String get titleEn => titleLatin;
  String get titleOl => titleOlChiki;

  factory LessonModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    final blocksData = data['blocks'] as List<dynamic>? ?? [];
    return LessonModel(
      id: docId ?? data['id'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      titleOlChiki:
          data['titleOlChiki'] as String? ?? data['titleOl'] as String? ?? '',
      titleLatin:
          data['titleLatin'] as String? ?? data['titleEn'] as String? ?? '',
      level: data['level'] as String? ?? 'beginner',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      blocks: blocksData
          .map((b) => LessonBlock.fromMap(b as Map<String, dynamic>))
          .toList(),
      estimatedMinutes: data['estimatedMinutes'] as int? ?? 5,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      description: data['description'] as String?,
      audioUrl: data['audioUrl'] as String?,
      isPremium: data['isPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'titleOlChiki': titleOlChiki,
      'titleLatin': titleLatin,
      'level': level,
      'order': order,
      'isActive': isActive,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'estimatedMinutes': estimatedMinutes,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'audioUrl': audioUrl,
      'isPremium': isPremium,
    };
  }

  LessonModel copyWith({
    String? id,
    String? categoryId,
    String? titleOlChiki,
    String? titleLatin,
    String? level,
    int? order,
    bool? isActive,
    List<LessonBlock>? blocks,
    int? estimatedMinutes,
    String? thumbnailUrl,
    String? description,
    bool? isPremium,
  }) {
    return LessonModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      titleOlChiki: titleOlChiki ?? this.titleOlChiki,
      titleLatin: titleLatin ?? this.titleLatin,
      level: level ?? this.level,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      blocks: blocks ?? this.blocks,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

class LessonBlock {
  final String type; // text, image, audio, quiz, video, lottie
  final String? textOlChiki;
  final String? textLatin;
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
  final String? quizRefId;

  LessonBlock({
    required this.type,
    this.textOlChiki,
    this.textLatin,
    this.imageUrl,
    this.audioUrl,
    this.animationUrl,
    this.quizRefId,
  });

  factory LessonBlock.fromMap(Map<String, dynamic> data) {
    // Unwrap nested contentJson from API response
    // API may return: {type, contentJson: {type, contentJson: {textOlChiki, textLatin}}}
    // or: {type, contentJson: {textOlChiki, textLatin}}
    Map<String, dynamic> content = data;
    if (data['contentJson'] is Map<String, dynamic>) {
      content = data['contentJson'] as Map<String, dynamic>;
      // Handle double-nesting
      if (content['contentJson'] is Map<String, dynamic>) {
        content = content['contentJson'] as Map<String, dynamic>;
      }
    }

    return LessonBlock(
      type: data['type'] as String? ?? 'text',
      textOlChiki:
          content['textOlChiki'] as String? ?? data['textOlChiki'] as String?,
      textLatin:
          content['textLatin'] as String? ?? data['textLatin'] as String?,
      imageUrl: content['imageUrl'] as String? ?? data['imageUrl'] as String?,
      audioUrl: content['audioUrl'] as String? ?? data['audioUrl'] as String?,
      animationUrl:
          content['animationUrl'] as String? ?? data['animationUrl'] as String?,
      quizRefId:
          content['quizRefId'] as String? ?? data['quizRefId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'textOlChiki': textOlChiki,
      'textLatin': textLatin,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'animationUrl': animationUrl,
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

  factory QuizModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    final questionsData = data['questions'] as List<dynamic>? ?? [];
    return QuizModel(
      id: docId ?? data['id'] as String? ?? '',
      categoryId: data['categoryId'] as String?,
      level: data['level'] as String? ?? 'beginner',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      questions: questionsData
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
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

  factory StickerModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return StickerModel(
      id: docId ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      category: data['category'] as String?,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
    };
  }
}

// ============== SENTENCE MODEL ==============
class SentenceModel {
  final String id;
  final String sentenceOlChiki;
  final String sentenceLatin;
  final String meaning;
  final String? usage;
  final String? category;
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
  final String? pronunciation;
  final int order;
  final bool isActive;

  SentenceModel({
    required this.id,
    required this.sentenceOlChiki,
    required this.sentenceLatin,
    required this.meaning,
    this.usage,
    this.category,
    this.imageUrl,
    this.audioUrl,
    this.animationUrl,
    this.pronunciation,
    this.order = 0,
    this.isActive = true,
  });

  factory SentenceModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return SentenceModel(
      id: docId ?? data['id'] as String? ?? '',
      sentenceOlChiki: data['sentenceOlChiki'] as String? ?? '',
      sentenceLatin: data['sentenceLatin'] as String? ?? '',
      meaning: data['meaning'] as String? ?? '',
      usage: data['usage'] as String?,
      category: data['category'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      pronunciation: data['pronunciation'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sentenceOlChiki': sentenceOlChiki,
      'sentenceLatin': sentenceLatin,
      'meaning': meaning,
      'usage': usage,
      'category': category,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'animationUrl': animationUrl,
      'pronunciation': pronunciation,
      'order': order,
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

  factory UserProgressModel.fromJson(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return UserProgressModel(
      categoryId: docId ?? data['categoryId'] as String? ?? '',
      percent: (data['percent'] as num?)?.toDouble() ?? 0,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
      completedLessons: data['completedLessons'] as int? ?? 0,
      totalLessons: data['totalLessons'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'percent': percent,
      'updatedAt': updatedAt.toIso8601String(),
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
    };
  }
}

// ============== MEDIA FILE MODEL ==============
class MediaFileModel {
  final String id;
  final String name;
  final String url;
  final String type; // image, audio, video
  final int size;
  final DateTime uploadedAt;

  MediaFileModel({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.size = 0,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  factory MediaFileModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return MediaFileModel(
      id: docId ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      url: data['url'] as String? ?? '',
      type: data['type'] as String? ?? 'image',
      size: data['size'] as int? ?? 0,
      uploadedAt: data['uploadedAt'] != null
          ? DateTime.parse(data['uploadedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
