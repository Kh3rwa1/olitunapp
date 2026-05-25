import 'dart:convert';
import '../../domain/entities/lesson_entity.dart';

class LessonModel extends LessonEntity {
  const LessonModel({
    required super.id,
    required super.categoryId,
    required super.titleOlChiki,
    required super.titleLatin,
    super.level = 'beginner',
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
      final decoded = jsonDecode(rawBlocks);
      if (decoded is List) blocksJson = decoded;
    } else if (rawBlocks is List) {
      blocksJson = rawBlocks;
    }

    final resolvedId =
        docId ?? json['id'] as String? ?? json['\$id'] as String? ?? '';

    // Retrieve root media fields and inject them into the data map
    // to preserve compatibility with existing UI components
    final thumbnailUrl = json['thumbnailUrl'] as String?;
    final heroMediaUrl = json['heroMediaUrl'] as String?;
    final heroMediaType = json['heroMediaType'] as String?;
    final heroPosterUrl = json['heroPosterUrl'] as String?;
    final rawData = json['data'];
    Map<String, dynamic> parsedData = {};
    if (rawData is Map) {
      parsedData = rawData.cast<String, dynamic>();
    } else if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) parsedData = decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      parsedData['thumbnailUrl'] = thumbnailUrl;
    }
    if (heroMediaUrl != null && heroMediaUrl.isNotEmpty) {
      parsedData['heroMediaUrl'] = heroMediaUrl;
    }
    if (heroMediaType != null && heroMediaType.isNotEmpty) {
      parsedData['heroMediaType'] = heroMediaType;
    }
    if (heroPosterUrl != null && heroPosterUrl.isNotEmpty) {
      parsedData['heroPosterUrl'] = heroPosterUrl;
    }

    final rawCategoryId = json['categoryId'] ?? json['category_id'];
    String parsedCategoryId = '';
    if (rawCategoryId is String) {
      parsedCategoryId = rawCategoryId;
    } else if (rawCategoryId is Map) {
      parsedCategoryId =
          (rawCategoryId['\$id'] ?? rawCategoryId['id'] ?? '') as String;
    }

    return LessonModel(
      id: resolvedId,
      categoryId: parsedCategoryId,
      titleOlChiki: json['titleOlChiki'] as String? ?? '',
      titleLatin: json['titleLatin'] as String? ?? '',
      level: json['level'] as String? ?? 'beginner',
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
      isActive: json['isActive'] as bool? ?? true,
      data: parsedData.isEmpty ? null : parsedData,
      blocks: blocksJson
          .whereType<Map>()
          .map((e) => LessonBlockModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'titleOlChiki': titleOlChiki,
      'titleLatin': titleLatin,
      'level': level,
      'description': description,
      'order': order,
      'estimatedMinutes': estimatedMinutes,
      'isActive': isActive,
      'thumbnailUrl': data?['thumbnailUrl'],
      'heroMediaUrl': data?['heroMediaUrl'],
      'heroMediaType': data?['heroMediaType'],
      'heroPosterUrl': data?['heroPosterUrl'],
      'blocks': blocks
          .map((e) => LessonBlockModel.fromEntity(e).toJson())
          .toList(),
    };
  }

  LessonEntity toEntity() {
    return LessonEntity(
      id: id,
      categoryId: categoryId,
      titleOlChiki: titleOlChiki,
      titleLatin: titleLatin,
      level: level,
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
      level: entity.level,
      description: entity.description,
      order: entity.order,
      estimatedMinutes: entity.estimatedMinutes,
      isActive: entity.isActive,
      data: entity.data,
      blocks: entity.blocks.map(LessonBlockModel.fromEntity).toList(),
    );
  }
}

Map<String, dynamic>? _parseData(dynamic rawData) {
  if (rawData is Map) return rawData.cast<String, dynamic>();
  if (rawData is String && rawData.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
  }
  return null;
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
    final parsedData = _parseData(json['data']);

    return LessonBlockModel(
      type: json['type'] as String? ?? 'text',
      textOlChiki: json['textOlChiki'] as String?,
      textLatin: json['textLatin'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      data: parsedData,
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
