import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:itun/core/error/failures.dart';

// Exceptions
class ContentValidationException implements Exception {
  final String message;
  const ContentValidationException(this.message);

  @override
  String toString() => 'ContentValidationException: $message';
}

class TracingRequiredFailure extends ValidationFailure {
  const TracingRequiredFailure({required super.message, super.fieldErrors});
}

// ContentKind
enum ContentKind {
  letter,
  number,
  word,
  sentence,
  lesson,
  rhyme;

  static ContentKind fromString(String val) {
    return ContentKind.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid ContentKind: $val'),
    );
  }
}

// ContentMediaKind
enum ContentMediaKind {
  image,
  video,
  audio,
  lottie,
  svg;

  static ContentMediaKind fromString(String val) {
    return ContentMediaKind.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid ContentMediaKind: $val'),
    );
  }
}

// CalloutVariant
enum CalloutVariant {
  tip,
  warning,
  note,
  success;

  static CalloutVariant fromString(String val) {
    return CalloutVariant.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => CalloutVariant.note,
    );
  }
}

// TracingGuide
enum TracingGuide {
  dotted,
  ghost,
  arrows,
  none;

  static TracingGuide fromString(String val) {
    return TracingGuide.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => TracingGuide.dotted,
    );
  }
}

// TracingDirection
enum TracingDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  clockwise,
  counterClockwise,
  custom;

  static TracingDirection fromString(String val) {
    return TracingDirection.values.firstWhere(
      (e) => e.name == val,
      orElse: () => TracingDirection.custom,
    );
  }
}

// ContentMedia
class ContentMedia extends Equatable {
  final String url;
  final String fileId;
  final ContentMediaKind kind;
  final String? caption;
  final int? durationSeconds;
  final String? posterUrl;

  const ContentMedia({
    required this.url,
    required this.fileId,
    required this.kind,
    this.caption,
    this.durationSeconds,
    this.posterUrl,
  });

  factory ContentMedia.fromJson(Map<String, dynamic> json) {
    return ContentMedia(
      url: json['url'] as String? ?? '',
      fileId: json['fileId'] as String? ?? json['file_id'] as String? ?? '',
      kind: ContentMediaKind.fromString(json['kind'] as String? ?? 'image'),
      caption: json['caption'] as String?,
      durationSeconds:
          json['durationSeconds'] as int? ?? json['duration_seconds'] as int?,
      posterUrl: json['posterUrl'] as String? ?? json['poster_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'fileId': fileId,
      'kind': kind.name,
      if (caption != null) 'caption': caption,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (posterUrl != null) 'posterUrl': posterUrl,
    };
  }

  ContentMedia copyWith({
    String? url,
    String? fileId,
    ContentMediaKind? kind,
    String? caption,
    int? durationSeconds,
    String? posterUrl,
  }) {
    return ContentMedia(
      url: url ?? this.url,
      fileId: fileId ?? this.fileId,
      kind: kind ?? this.kind,
      caption: caption ?? this.caption,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      posterUrl: posterUrl ?? this.posterUrl,
    );
  }

  @override
  List<Object?> get props => [
    url,
    fileId,
    kind,
    caption,
    durationSeconds,
    posterUrl,
  ];
}

// TracingPoint
class TracingPoint extends Equatable {
  final double x;
  final double y;
  final bool isControlPoint;

  const TracingPoint({
    required this.x,
    required this.y,
    this.isControlPoint = false,
  });

  factory TracingPoint.fromJson(Map<String, dynamic> json) {
    return TracingPoint(
      x: (json['x'] as num? ?? 0.0).toDouble(),
      y: (json['y'] as num? ?? 0.0).toDouble(),
      isControlPoint:
          json['isControlPoint'] as bool? ??
          json['is_control_point'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'isControlPoint': isControlPoint};
  }

  @override
  List<Object?> get props => [x, y, isControlPoint];
}

// TracingStroke
class TracingStroke extends Equatable {
  final String id;
  final int order;
  final List<TracingPoint> path;
  final TracingDirection direction;
  final String? hintText;

