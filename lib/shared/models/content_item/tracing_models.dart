import 'package:equatable/equatable.dart';

import 'content_enums.dart';

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
