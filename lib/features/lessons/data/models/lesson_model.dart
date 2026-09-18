import 'dart:convert';

import 'package:itun/core/logging/app_logger.dart';

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
    super.isPreview = false,
    super.isLocked = false,
    super.data,
    required List<LessonBlockModel> super.blocks,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final dynamic rawBlocks = json['blocks'];
    List<dynamic> blocksJson = [];
    if (rawBlocks is String && rawBlocks.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBlocks);
        if (decoded is List) blocksJson = decoded;
      } catch (e) {
        // Malformed blocks payload: fail closed with zero blocks so quiz
        // generation yields an honest unavailable state instead of crashing
        // or inventing placeholder questions.
        AppLogger.warning('LessonModel: malformed blocks JSON: $e');
        blocksJson = [];
      }
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
      } catch (e) {
        AppLogger.warning('LessonModel: malformed data JSON: $e');
      }
    }
    final rawHeroMedia = json['hero_media'];
    if (rawHeroMedia != null &&
        rawHeroMedia is String &&
        rawHeroMedia.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawHeroMedia);
        if (decoded is Map) {
          parsedData['heroMedia'] = decoded.cast<String, dynamic>();
        }
      } catch (e) {
        AppLogger.warning('LessonModel: malformed hero_media JSON: $e');
      }
    }
    final rawTracing = json['tracing'];
    if (rawTracing != null && rawTracing is String && rawTracing.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTracing);
        if (decoded is Map) {
          parsedData['tracing'] = decoded.cast<String, dynamic>();
        }
      } catch (e) {
        AppLogger.warning('LessonModel: malformed tracing JSON: $e');
      }
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
      isPreview: json['isPreview'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
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
      'isPreview': isPreview,
      'isLocked': isLocked,
      'thumbnailUrl': data?['thumbnailUrl'],
      'heroMediaUrl': data?['heroMediaUrl'],
      'heroMediaType': data?['heroMediaType'],
      'heroPosterUrl': data?['heroPosterUrl'],
      'hero_media': data?['heroMedia'] != null
          ? jsonEncode(data!['heroMedia'])
          : null,
      'tracing': data?['tracing'] != null ? jsonEncode(data!['tracing']) : null,
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
      isPreview: isPreview,
      isLocked: isLocked,
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
      isPreview: entity.isPreview,
      isLocked: entity.isLocked,
      data: entity.data,
      blocks: entity.blocks.map(LessonBlockModel.fromEntity).toList(),
    );
  }
}

Map<String, dynamic>? _parseData(
  dynamic rawData, {
  required bool Function() onMalformed,
}) {
  if (rawData is Map) return rawData.cast<String, dynamic>();
  if (rawData is String && rawData.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map) return decoded.cast<String, dynamic>();
      // A JSON string that decodes to a non-Map is malformed for our purposes.
      onMalformed();
    } catch (e) {
      AppLogger.warning('LessonBlockModel: malformed data JSON: $e');
      onMalformed();
    }
  }
  return null;
}

/// Canonical sentence/word attribution keys. Legacy aliases are copied to
/// these canonical keys (without overwriting an explicit canonical value)
// so generation and mastery tracking read exactly one stable location.
const _sentenceIdAliases = [
  'sourceSentenceId',
  'sentenceId',
  'sourceSentence',
  'sentence_id',
];

const _wordIdAliases = ['sourceWordId', 'wordId', 'sourceWord', 'word_id'];

String? _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

Map<String, dynamic>? _canonicalizeAttribution(Map<String, dynamic>? data) {
  if (data == null) return null;
  final sentenceId = _firstNonEmptyString(data, _sentenceIdAliases);
  final wordId = _firstNonEmptyString(data, _wordIdAliases);
  if (sentenceId == null && wordId == null) return data;
  return {...data, 'sourceSentenceId': ?sentenceId, 'sourceWordId': ?wordId};
}

class LessonBlockModel extends LessonBlockEntity {
  const LessonBlockModel({
    required super.type,
    super.textOlChiki,
    super.textLatin,
    super.textBengali,
    super.textHindi,
    super.textOdia,
    super.imageUrl,
    super.audioUrl,
    super.data,
    super.dataMalformed,
  });

