import 'package:equatable/equatable.dart';

import 'content_enums.dart';
import 'content_media.dart';
import 'tracing_models.dart';

// Sealed ContentBlock hierarchy
sealed class ContentBlock extends Equatable {
  final String id;
  final int order;
  final String type;
  final Map<String, dynamic> meta; // Admin/editor passthrough

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

Map<String, dynamic> _extractBlockMeta(Map<String, dynamic> json) {
  return <String, dynamic>{
    if (json['audioUrl'] != null) 'audioUrl': json['audioUrl'],
    if (json['audio_url'] != null) 'audioUrl': json['audio_url'],
    if (json['themeColor'] != null) 'themeColor': json['themeColor'],
    if (json['data'] is Map) ...(json['data'] as Map).cast<String, dynamic>(),
    if (json['meta'] is Map) ...(json['meta'] as Map).cast<String, dynamic>(),
  };
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
      meta: _extractBlockMeta(json),
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
      if (meta.containsKey('audioUrl')) 'audioUrl': meta['audioUrl'],
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
      meta: _extractBlockMeta(json),
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
      if (meta.containsKey('audioUrl')) 'audioUrl': meta['audioUrl'],
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
      meta: _extractBlockMeta(json),
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
    if (meta.containsKey('audioUrl')) 'audioUrl': meta['audioUrl'],
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
        url:
            (json['audioUrl'] ?? json['audio_url'] ?? json['url'] ?? '')
                as String,
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
      meta: _extractBlockMeta(json),
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
      if (meta.containsKey('audioUrl')) 'audioUrl': meta['audioUrl'],
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
        url:
            (json['imageUrl'] ?? json['animationUrl'] ?? json['url'] ?? '')
                as String,
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
      meta: _extractBlockMeta(json),
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
      if (meta.containsKey('audioUrl')) 'audioUrl': meta['audioUrl'],
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
      meta: _extractBlockMeta(json),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'quiz',
      'quizId': quizId,
      if (meta.containsKey('audioUrl')) 'audioUrl': meta['audioUrl'],
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
      meta: _extractBlockMeta(json),
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
      meta: _extractBlockMeta(json),
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
      if (meta.containsKey('audioUrl')) 'audioUrl': meta['audioUrl'],
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
      meta: _extractBlockMeta(json),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': 'tracing',
      'config': config.toJson(),
      if (meta.containsKey('audioUrl')) 'audioUrl': meta['audioUrl'],
      if (meta.isNotEmpty) 'meta': meta,
    };
  }

  @override
  List<Object?> get props => [...super.props, config];
}
