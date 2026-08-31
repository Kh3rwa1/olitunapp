import 'package:equatable/equatable.dart';

import 'content_enums.dart';

/// ContentMedia represents an image, video, audio, SVG, or Lottie asset.
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
