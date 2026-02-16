/// Ol Chiki letter stroke data for practice/tracing screen.
///
/// Each letter has a list of stroke segments. Each segment represents one
/// continuous pen stroke (lift between segments). Points are normalized
/// coordinates (0.0-1.0) that scale to the canvas size.
///
/// Stroke types:
/// - 'line': Simple line from start to end
/// - 'cubic': Cubic bezier with two control points
/// - 'arc': Circular arc segment
library;

import 'dart:ui';

/// Represents a single stroke segment
class StrokeSegment {
  final String type; // 'line', 'cubic', 'arc'
  final List<Offset> points; // Normalized 0.0-1.0 coordinates

  const StrokeSegment({required this.type, required this.points});
}

/// Letter stroke data: Maps Ol Chiki character to its stroke segments
final Map<String, List<StrokeSegment>> olChikiStrokes = {
  // ᱚ - La (a) - Circular shape with tail
  'ᱚ': [
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.50, 0.20), // start top center
        Offset(0.20, 0.20), // control 1
        Offset(0.20, 0.80), // control 2
        Offset(0.50, 0.80), // end bottom center
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.50, 0.80), // start bottom center
        Offset(0.80, 0.80), // control 1
        Offset(0.80, 0.20), // control 2
        Offset(0.50, 0.20), // end top center
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.50, 0.50), // center
        Offset(0.75, 0.50), // right mid
      ],
    ),
  ],

  // ᱟ - Aah (aa) - Open circular with hook
  'ᱟ': [
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.70, 0.25), // start top right
        Offset(0.25, 0.15), // control 1
        Offset(0.20, 0.75), // control 2
        Offset(0.50, 0.80), // end bottom center
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.50, 0.80), // start bottom center
        Offset(0.75, 0.85), // control 1
        Offset(0.82, 0.55), // control 2
        Offset(0.70, 0.45), // end mid right
      ],
    ),
  ],

  // ᱤ - Li (i) - Vertical with curves
  'ᱤ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.50, 0.18), // top
        Offset(0.50, 0.82), // bottom
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.30, 0.35), // left curve start
        Offset(0.40, 0.45), // control 1
        Offset(0.40, 0.55), // control 2
        Offset(0.30, 0.65), // left curve end
      ],
    ),
  ],

  // ᱩ - Lu (u) - U shape with extension
  'ᱩ': [
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.25, 0.20), // start top left
        Offset(0.25, 0.70), // control 1
        Offset(0.75, 0.70), // control 2
        Offset(0.75, 0.20), // end top right
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.50, 0.70), // bottom center
        Offset(0.50, 0.85), // extension down
      ],
    ),
  ],

  // ᱮ - E vowel - Angular E shape
  'ᱮ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.20), // top left
        Offset(0.30, 0.80), // bottom left
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.20), // top left
        Offset(0.70, 0.20), // top right
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.50), // mid left
        Offset(0.60, 0.50), // mid right
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.80), // bottom left
        Offset(0.70, 0.80), // bottom right
      ],
    ),
  ],

  // ᱳ - O vowel - Oval shape
  'ᱳ': [
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.50, 0.18), // top center
        Offset(0.20, 0.18), // control 1
        Offset(0.20, 0.82), // control 2
        Offset(0.50, 0.82), // bottom center
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.50, 0.82), // bottom center
        Offset(0.80, 0.82), // control 1
        Offset(0.80, 0.18), // control 2
        Offset(0.50, 0.18), // top center
      ],
    ),
  ],

  // ᱠ - Ok (k) - Angular K shape
  'ᱠ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.20), // top left
        Offset(0.30, 0.80), // bottom left
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.50), // mid left
        Offset(0.70, 0.20), // top right
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.50), // mid left
        Offset(0.70, 0.80), // bottom right
      ],
    ),
  ],

  // ᱜ - Ol (g) - Curved G shape
  'ᱜ': [
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.75, 0.30), // start upper right
        Offset(0.75, 0.15), // control 1
        Offset(0.25, 0.15), // control 2
        Offset(0.25, 0.50), // mid left
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.25, 0.50), // mid left
        Offset(0.25, 0.85), // control 1
        Offset(0.75, 0.85), // control 2
        Offset(0.75, 0.55), // mid right
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.75, 0.55), // mid right
        Offset(0.50, 0.55), // center
      ],
    ),
  ],

  // ᱝ - Ong (ng) - Nasal marker
  'ᱝ': [
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.25, 0.35), // start left
        Offset(0.25, 0.65), // control 1
        Offset(0.75, 0.65), // control 2
        Offset(0.75, 0.35), // end right
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.50, 0.50), // center
        Offset(0.50, 0.75), // down
      ],
    ),
  ],

  // ᱪ - Uc (c) - C shape
  'ᱪ': [
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.70, 0.25), // top right
        Offset(0.25, 0.20), // control 1
        Offset(0.25, 0.80), // control 2
        Offset(0.70, 0.75), // bottom right
      ],
    ),
  ],

  // ᱡ - Oj (j) - J shape with curve
  'ᱡ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.55, 0.20), // top
        Offset(0.55, 0.65), // mid down
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.55, 0.65), // mid
        Offset(0.55, 0.85), // control 1
        Offset(0.30, 0.85), // control 2
        Offset(0.30, 0.65), // end left
      ],
    ),
  ],

  // ᱴ - Ot (t) - T shape
  'ᱴ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.25, 0.25), // top left
        Offset(0.75, 0.25), // top right
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.50, 0.25), // top center
        Offset(0.50, 0.80), // bottom center
      ],
    ),
  ],

  // ᱰ - Od (d) - D shape
  'ᱰ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.20), // top left
        Offset(0.30, 0.80), // bottom left
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.30, 0.20), // top left
        Offset(0.80, 0.20), // control 1
        Offset(0.80, 0.80), // control 2
        Offset(0.30, 0.80), // bottom left
      ],
    ),
  ],

  // ᱱ - On (n) - N bridge shape
  'ᱱ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.25, 0.75), // bottom left
        Offset(0.25, 0.30), // top left
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.25, 0.30), // top left
        Offset(0.25, 0.15), // control 1
        Offset(0.75, 0.15), // control 2
        Offset(0.75, 0.30), // top right
      ],
    ),
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.75, 0.30), // top right
        Offset(0.75, 0.75), // bottom right
      ],
    ),
  ],

  // ᱯ - Op (p) - P shape
  'ᱯ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.80), // bottom
        Offset(0.30, 0.20), // top
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.30, 0.20), // top left
        Offset(0.80, 0.20), // control 1
        Offset(0.80, 0.50), // control 2
        Offset(0.30, 0.50), // mid left
      ],
    ),
  ],

  // ᱵ - Ob (b) - B shape
  'ᱵ': [
    StrokeSegment(
      type: 'line',
      points: [
        Offset(0.30, 0.20), // top
        Offset(0.30, 0.80), // bottom
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.30, 0.20), // top left
        Offset(0.75, 0.20), // control 1
        Offset(0.75, 0.48), // control 2
        Offset(0.30, 0.48), // mid left
      ],
    ),
    StrokeSegment(
      type: 'cubic',
      points: [
        Offset(0.30, 0.52), // mid left
        Offset(0.78, 0.52), // control 1
        Offset(0.78, 0.80), // control 2
        Offset(0.30, 0.80), // bottom left
      ],
    ),
  ],
};

/// Build a Flutter Path from stroke segments
Path buildPathFromStrokes(Size size, List<StrokeSegment> strokes) {
  final path = Path();
  final scaleX = size.width;
  final scaleY = size.height;

  for (final stroke in strokes) {
    final points = stroke.points;
    if (points.isEmpty) continue;

    // Scale first point
    final start = Offset(points[0].dx * scaleX, points[0].dy * scaleY);
    path.moveTo(start.dx, start.dy);

    switch (stroke.type) {
      case 'line':
        if (points.length >= 2) {
          final end = Offset(points[1].dx * scaleX, points[1].dy * scaleY);
          path.lineTo(end.dx, end.dy);
        }
        break;

      case 'cubic':
        if (points.length >= 4) {
          final cp1 = Offset(points[1].dx * scaleX, points[1].dy * scaleY);
          final cp2 = Offset(points[2].dx * scaleX, points[2].dy * scaleY);
          final end = Offset(points[3].dx * scaleX, points[3].dy * scaleY);
          path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
        }
        break;
    }
  }

  return path;
}
