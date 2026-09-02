import 'dart:convert';

import 'package:itun/features/content/domain/entities/story_segment_entity.dart';

/// Appwrite document mapper for the `story_segments` collection (spec §13).
///
/// Documents are written by the admin CMS; the learner app only reads them.
/// Malformed rows never crash the player — bad translations/vocab JSON is
/// dropped and the segment still renders with whatever text it has.
class StorySegmentModel {
  final String id;
  final String storyId;
  final int order;
  final String textOlChiki;
  final String? textLatin;
  final Map<String, String> translations;
  final int? startMs;
  final int? endMs;
  final String? imageUrl;
  final List<String> vocabularyRefs;

  const StorySegmentModel({
    required this.id,
    required this.storyId,
    required this.order,
    required this.textOlChiki,
    this.textLatin,
    this.translations = const {},
    this.startMs,
    this.endMs,
    this.imageUrl,
    this.vocabularyRefs = const [],
  });

  factory StorySegmentModel.fromJson(Map<String, dynamic> data, String docId) {
    return StorySegmentModel(
      id: docId,
      storyId: data['storyId'] as String? ?? '',
      order: _readInt(data['order']),
      textOlChiki: data['textOlChiki'] as String? ?? '',
      textLatin: _readNullableString(data['textLatin']),
      translations: _readTranslations(data['translations']),
      startMs: _readOptionalInt(data['startMs']),
      endMs: _readOptionalInt(data['endMs']),
      imageUrl: _readNullableString(data['imageUrl']),
      vocabularyRefs: _readVocabularyRefs(data['vocabularyRefs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'order': order,
      'textOlChiki': textOlChiki,
      'textLatin': textLatin,
      'translations': jsonEncode(translations),
      'startMs': startMs,
      'endMs': endMs,
      'imageUrl': imageUrl,
      'vocabularyRefs': jsonEncode(vocabularyRefs),
    };
  }

  StorySegment toEntity() {
    return StorySegment(
      id: id,
      storyId: storyId,
      order: order,
      textOlChiki: textOlChiki,
      textLatin: textLatin,
      translations: translations,
      startMs: startMs,
      endMs: endMs,
      imageUrl: imageUrl,
      vocabularyRefs: vocabularyRefs,
    );
  }

  factory StorySegmentModel.fromEntity(StorySegment segment) {
    return StorySegmentModel(
      id: segment.id,
      storyId: segment.storyId,
      order: segment.order,
      textOlChiki: segment.textOlChiki,
      textLatin: segment.textLatin,
      translations: segment.translations,
      startMs: segment.startMs,
      endMs: segment.endMs,
      imageUrl: segment.imageUrl,
      vocabularyRefs: segment.vocabularyRefs,
    );
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readOptionalInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  /// `translations` is stored as a JSON object string keyed by language code.
  static Map<String, String> _readTranslations(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k.trim(), v?.toString() ?? ''))
        ..removeWhere((k, v) => k.isEmpty || v.trim().isEmpty);
    }
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map(
        (k, v) => MapEntry(k.toString().trim(), v?.toString() ?? ''),
      )..removeWhere((k, v) => k.isEmpty || v.trim().isEmpty);
    } catch (_) {
      // Malformed translations JSON — the segment renders without them
      // (see class doc: malformed rows never crash the player).
      return const {};
    }
  }

  /// `vocabularyRefs` is stored as a JSON array of content IDs.
  static List<String> _readVocabularyRefs(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      // Malformed vocabulary JSON — the segment renders without refs
      // (see class doc: malformed rows never crash the player).
      return const [];
    }
  }
}
