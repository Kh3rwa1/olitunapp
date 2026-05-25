import 'package:itun/shared/models/content_item.dart';
import 'package:itun/features/lessons/data/ol_chiki_strokes.dart';

/// Predefined stroke templates for Ol Chiki letters and numerals.
/// Programmatically built from ol_chiki_strokes.dart.
final Map<String, TracingConfig> tracingTemplates = _buildTracingTemplates();

Map<String, TracingConfig> _buildTracingTemplates() {
  final Map<String, TracingConfig> map = {};

  for (final entry in olChikiStrokes.entries) {
    final glyph = entry.key;
    final segments = entry.value;

    final strokes = <TracingStroke>[];
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final path = <TracingPoint>[];

      for (int p = 0; p < seg.points.length; p++) {
        final pt = seg.points[p];
        final isCp = seg.type == 'cubic' && (p == 1 || p == 2);
        path.add(TracingPoint(x: pt.dx, y: pt.dy, isControlPoint: isCp));
      }

      strokes.add(
        TracingStroke(
          id: 'stroke_${glyph}_$i',
          order: i,
          path: path,
          hintText: 'Stroke ${i + 1}',
        ),
      );
    }

    map[glyph] = TracingConfig(
      glyph: glyph,
      strokes: strokes,
    );
  }

  return map;
}

/// Generates a default bounding-box stroke path for letters or numerals
/// that do not have refined stroke coordinates predefined.
TracingConfig getFallbackTemplate(String glyph) {
  return TracingConfig(
    glyph: glyph,
    strokes: [
      TracingStroke(
        id: 'stroke_${glyph}_fallback',
        order: 0,
        path: const [
          TracingPoint(x: 0.2, y: 0.2),
          TracingPoint(x: 0.8, y: 0.2),
          TracingPoint(x: 0.8, y: 0.8),
          TracingPoint(x: 0.2, y: 0.8),
          TracingPoint(x: 0.2, y: 0.2),
        ],
        direction: TracingDirection.clockwise,
        hintText: 'Trace the box around the glyph',
      ),
    ],
  );
}