  const TracingStroke({
    required this.id,
    required this.order,
    required this.path,
    this.direction = TracingDirection.custom,
    this.hintText,
  });

  factory TracingStroke.fromJson(Map<String, dynamic> json) {
    return TracingStroke(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      path:
          (json['path'] as List<dynamic>?)
              ?.map((e) => TracingPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      direction: TracingDirection.fromString(
        json['direction'] as String? ?? 'custom',
      ),
      hintText: json['hintText'] as String? ?? json['hint_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'path': path.map((e) => e.toJson()).toList(),
      'direction': direction.name,
      if (hintText != null) 'hintText': hintText,
    };
  }

  @override
  List<Object?> get props => [id, order, path, direction, hintText];
}

// TracingConfig
class TracingConfig extends Equatable {
  final String glyph;
  final List<TracingStroke> strokes;
  final TracingGuide guide;
  final double strokeWidth;
  final double tolerance;
  final bool showDirectionArrows;
  final bool playAudioOnComplete;
  final String? audioOnCompleteUrl;
  final int requiredCompletions;

  const TracingConfig({
    required this.glyph,
    required this.strokes,
    this.guide = TracingGuide.dotted,
    this.strokeWidth = 12.0,
    this.tolerance = 0.6,
    this.showDirectionArrows = true,
    this.playAudioOnComplete = true,
    this.audioOnCompleteUrl,
    this.requiredCompletions = 1,
  });

  factory TracingConfig.fromJson(Map<String, dynamic> json) {
    return TracingConfig(
      glyph: json['glyph'] as String? ?? '',
      strokes:
          (json['strokes'] as List<dynamic>?)
              ?.map((e) => TracingStroke.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      guide: TracingGuide.fromString(json['guide'] as String? ?? 'dotted'),
      strokeWidth:
          (json['strokeWidth'] as num? ?? json['stroke_width'] as num? ?? 12.0)
              .toDouble(),
      tolerance: (json['tolerance'] as num? ?? json['tolerance'] as num? ?? 0.6)
          .toDouble(),
      showDirectionArrows:
          json['showDirectionArrows'] as bool? ??
          json['show_direction_arrows'] as bool? ??
          true,
      playAudioOnComplete:
          json['playAudioOnComplete'] as bool? ??
          json['play_audio_on_complete'] as bool? ??
          true,
      audioOnCompleteUrl:
          json['audioOnCompleteUrl'] as String? ??
          json['audio_on_complete_url'] as String?,
      requiredCompletions:
          json['requiredCompletions'] as int? ??
          json['required_completions'] as int? ??
          1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'glyph': glyph,
      'strokes': strokes.map((e) => e.toJson()).toList(),
      'guide': guide.name,
      'strokeWidth': strokeWidth,
      'tolerance': tolerance,
      'showDirectionArrows': showDirectionArrows,
      'playAudioOnComplete': playAudioOnComplete,
      if (audioOnCompleteUrl != null) 'audioOnCompleteUrl': audioOnCompleteUrl,
      'requiredCompletions': requiredCompletions,
    };
  }

  @override
  List<Object?> get props => [
    glyph,
    strokes,
    guide,
    strokeWidth,
    tolerance,
    showDirectionArrows,
    playAudioOnComplete,
    audioOnCompleteUrl,
    requiredCompletions,
  ];
}

// Sealed ContentBlock hierarchy
sealed class ContentBlock extends Equatable {
  final String id;
  final int order;
  final String type;

  const ContentBlock({
    required this.id,
    required this.order,
    required this.type,
  });

  @override
  List<Object?> get props => [id, order, type];

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'text';
    switch (type) {
      case 'text':
        return TextBlock.fromJson(json);
      case 'image':
        return ImageBlock.fromJson(json);
      case 'video':
        return VideoBlock.fromJson(json);
      case 'audio':
        return AudioBlock.fromJson(json);
      case 'lottie':
        return LottieBlock.fromJson(json);
      case 'quiz':
        return QuizBlock.fromJson(json);
      case 'glyph':
        return GlyphBlock.fromJson(json);
      case 'callout':
        return CalloutBlock.fromJson(json);
      case 'tracing':
        return TracingBlock.fromJson(json);
      default:
        throw Exception('Unknown ContentBlock type: $type');
    }
  }

  Map<String, dynamic> toJson();
}

class TextBlock extends ContentBlock {
  final String markdown;

  const TextBlock({
    required super.id,
    required super.order,
    required this.markdown,
  }) : super(type: 'text');

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      markdown: json['markdown'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'order': order, 'type': 'text', 'markdown': markdown};
  }

  @override
  List<Object?> get props => [...super.props, markdown];
}

class ImageBlock extends ContentBlock {
  final ContentMedia media;
  final String? caption;