  /// Parses a block, normalizing legacy field aliases explicitly:
  ///
  /// * canonical `textOlChiki` / `textLatin` / `textBengali` / `textHindi` /
  ///   `textOdia`, plus snake_case aliases (`text_ol_chiki`, …);
  /// * production `meta` payloads (meanings and display text stored under
  ///   `meta` instead of `data`): merged underneath explicit values, so an
  ///   explicit `data` entry or canonical field always wins;
  /// * legacy `content` / `text` payloads, used only when neither canonical
  ///   field is present: content containing Ol Chiki codepoints becomes
  ///   `textOlChiki` (never `textLatin` — arbitrary Latin text is not Ol
  ///   Chiki), anything else becomes `textLatin`;
  /// * `data` maps are preserved verbatim with sentence/word attribution
  ///   aliases copied to the canonical `sourceSentenceId` / `sourceWordId`
  ///   keys; a malformed `data` string sets [dataMalformed] instead of
  ///   throwing.
  factory LessonBlockModel.fromJson(Map<String, dynamic> json) {
    var malformedData = json['dataMalformed'] == true;
    final parsedData = _parseData(
      json['data'],
      onMalformed: () => malformedData = true,
    );
    final metaData = json['meta'] is Map
        ? (json['meta'] as Map).cast<String, dynamic>()
        : null;
    final content = json['content'] as String? ?? json['text'] as String?;

    String? pickText(String canonical, String snake, String metaKey) {
      final explicit = json[canonical] as String? ?? json[snake] as String?;
      if (explicit != null && explicit.isNotEmpty) return explicit;
      final fromMeta = metaData?[metaKey] as String?;
      if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
      return explicit;
    }

    final rawOlChiki = pickText('textOlChiki', 'text_ol_chiki', 'textOlChiki');
    final rawLatin = pickText('textLatin', 'text_latin', 'textLatin');
    final rawBengali = pickText('textBengali', 'text_bengali', 'textBengali');
    final rawHindi = pickText('textHindi', 'text_hindi', 'textHindi');
    final rawOdia = pickText('textOdia', 'text_odia', 'textOdia');

    String? resolvedOlChiki = rawOlChiki;
    String? resolvedLatin = rawLatin;

    if ((resolvedOlChiki == null || resolvedOlChiki.isEmpty) &&
        (resolvedLatin == null || resolvedLatin.isEmpty) &&
        content != null &&
        content.trim().isNotEmpty) {
      if (content.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F)) {
        resolvedOlChiki = content;
      } else {
        resolvedLatin = content;
      }
    }

    // Explicit `data` wins over `meta` on conflicts; absent payloads stay
    // null rather than becoming an empty map.
    final mergedPayload = {...?metaData, ...?parsedData};

    return LessonBlockModel(
      type: json['type'] as String? ?? 'text',
      textOlChiki: resolvedOlChiki,
      textLatin: resolvedLatin,
      textBengali: rawBengali,
      textHindi: rawHindi,
      textOdia: rawOdia,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String?,
      data: _canonicalizeAttribution(
        mergedPayload.isEmpty ? null : mergedPayload,
      ),
      dataMalformed: malformedData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'textOlChiki': textOlChiki,
      'textLatin': textLatin,
      'textBengali': textBengali,
      'textHindi': textHindi,
      'textOdia': textOdia,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'data': data,
      if (dataMalformed) 'dataMalformed': true,
    };
  }

  LessonBlockEntity toEntity() {
    return LessonBlockEntity(
      type: type,
      textOlChiki: textOlChiki,
      textLatin: textLatin,
      textBengali: textBengali,
      textHindi: textHindi,
      textOdia: textOdia,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      data: data,
      dataMalformed: dataMalformed,
    );
  }

  factory LessonBlockModel.fromEntity(LessonBlockEntity entity) {
    return LessonBlockModel(
      type: entity.type,
      textOlChiki: entity.textOlChiki,
      textLatin: entity.textLatin,
      textBengali: entity.textBengali,
      textHindi: entity.textHindi,
      textOdia: entity.textOdia,
      imageUrl: entity.imageUrl,
      audioUrl: entity.audioUrl,
      data: entity.data,
      dataMalformed: entity.dataMalformed,
    );
  }
}
