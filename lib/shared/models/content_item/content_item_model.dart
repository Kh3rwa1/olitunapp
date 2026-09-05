import 'package:equatable/equatable.dart';

import 'content_block.dart';
import 'content_enums.dart';
import 'content_item_serialization.dart';
import 'content_media.dart';
import 'tracing_models.dart';

class ContentItem extends Equatable {
  final String id;
  final ContentKind kind;
  final String categoryId;
  final String title;
  final String? titleOlChiki;
  final String? subtitle;
  final String? olChiki;
  final ContentMedia? heroMedia;
  final List<ContentBlock> blocks;
  final TracingConfig? tracing;
  final int order;
  final bool isPublished;
  final bool isPremium;
  final List<String> tags;
  final String? difficulty;
  final int? durationSeconds;
  final DateTime updatedAt;
  final String? audioUrl;
  final String? audioFileId;
  final int? durationMs;
  final String? category;
  final String? coverMediaType;

  const ContentItem({
    required this.id,
    required this.kind,
    required this.categoryId,
    required this.title,
    this.titleOlChiki,
    this.subtitle,
    this.olChiki,
    this.heroMedia,
    this.coverMediaType,
    required this.blocks,
    this.tracing,
    this.order = 0,
    this.isPublished = false,
    this.isPremium = false,
    this.tags = const [],
    this.difficulty,
    this.durationSeconds,
    required this.updatedAt,
    this.audioUrl,
    this.audioFileId,
    this.durationMs,
    this.category,
  }) : assert(
         coverMediaType == null ||
             coverMediaType == 'image' ||
             coverMediaType == 'video',
         'Invalid coverMediaType: $coverMediaType',
       );

  factory ContentItem.empty({required String id, required ContentKind kind}) {
    return ContentItem(
      id: id,
      kind: kind,
      categoryId: '',
      title: '',
      blocks: const [],
      updatedAt: DateTime.now(),
    );
  }

  static void validate(ContentKind kind, TracingConfig? tracing) {
    if ((kind == ContentKind.letter || kind == ContentKind.number) &&
        tracing == null) {
      throw const ContentValidationException(
        'Tracing config is required for letter and number content. '
        'Provide strokes in admin form or run the tracing template generator.',
      );
    }
  }

  String? get effectiveAudioUrl {
    if (audioUrl != null && audioUrl!.isNotEmpty) {
      return audioUrl;
    }
    return _extractAudioFromBlocks(blocks);
  }

  static String? _extractAudioFromBlocks(List<ContentBlock> blocksList) {
    for (final block in blocksList) {
      if (block.type == 'audio' && block is AudioBlock) {
        return block.media.url;
      }
      if (block.type == 'glyph' && block is GlyphBlock) {
        if (block.audioUrl != null && block.audioUrl!.isNotEmpty) {
          return block.audioUrl;
        }
      }
    }
    return null;
  }

  factory ContentItem.fromJson(
    Map<String, dynamic> json, [
    String? docId,
    ContentKind? expectedKind,
  ]) => ContentItemSerialization.fromJson(json, docId, expectedKind);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'categoryId': categoryId,
      'title': title,
      if (titleOlChiki != null) 'titleOlChiki': titleOlChiki,
      if (subtitle != null) 'subtitle': subtitle,
      if (olChiki != null) 'olChiki': olChiki,
      if (heroMedia != null) 'heroMedia': heroMedia!.toJson(),
      if (coverMediaType != null) 'coverMediaType': coverMediaType,
      'blocks': blocks.map((e) => e.toJson()).toList(),
      if (tracing != null) 'tracing': tracing!.toJson(),
      'order': order,
      'isPublished': isPublished,
      'isPremium': isPremium,
      'tags': tags,
      if (difficulty != null) 'difficulty': difficulty,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'updatedAt': updatedAt.toIso8601String(),
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (audioFileId != null) 'audioFileId': audioFileId,
      if (durationMs != null) 'durationMs': durationMs,
      if (category != null) 'category': category,
    };
  }

  /// Direct Appwrite attribute serialization without publication boundary checks.
  Map<String, dynamic> toAppwriteAttributes() =>
      ContentItemSerialization.toAppwrite(this);

  /// Serializes content for legacy generic upsert paths.
  ///
  /// Those paths create documents with anonymous read permission and cannot
  /// resolve category entitlement policy. Refuse lesson and explicitly premium
  /// writes here so a future call site cannot accidentally publish paid bodies.
  /// Lessons must use the category-aware lesson publisher.
  Map<String, dynamic> toAppwrite() {
    if (kind == ContentKind.lesson) {
      throw StateError(
        'Lesson publication requires the category-aware lesson publisher.',
      );
    }
    if (isPremium) {
      throw StateError(
        'Premium content cannot use the anonymous generic publication path.',
      );
    }
    return toAppwriteAttributes();
  }

  ContentItem copyWith({
    String? id,
    ContentKind? kind,
    String? categoryId,
    String? title,
    String? titleOlChiki,
    String? subtitle,
    String? olChiki,
    Object? heroMedia = const Object(),
    Object? coverMediaType = const Object(),
    List<ContentBlock>? blocks,
    TracingConfig? tracing,
    int? order,
    bool? isPublished,
    bool? isPremium,
    List<String>? tags,
    String? difficulty,
    int? durationSeconds,
    DateTime? updatedAt,
    String? audioUrl,
    String? audioFileId,
    int? durationMs,
    Object? category = const Object(),
  }) {
    return ContentItem(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      titleOlChiki: titleOlChiki ?? this.titleOlChiki,
      subtitle: subtitle ?? this.subtitle,
      olChiki: olChiki ?? this.olChiki,
      heroMedia: heroMedia == const Object()
          ? this.heroMedia
          : (heroMedia as ContentMedia?),
      coverMediaType: coverMediaType == const Object()
          ? this.coverMediaType
          : (coverMediaType as String?),
      blocks: blocks ?? this.blocks,
      tracing: tracing ?? this.tracing,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
      isPremium: isPremium ?? this.isPremium,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
      audioUrl: audioUrl ?? this.audioUrl,
      audioFileId: audioFileId ?? this.audioFileId,
      durationMs: durationMs ?? this.durationMs,
      category: category == const Object()
          ? this.category
          : (category as String?),
    );
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    categoryId,
    title,
    titleOlChiki,
    subtitle,
    olChiki,
    heroMedia,
    coverMediaType,
    blocks,
    tracing,
    order,
    isPublished,
    isPremium,
    tags,
    difficulty,
    durationSeconds,
    updatedAt,
    audioUrl,
    audioFileId,
    durationMs,
    category,
  ];
}