  const ImageBlock({
    required super.id,
    required super.order,
    required this.media,
    this.caption,
  }) : super(type: 'image');

  factory ImageBlock.fromJson(Map<String, dynamic> json) {
    return ImageBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      media: ContentMedia.fromJson(
        json['media'] as Map<String, dynamic>? ?? const {},
      ),
      caption: json['caption'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'image',
      'media': media.toJson(),
      if (caption != null) 'caption': caption,
    };
  }

  @override
  List<Object?> get props => [...super.props, media, caption];
}

class VideoBlock extends ContentBlock {
  final ContentMedia media;
  final String? posterUrl;
  final int? durationSeconds;
  final bool autoplay;

  const VideoBlock({
    required super.id,
    required super.order,
    required this.media,
    this.posterUrl,
    this.durationSeconds,
    this.autoplay = false,
  }) : super(type: 'video');

  factory VideoBlock.fromJson(Map<String, dynamic> json) {
    return VideoBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      media: ContentMedia.fromJson(
        json['media'] as Map<String, dynamic>? ?? const {},
      ),
      posterUrl: json['posterUrl'] as String? ?? json['poster_url'] as String?,
      durationSeconds:
          json['durationSeconds'] as int? ?? json['duration_seconds'] as int?,
      autoplay: json['autoplay'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'video',
      'media': media.toJson(),
      if (posterUrl != null) 'posterUrl': posterUrl,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'autoplay': autoplay,
    };
  }

  @override
  List<Object?> get props => [
    ...super.props,
    media,
    posterUrl,
    durationSeconds,
    autoplay,
  ];
}

class AudioBlock extends ContentBlock {
  final ContentMedia media;
  final String? transcript;

  const AudioBlock({
    required super.id,
    required super.order,
    required this.media,
    this.transcript,
  }) : super(type: 'audio');

  factory AudioBlock.fromJson(Map<String, dynamic> json) {
    return AudioBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      media: ContentMedia.fromJson(
        json['media'] as Map<String, dynamic>? ?? const {},
      ),
      transcript: json['transcript'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'audio',
      'media': media.toJson(),
      if (transcript != null) 'transcript': transcript,
    };
  }

  @override
  List<Object?> get props => [...super.props, media, transcript];
}

class LottieBlock extends ContentBlock {
  final ContentMedia media;
  final bool loop;

  const LottieBlock({
    required super.id,
    required super.order,
    required this.media,
    this.loop = true,
  }) : super(type: 'lottie');

  factory LottieBlock.fromJson(Map<String, dynamic> json) {
    return LottieBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      media: ContentMedia.fromJson(
        json['media'] as Map<String, dynamic>? ?? const {},
      ),
      loop: json['loop'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'lottie',
      'media': media.toJson(),
      'loop': loop,
    };
  }

  @override
  List<Object?> get props => [...super.props, media, loop];
}

class QuizBlock extends ContentBlock {
  final String quizId;

  const QuizBlock({
    required super.id,
    required super.order,
    required this.quizId,
  }) : super(type: 'quiz');

  factory QuizBlock.fromJson(Map<String, dynamic> json) {
    return QuizBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      quizId: json['quizId'] as String? ?? json['quiz_id'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'order': order, 'type': 'quiz', 'quizId': quizId};
  }

  @override
  List<Object?> get props => [...super.props, quizId];
}

class GlyphBlock extends ContentBlock {
  final String olChiki;
  final String latin;
  final String? audioUrl;

