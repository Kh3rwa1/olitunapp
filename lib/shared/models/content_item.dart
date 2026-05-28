import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';

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
  final int? durationMs;
  final String? posterUrl;

  const ContentMedia({
    required this.url,
    required this.fileId,
    required this.kind,
    this.caption,
    this.durationSeconds,
    this.durationMs,
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
      durationMs: json['durationMs'] as int? ?? json['duration_ms'] as int?,
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
      if (durationMs != null) 'durationMs': durationMs,
      if (posterUrl != null) 'posterUrl': posterUrl,
    };
  }

  ContentMedia copyWith({
    String? url,
    String? fileId,
    ContentMediaKind? kind,
    String? caption,
    int? durationSeconds,
    int? durationMs,
    String? posterUrl,
  }) {
    return ContentMedia(
      url: url ?? this.url,
      fileId: fileId ?? this.fileId,
      kind: kind ?? this.kind,
      caption: caption ?? this.caption,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationMs: durationMs ?? this.durationMs,
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
    durationMs,
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
  final Map<String, dynamic> meta; // NEW — admin/editor passthrough

  const ContentBlock({
    required this.id,
    required this.order,
    required this.type,
    this.meta = const {},
  });

  @override
  List<Object?> get props => [id, order, type, meta];

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'text';
    switch (type) {
      case 'text':
        return TextBlock.fromJson(json);
      case 'image':
      case 'svg':
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
        return TextBlock.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

class TextBlock extends ContentBlock {
  final String markdown;
  final String? textOlChiki;
  final String? textLatin;

  const TextBlock({
    required super.id,
    required super.order,
    required this.markdown,
    this.textOlChiki,
    this.textLatin,
    super.meta = const {},
  }) : super(type: 'text');

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      markdown:
          json['markdown'] as String? ??
          json['textLatin'] as String? ??
          json['textOlChiki'] as String? ??
          '',
      textOlChiki: json['textOlChiki'] as String?,
      textLatin: json['textLatin'] as String?,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'text',
      'markdown': markdown,
      if (textOlChiki != null) 'textOlChiki': textOlChiki,
      if (textLatin != null) 'textLatin': textLatin,
      if (meta.isNotEmpty) 'meta': meta,
    };
  }

  @override
  List<Object?> get props => [...super.props, markdown, textOlChiki, textLatin];
}

class ImageBlock extends ContentBlock {
  final ContentMedia media;
  final String? caption;

  const ImageBlock({
    required super.id,
    required super.order,
    required this.media,
    this.caption,
    super.meta = const {},
  }) : super(type: 'image');

  factory ImageBlock.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    ContentMedia parsedMedia;
    if (rawMedia is Map<String, dynamic>) {
      parsedMedia = ContentMedia.fromJson(rawMedia.cast<String, dynamic>());
    } else {
      parsedMedia = ContentMedia(
        url:
            (json['imageUrl'] ?? json['mediaUrl'] ?? json['url'] ?? '')
                as String,
        fileId: '',
        kind: json['type'] == 'svg'
            ? ContentMediaKind.svg
            : ContentMediaKind.image,
      );
    }
    return ImageBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      media: parsedMedia,
      caption: json['caption'] as String? ?? json['textLatin'] as String?,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
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
      if (meta.isNotEmpty) 'meta': meta,
    };
  }

  @override
  List<Object?> get props => [...super.props, media, caption];
}

class VideoBlock extends ContentBlock {
  final ContentMedia media;
  final String? posterUrl;
  final bool autoplay;
  final int? durationSeconds;

  const VideoBlock({
    required super.id,
    required super.order,
    required this.media,
    this.posterUrl,
    this.autoplay = false,
    this.durationSeconds,
    super.meta = const {},
  }) : super(type: 'video');

