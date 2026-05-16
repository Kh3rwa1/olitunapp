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
    String? audioUrl,
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
      audioUrl: audioUrl ?? this.audioUrl,
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
