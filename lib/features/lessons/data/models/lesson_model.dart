import 'dart:convert';
import '../../domain/entities/lesson_entity.dart';

class LessonModel extends LessonEntity {
  const LessonModel({
    required super.id,
    required super.categoryId,
    required super.titleOlChiki,
    required super.titleLatin,
    super.description,
    super.order = 0,
    super.estimatedMinutes = 5,
    super.isActive = true,
    super.data,
    required List<LessonBlockModel> super.blocks,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final dynamic rawBlocks = json['blocks'];
    List<dynamic> blocksJson = [];
    if (rawBlocks is String && rawBlocks.isNotEmpty) {
      blocksJson = jsonDecode(rawBlocks);
    } else if (rawBlocks is List) {
      blocksJson = rawBlocks;
    }

    final resolvedId = docId ?? json['id'] as String? ?? json['\$id'] as String? ?? '';
    return LessonModel(
      id: resolvedId,
      categoryId: json['categoryId'] as String? ?? '',
      titleOlChiki: json['titleOlChiki'] as String? ?? '',
      titleLatin: json['titleLatin'] as String? ?? '',
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
      isActive: json['isActive'] as bool? ?? true,
      data: json['data'] as Map<String, dynamic>?,
      blocks: blocksJson.map((e) => LessonBlockModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'titleOlChiki': titleOlChiki,
      'titleLatin': titleLatin,
      'description': description,
      'order': order,
      'estimatedMinutes': estimatedMinutes,
      'isActive': isActive,
      'data': data,
      'blocks': blocks.map((e) => LessonBlockModel.fromEntity(e).toJson()).toList(),
    };
  }

  LessonEntity toEntity() {
    return LessonEntity(
      id: id,
      categoryId: categoryId,
      titleOlChiki: titleOlChiki,
      titleLatin: titleLatin,
      description: description,
      order: order,
      estimatedMinutes: estimatedMinutes,
      isActive: isActive,
      data: data,
      blocks: blocks.map((e) => (e as LessonBlockModel).toEntity()).toList(),
    );
  }

  factory LessonModel.fromEntity(LessonEntity entity) {
    return LessonModel(
      id: entity.id,
      categoryId: entity.categoryId,
      titleOlChiki: entity.titleOlChiki,
      titleLatin: entity.titleLatin,
      description: entity.description,
      order: entity.order,
      estimatedMinutes: entity.estimatedMinutes,
      isActive: entity.isActive,
      data: entity.data,
      blocks: entity.blocks.map(LessonBlockModel.fromEntity).toList(),
    );
  }
}

class LessonBlockModel extends LessonBlockEntity {
  const LessonBlockModel({
    required super.type,
    super.textOlChiki,
    super.textLatin,
    super.imageUrl,
    super.audioUrl,
    super.data,
  });

  factory LessonBlockModel.fromJson(Map<String, dynamic> json) {
    return LessonBlockModel(
      type: json['type'] as String? ?? 'text',
      textOlChiki: json['textOlChiki'] as String?,
      textLatin: json['textLatin'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'textOlChiki': textOlChiki,
      'textLatin': textLatin,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'data': data,
    };
  }

  LessonBlockEntity toEntity() {
    return LessonBlockEntity(
      type: type,
      textOlChiki: textOlChiki,
      textLatin: textLatin,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      data: data,
    );
  }

  factory LessonBlockModel.fromEntity(LessonBlockEntity entity) {
    return LessonBlockModel(
      type: entity.type,
      textOlChiki: entity.textOlChiki,
      textLatin: entity.textLatin,
      imageUrl: entity.imageUrl,
      audioUrl: entity.audioUrl,
      data: entity.data,
    );
  }
}