  factory VideoBlock.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media'];
    return VideoBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      media: mediaJson is Map
          ? ContentMedia.fromJson(mediaJson.cast<String, dynamic>())
          : ContentMedia(
              url:
                  (json['videoUrl'] ?? json['audioUrl'] ?? json['url'] ?? '')
                      as String,
              fileId: '',
              kind: ContentMediaKind.video,
            ),
      posterUrl: json['posterUrl'] as String? ?? json['imageUrl'] as String?,
      autoplay: json['autoplay'] as bool? ?? false,
      durationSeconds: json['durationSeconds'] as int?,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'type': 'video',
    'media': media.toJson(),
    if (posterUrl != null) 'posterUrl': posterUrl,
    'autoplay': autoplay,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (meta.isNotEmpty) 'meta': meta,
  };

  @override
  List<Object?> get props => [
    ...super.props,
    media,
    posterUrl,
    autoplay,
    durationSeconds,
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
    super.meta = const {},
  }) : super(type: 'audio');

  factory AudioBlock.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    ContentMedia parsedMedia;
    if (rawMedia is Map<String, dynamic>) {
      parsedMedia = ContentMedia.fromJson(rawMedia.cast<String, dynamic>());
    } else {
      parsedMedia = ContentMedia(
        url: (json['audioUrl'] ?? json['url'] ?? '') as String,
        fileId: '',
        kind: ContentMediaKind.audio,
      );
    }

    final rawData = json['data'] is Map ? json['data'] as Map : null;
    return AudioBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      media: parsedMedia,
      transcript:
          json['transcript'] as String? ?? rawData?['transcript'] as String?,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
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
      if (meta.isNotEmpty) 'meta': meta,
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
    super.meta = const {},
  }) : super(type: 'lottie');

  factory LottieBlock.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    ContentMedia parsedMedia;
    if (rawMedia is Map<String, dynamic>) {
      parsedMedia = ContentMedia.fromJson(rawMedia.cast<String, dynamic>());
    } else {
      parsedMedia = ContentMedia(
        url: (json['imageUrl'] ?? json['url'] ?? '') as String,
        fileId: '',
        kind: ContentMediaKind.lottie,
      );
    }

    final rawData = json['data'] is Map ? json['data'] as Map : null;
    return LottieBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      media: parsedMedia,
      loop: json['loop'] as bool? ?? rawData?['loop'] as bool? ?? true,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
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
      if (meta.isNotEmpty) 'meta': meta,
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
    super.meta = const {},
  }) : super(type: 'quiz');

  factory QuizBlock.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map ? json['data'] as Map : null;
    return QuizBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      quizId:
          (json['quizId'] ??
                  json['quizRefId'] ??
                  rawData?['quizId'] ??
                  rawData?['quizRefId'] ??
                  '')
              as String,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'quiz',
      'quizId': quizId,
      if (meta.isNotEmpty) 'meta': meta,
    };
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
    super.meta = const {},
  }) : super(type: 'glyph');

  factory GlyphBlock.fromJson(Map<String, dynamic> json) {
    return GlyphBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      olChiki:
          json['olChiki'] as String? ??
          json['ol_chiki'] as String? ??
          json['textOlChiki'] as String? ??
          '',
      latin: json['latin'] as String? ?? json['textLatin'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String?,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
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
      if (meta.isNotEmpty) 'meta': meta,
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
    super.meta = const {},
  }) : super(type: 'callout');

  factory CalloutBlock.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map ? json['data'] as Map : null;
    return CalloutBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      text: json['text'] as String? ?? json['textLatin'] as String? ?? '',
      variant: CalloutVariant.fromString(
        json['variant'] as String? ?? rawData?['style'] as String? ?? 'note',
      ),
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
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
      if (meta.isNotEmpty) 'meta': meta,
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
    super.meta = const {},
  }) : super(type: 'tracing');

  factory TracingBlock.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map ? json['data'] as Map : null;
    return TracingBlock(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      config: TracingConfig.fromJson(
        json['config'] is Map<String, dynamic>
            ? json['config'] as Map<String, dynamic>
            : (rawData?.cast<String, dynamic>() ?? const {}),
      ),
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'tracing',
      'config': config.toJson(),
      if (meta.isNotEmpty) 'meta': meta,
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

  String? get effectiveAudioUrl => audioUrl ?? _extractAudioFromBlocks(blocks);

  static String? _extractAudioFromBlocks(List<ContentBlock> blocksList) {
    for (final block in blocksList) {
      if (block.type == 'audio' && block is AudioBlock) {
        return block.media.url;
      }
    }
    return null;
  }

  static String? _extractFileIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final regExp = RegExp(r'/files/([^/]+)/view');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Defensive: schema has `tags` as string(50), not array.
  // Joining + clipping prevents row_invalid_structure 400 errors.
  // TODO(phase-b): remove once tagsList array column is live.
  static String? _coerceTagsToLegacyString(List<String>? tags) {
    if (tags == null || tags.isEmpty) return null;
    final joined = tags.where((t) => t.trim().isNotEmpty).join(',');
    if (joined.isEmpty) return null;
    return joined.length <= 50 ? joined : joined.substring(0, 50);
  }

  factory ContentItem.fromJson(
    Map<String, dynamic> json, [
    String? docId,
    ContentKind? expectedKind,
  ]) {
    // Appwrite collection documents intentionally do not store a `kind`
    // attribute. The repository knows which collection it queried and passes
    // [expectedKind] so that legacy collection-specific keys round-trip safely.
    final rawKind = expectedKind?.name ?? json['kind'] as String? ?? 'lesson';
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
    final coverMediaType = json['coverMediaType'] as String? ??
        (parsedHeroMedia != null ? 'image' : null);
    if (parsedHeroMedia != null && parsedHeroMedia.fileId.isEmpty) {
      final extId = _extractFileIdFromUrl(parsedHeroMedia.url);
      if (extId != null && extId.isNotEmpty) {
        parsedHeroMedia = ContentMedia(
          url: parsedHeroMedia.url,
          fileId: extId,
          kind: parsedHeroMedia.kind,
          posterUrl: parsedHeroMedia.posterUrl,
          durationSeconds: parsedHeroMedia.durationSeconds,
        );
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
                .map((e) {
                  try {
                    if (e is Map<String, dynamic>) {
                      return ContentBlock.fromJson(e);
                    }
                    if (e is Map) {
                      return ContentBlock.fromJson(e.cast<String, dynamic>());
                    }
                  } catch (_) {}
                  return null;
                })
                .whereType<ContentBlock>()
                .toList();
          } catch (_) {}
        }
      } else if (rawBlocks is List<dynamic>) {
        parsedBlocks = rawBlocks
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return ContentBlock.fromJson(e);
                }
                if (e is Map) {
                  return ContentBlock.fromJson(e.cast<String, dynamic>());
                }
              } catch (_) {}
              return null;
            })
            .whereType<ContentBlock>()
            .toList();
      }
    }

    final rawUpdatedAt =
        json['updatedAt'] ?? json['updated_at'] ?? json[r'$updatedAt'];
    DateTime parsedUpdatedAt = DateTime.now();
    if (rawUpdatedAt != null) {
      if (rawUpdatedAt is String) {
        parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt) ?? DateTime.now();
      } else if (rawUpdatedAt is int) {
        parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt);
      }
    }

    // Prefer tagsList (array), fall back to legacy comma-joined tags.
    final tagsListRaw = json['tagsList'];
    List<String> parsedTags;
    if (tagsListRaw is List) {
      parsedTags = tagsListRaw
          .cast<String>()
          .where((t) => t.trim().isNotEmpty)
          .toList();
    } else {
      final rawTags = json['tags'];
      if (rawTags is List<dynamic>) {
        parsedTags = rawTags.map((e) => e.toString()).toList();
      } else if (rawTags is String && rawTags.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawTags) as List<dynamic>;
          parsedTags = decoded.map((e) => e.toString()).toList();
        } catch (_) {
          parsedTags = rawTags
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
        }
      } else {
        parsedTags = const [];
      }
    }

    final rawCategoryId =
        json['category_id'] ??
        json['categoryId'] ??
        ((parsedKind == ContentKind.word ||
                parsedKind == ContentKind.sentence ||
                parsedKind == ContentKind.rhyme)
            ? json['category']
            : null);
    String parsedCategoryId = '';
    if (rawCategoryId is String) {
      parsedCategoryId = rawCategoryId;
    } else if (rawCategoryId is Map) {
      parsedCategoryId =
          (rawCategoryId['\$id'] ?? rawCategoryId['id'] ?? '') as String;
    }

    String? firstString(List<dynamic> values) {
      for (final value in values) {
        if (value is String && value.isNotEmpty) return value;
      }
      return null;
    }

    var resolvedTitle = firstString([json['title'], json['titleLatin']]) ?? '';
    var resolvedTitleOlChiki = firstString([
      json['title_ol_chiki'],
      json['titleOlChiki'],
    ]);
    var resolvedSubtitle = json['subtitle'] as String?;
    var resolvedOlChiki = firstString([json['ol_chiki'], json['olChiki']]);

    switch (parsedKind) {
      case ContentKind.lesson:
        resolvedTitle =
            firstString([json['title'], json['titleLatin']]) ?? resolvedTitle;
        resolvedSubtitle =
            firstString([json['subtitle'], json['description']]) ??
            resolvedSubtitle;
        break;
      case ContentKind.letter:
        resolvedTitle =
            firstString([json['title'], json['transliterationLatin']]) ??
            resolvedTitle;
        resolvedTitleOlChiki ??= json['charOlChiki'] as String?;
        resolvedOlChiki ??= json['charOlChiki'] as String?;
        resolvedSubtitle =
            firstString([
              json['subtitle'],
              json['exampleWordLatin'],
              json['exampleWordOlChiki'],
            ]) ??
            resolvedSubtitle;
        break;
      case ContentKind.number:
        resolvedTitle =
            firstString([json['title'], json['nameLatin']]) ?? resolvedTitle;
        resolvedTitleOlChiki ??= json['nameOlChiki'] as String?;
        resolvedOlChiki ??= json['numeral'] as String?;
        break;
      case ContentKind.word:
        resolvedTitle =
            firstString([json['title'], json['wordLatin']]) ?? resolvedTitle;
        resolvedTitleOlChiki ??= json['wordOlChiki'] as String?;
        resolvedOlChiki ??= json['wordOlChiki'] as String?;
        resolvedSubtitle =
            firstString([json['subtitle'], json['meaning']]) ??
            resolvedSubtitle;
        break;
      case ContentKind.sentence:
        resolvedTitle =
            firstString([json['title'], json['sentenceLatin']]) ??
            resolvedTitle;
        resolvedTitleOlChiki ??= json['sentenceOlChiki'] as String?;
        resolvedOlChiki ??= json['sentenceOlChiki'] as String?;
        resolvedSubtitle =
            firstString([json['subtitle'], json['meaning']]) ??
            resolvedSubtitle;
        break;
      case ContentKind.rhyme:
        resolvedTitle =
            firstString([json['title'], json['titleLatin']]) ?? resolvedTitle;
        resolvedOlChiki ??= json['contentOlChiki'] as String?;
        resolvedSubtitle =
            firstString([json['subtitle'], json['contentLatin']]) ??
            resolvedSubtitle;
        break;
    }

    if (parsedHeroMedia == null) {
      String? legacyMediaUrl;
      ContentMediaKind? legacyMediaKind;
      if (parsedKind == ContentKind.lesson) {
        legacyMediaUrl = firstString([
          json['heroMediaUrl'],
          json['thumbnailUrl'],
        ]);
        final rawMediaType = json['heroMediaType'] as String?;
        if (rawMediaType != null) {
          try {
            legacyMediaKind = ContentMediaKind.fromString(rawMediaType);
          } catch (_) {}
        }
        legacyMediaKind ??= ContentMediaKind.image;
      } else if (firstString([json['animationUrl']]) != null) {
        legacyMediaUrl = json['animationUrl'] as String;
        legacyMediaKind = ContentMediaKind.lottie;
      } else if (firstString([json['imageUrl'], json['thumbnailUrl']]) !=
          null) {
        legacyMediaUrl = firstString([json['imageUrl'], json['thumbnailUrl']]);
        legacyMediaKind = ContentMediaKind.image;
      } else if (firstString([json['audioUrl']]) != null &&
          parsedKind != ContentKind.rhyme) {
        legacyMediaUrl = json['audioUrl'] as String;
        legacyMediaKind = ContentMediaKind.audio;
      }
      if (legacyMediaUrl != null && legacyMediaKind != null) {
        final extId = _extractFileIdFromUrl(legacyMediaUrl);
        parsedHeroMedia = ContentMedia(
          url: legacyMediaUrl,
          fileId: extId ?? '',
          kind: legacyMediaKind,
        );
      }
    }

    final parsedItem = ContentItem(
      id: docId ?? json['\$id'] as String? ?? json['id'] as String? ?? '',
      kind: parsedKind,
      categoryId: parsedCategoryId,
      title: resolvedTitle,
      titleOlChiki: resolvedTitleOlChiki,
      subtitle: resolvedSubtitle,
      olChiki: resolvedOlChiki,
      heroMedia: parsedHeroMedia,
      coverMediaType: coverMediaType,
      blocks: parsedBlocks,
      tracing: parsedTracing,
      order: json['order'] as int? ?? 0,
      isPublished:
          json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          json['isActive'] as bool? ??
          true,
      isPremium:
          json['is_premium'] as bool? ?? json['isPremium'] as bool? ?? false,
      tags: parsedTags,
      difficulty: json['difficulty'] as String?,
      durationSeconds:
          json['duration_seconds'] as int? ?? json['durationSeconds'] as int?,
      updatedAt: parsedUpdatedAt,
      audioUrl: json['audioUrl'] as String?,
      audioFileId: (json['audioFileId'] as String? ?? '').isNotEmpty
          ? json['audioFileId'] as String?
          : _extractFileIdFromUrl(json['audioUrl'] as String?),
      durationMs: json['durationMs'] as int?,
      category: json['category'] as String?,
    );

    if (parsedKind == ContentKind.rhyme && json['audioUrl'] == null) {
      final hasAudioBlock = parsedBlocks.any((e) => e.type == 'audio');
      if (hasAudioBlock) {
        AppLogger.debug(
          'Legacy audio block detected on rhyme ${parsedItem.id}',
        );
      }
    }

    return parsedItem;
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

  Map<String, dynamic> toAppwrite() {
    final requiresCategory =
        kind == ContentKind.lesson ||
        kind == ContentKind.word ||
        kind == ContentKind.sentence ||
        kind == ContentKind.rhyme;
    if (requiresCategory && categoryId.isEmpty) {
      AppLogger.debug('ContentItem $id saved without categoryId');
    }

    final resolvedTitleOlChiki =
        (titleOlChiki == null || titleOlChiki!.trim().isEmpty)
        ? title
        : titleOlChiki!;
    final encodedHeroMedia = heroMedia == null
        ? null
        : jsonEncode(heroMedia!.toJson());
    final encodedBlocks = jsonEncode(blocks.map((e) => e.toJson()).toList());
    final encodedTracing = tracing == null
        ? null
        : jsonEncode(tracing!.toJson());
    final imageUrl =
        heroMedia?.kind == ContentMediaKind.image ||
            heroMedia?.kind == ContentMediaKind.svg
        ? heroMedia?.url
        : null;
    final legacyAudioUrl = heroMedia?.kind == ContentMediaKind.audio
        ? heroMedia?.url
        : null;
    final animationUrl = heroMedia?.kind == ContentMediaKind.lottie
        ? heroMedia?.url
        : null;

    if (kind == ContentKind.rhyme &&
        heroMedia?.kind == ContentMediaKind.audio &&
        audioUrl != null) {
      AppLogger.debug(
        'WARNING: both heroMedia.kind == audio AND audioUrl are set on rhyme $id',
      );
    }

    switch (kind) {
      case ContentKind.lesson:
        return {
          if (categoryId.isNotEmpty) 'categoryId': categoryId,
          'titleOlChiki': resolvedTitleOlChiki,
          'titleLatin': title,
          'level': 'beginner',
          'description': subtitle ?? '',
          'order': order,
          'estimatedMinutes': durationSeconds != null
              ? (durationSeconds! / 60).round()
              : 5,
          'isActive': isPublished,
          'isPremium': isPremium,
          'thumbnailUrl': heroMedia?.url,
          'heroMediaUrl': heroMedia?.url,
          'heroMediaType': heroMedia?.kind.name,
          'heroPosterUrl': heroMedia?.posterUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.letter:
        return {
          'charOlChiki': olChiki ?? resolvedTitleOlChiki,
          'transliterationLatin': title,
          'order': order,
          'isActive': isPublished,
          'exampleWordLatin': subtitle,
          'audioUrl': legacyAudioUrl,
          'imageUrl': imageUrl,
          'animationUrl': animationUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.number:
        return {
          'numeral': olChiki ?? resolvedTitleOlChiki,
          'value': int.tryParse(title) ?? order,
          'nameOlChiki': resolvedTitleOlChiki,
          'nameLatin': title,
          'order': order,
          'isActive': isPublished,
          'audioUrl': legacyAudioUrl,
          'imageUrl': imageUrl,
          'animationUrl': animationUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.word:
        return {
          'wordOlChiki': olChiki ?? resolvedTitleOlChiki,
          'wordLatin': title,
          'meaning': subtitle ?? '',
          if (categoryId.isNotEmpty) 'category': categoryId,
          'order': order,
          'isActive': isPublished,
          'audioUrl': legacyAudioUrl,
          'imageUrl': imageUrl,
          'animationUrl': animationUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.sentence:
        return {
          'sentenceOlChiki': olChiki ?? resolvedTitleOlChiki,
          'sentenceLatin': title,
          'meaning': subtitle ?? '',
          if (categoryId.isNotEmpty) 'category': categoryId,
          'order': order,
          'isActive': isPublished,
          'audioUrl': legacyAudioUrl,
          'imageUrl': imageUrl,
          'animationUrl': animationUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.rhyme:
        final resolvedBlocks = blocks.where((e) => e.type != 'audio').toList();
        final encodedBlocksForRhyme = jsonEncode(
          resolvedBlocks.map((e) => e.toJson()).toList(),
        );
        final tagsLegacy = _coerceTagsToLegacyString(tags);
        final tagsArray = tags.where((t) => t.trim().isNotEmpty).toList();
        return {
          'titleOlChiki': resolvedTitleOlChiki,
          'titleLatin': title,
          'contentOlChiki': olChiki ?? '',
          'contentLatin': subtitle ?? '',
          'audioUrl': audioUrl,
          'audioFileId': audioFileId,
          'durationMs': durationMs,
          'thumbnailUrl': coverMediaType == 'image' ? heroMedia?.url : null,
          'coverMediaType': coverMediaType,
          if (categoryId.isNotEmpty) 'categoryId': categoryId,
          if (category != null && category!.isNotEmpty) 'category': category,
          // ignore: use_null_aware_elements
          if (tagsLegacy != null) 'tags': tagsLegacy,
          // ignore: use_null_aware_elements
          if (tagsArray.isNotEmpty) 'tagsList': tagsArray,
          'difficulty': difficulty ?? 'easy',
          'durationSeconds': durationSeconds ?? 0,
          'isPremium': isPremium,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocksForRhyme,
          'tracing': encodedTracing,
        };
    }
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