  const GlyphBlock({
    required super.id,
    required super.order,
    required this.olChiki,
    required this.latin,
    this.audioUrl,
  }) : super(type: 'glyph');

  factory GlyphBlock.fromJson(Map<String, dynamic> json) {
    return GlyphBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      olChiki: json['olChiki'] as String? ?? json['ol_chiki'] as String? ?? '',
      latin: json['latin'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'glyph',
      'olChiki': olChiki,
      'latin': latin,
      if (audioUrl != null) 'audioUrl': audioUrl,
    };
  }

  @override
  List<Object?> get props => [...super.props, olChiki, latin, audioUrl];
}

class CalloutBlock extends ContentBlock {
  final String text;
  final CalloutVariant variant;

  const CalloutBlock({
    required super.id,
    required super.order,
    required this.text,
    required this.variant,
  }) : super(type: 'callout');

  factory CalloutBlock.fromJson(Map<String, dynamic> json) {
    return CalloutBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      variant: CalloutVariant.fromString(json['variant'] as String? ?? 'note'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'callout',
      'text': text,
      'variant': variant.name,
    };
  }

  @override
  List<Object?> get props => [...super.props, text, variant];
}

class TracingBlock extends ContentBlock {
  final TracingConfig config;

  const TracingBlock({
    required super.id,
    required super.order,
    required this.config,
  }) : super(type: 'tracing');

  factory TracingBlock.fromJson(Map<String, dynamic> json) {
    return TracingBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      config: TracingConfig.fromJson(
        json['config'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'tracing',
      'config': config.toJson(),
    };
  }

  @override
  List<Object?> get props => [...super.props, config];
}

// ContentItem
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

  const ContentItem({
    required this.id,
    required this.kind,
    required this.categoryId,
    required this.title,
    this.titleOlChiki,
    this.subtitle,
    this.olChiki,
    this.heroMedia,
    required this.blocks,
    this.tracing,
    this.order = 0,
    this.isPublished = false,
    this.isPremium = false,
    this.tags = const [],
    this.difficulty,
    this.durationSeconds,
    required this.updatedAt,
  });

  static void validate(ContentKind kind, TracingConfig? tracing) {
    if ((kind == ContentKind.letter || kind == ContentKind.number) &&
        tracing == null) {
      throw const ContentValidationException(
        'Tracing config is required for letter and number content. '
        'Provide strokes in admin form or run the tracing template generator.',
      );
    }
  }

  factory ContentItem.fromJson(Map<String, dynamic> json, [String? docId]) {
    final rawKind = json['kind'] as String? ?? 'lesson';
    final parsedKind = ContentKind.fromString(rawKind);

    final rawTracing = json['tracing'];
    TracingConfig? parsedTracing;
    if (rawTracing != null) {
      if (rawTracing is String) {
        if (rawTracing.isNotEmpty) {
          try {
            parsedTracing = TracingConfig.fromJson(
              jsonDecode(rawTracing) as Map<String, dynamic>,
            );
          } catch (_) {}
        }
      } else if (rawTracing is Map<String, dynamic>) {
        parsedTracing = TracingConfig.fromJson(rawTracing);
      }
    }

    validate(parsedKind, parsedTracing);

    final rawHeroMedia = json['hero_media'] ?? json['heroMedia'];
    ContentMedia? parsedHeroMedia;
    if (rawHeroMedia != null) {
      if (rawHeroMedia is String) {
        if (rawHeroMedia.isNotEmpty) {
          try {
            parsedHeroMedia = ContentMedia.fromJson(
              jsonDecode(rawHeroMedia) as Map<String, dynamic>,
            );
          } catch (_) {}
        }
      } else if (rawHeroMedia is Map<String, dynamic>) {
        parsedHeroMedia = ContentMedia.fromJson(rawHeroMedia);
      }
    }

    final rawBlocks = json['blocks'];
    List<ContentBlock> parsedBlocks = const [];
    if (rawBlocks != null) {
      if (rawBlocks is String) {
        if (rawBlocks.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawBlocks) as List<dynamic>;
            parsedBlocks = decoded
                .map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        }
      } else if (rawBlocks is List<dynamic>) {
        parsedBlocks = rawBlocks
            .map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    final rawUpdatedAt = json['updatedAt'] ?? json['updated_at'];
    DateTime parsedUpdatedAt = DateTime.now();
    if (rawUpdatedAt != null) {
      if (rawUpdatedAt is String) {
        parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt) ?? DateTime.now();
      } else if (rawUpdatedAt is int) {
        parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt);
      }
    }

    final rawTags = json['tags'];
    List<String> parsedTags = const [];
    if (rawTags != null) {
      if (rawTags is List<dynamic>) {
        parsedTags = rawTags.map((e) => e.toString()).toList();
      } else if (rawTags is String) {
        if (rawTags.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawTags) as List<dynamic>;
            parsedTags = decoded.map((e) => e.toString()).toList();
          } catch (_) {
            parsedTags = rawTags
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        }
      }
    }

    return ContentItem(
      id: docId ?? json['\$id'] as String? ?? json['id'] as String? ?? '',
      kind: parsedKind,
      categoryId:
          json['category_id'] as String? ?? json['categoryId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleOlChiki:
          json['title_ol_chiki'] as String? ?? json['titleOlChiki'] as String?,
      subtitle: json['subtitle'] as String?,
      olChiki: json['ol_chiki'] as String? ?? json['olChiki'] as String?,
      heroMedia: parsedHeroMedia,
      blocks: parsedBlocks,
      tracing: parsedTracing,
      order: json['order'] as int? ?? 0,
      isPublished:
          json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isPremium:
          json['is_premium'] as bool? ?? json['isPremium'] as bool? ?? false,
      tags: parsedTags,
      difficulty: json['difficulty'] as String?,
      durationSeconds:
          json['duration_seconds'] as int? ?? json['durationSeconds'] as int?,
      updatedAt: parsedUpdatedAt,
    );
  }

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
      'blocks': blocks.map((e) => e.toJson()).toList(),
      if (tracing != null) 'tracing': tracing!.toJson(),
      'order': order,
      'isPublished': isPublished,
      'isPremium': isPremium,
      'tags': tags,
      if (difficulty != null) 'difficulty': difficulty,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toAppwrite() {
    assert(
      categoryId.isNotEmpty,
      'ContentItem.toAppwrite(): categoryId must not be empty (kind=$kind, id=$id)',
    );
    return {
      'kind': kind.name,
      'category_id': categoryId,
      'title': title,
      'title_ol_chiki': titleOlChiki,
      'subtitle': subtitle,
      'ol_chiki': olChiki,
      'hero_media': heroMedia != null ? jsonEncode(heroMedia!.toJson()) : null,
      'blocks': jsonEncode(blocks.map((e) => e.toJson()).toList()),
      'tracing': tracing != null ? jsonEncode(tracing!.toJson()) : null,
      'order': order,
      'is_published': isPublished,
      'is_premium': isPremium,
      'tags': tags,
      'difficulty': difficulty,
      'duration_seconds': durationSeconds,
    };
  }

  ContentItem copyWith({
    String? id,
    ContentKind? kind,
    String? categoryId,
    String? title,
    String? titleOlChiki,
    String? subtitle,
    String? olChiki,
    ContentMedia? heroMedia,
    List<ContentBlock>? blocks,
    TracingConfig? tracing,
    int? order,
    bool? isPublished,
    bool? isPremium,
    List<String>? tags,
    String? difficulty,
    int? durationSeconds,
    DateTime? updatedAt,
  }) {
    return ContentItem(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      titleOlChiki: titleOlChiki ?? this.titleOlChiki,
      subtitle: subtitle ?? this.subtitle,
      olChiki: olChiki ?? this.olChiki,
      heroMedia: heroMedia ?? this.heroMedia,
      blocks: blocks ?? this.blocks,
      tracing: tracing ?? this.tracing,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
      isPremium: isPremium ?? this.isPremium,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
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
    blocks,
    tracing,
    order,
    isPublished,
    isPremium,
    tags,
    difficulty,
    durationSeconds,
    updatedAt,
  ];
}
