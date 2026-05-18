import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/ol_chiki_strokes.dart';

Path buildPracticeGuidePath(Size size, String letter) {
  final character = normalizePracticeCharacter(letter);

  // Use actual stroke data if available
  final strokeData = olChikiStrokes[character];
  if (strokeData != null) {
    return buildPathFromStrokes(size, strokeData);
  }

  // Fallback: generate a simple placeholder for unknown letters
  return _buildFallbackPath(size, character);
}

String normalizePracticeCharacter(String value) {
  final decoded = value.contains('%')
      ? Uri.decodeComponent(value).trim()
      : value.trim();
  const asciiToOlChikiDigits = {
    '0': '᱐',
    '1': '᱑',
    '2': '᱒',
    '3': '᱓',
    '4': '᱔',
    '5': '᱕',
    '6': '᱖',
    '7': '᱗',
    '8': '᱘',
    '9': '᱙',
  };

  const latinToOlChiki = {
    'la': 'ᱚ',
    'a': 'ᱟ',
    'aah': 'ᱟ',
    'aa': 'ᱟ',
    'li': 'ᱤ',
    'i': 'ᱤ',
    'lu': 'ᱩ',
    'u': 'ᱩ',
    'le': 'ᱮ',
    'e': 'ᱮ',
    'lo': 'ᱳ',
    'o': 'ᱳ',
    'ok': 'ᱠ',
    'k': 'ᱠ',
    'ol': 'ᱜ',
    'g': 'ᱜ',
    'ong': 'ᱝ',
    'ng': 'ᱝ',
    'uc': 'ᱪ',
    'c': 'ᱪ',
    'oj': 'ᱡ',
    'j': 'ᱡ',
    'at': 'ᱛ',
    't': 'ᱛ',
    'el': 'ᱞ',
    'l': 'ᱞ',
    'am': 'ᱢ',
    'm': 'ᱢ',
    'aw': 'ᱣ',
    'w': 'ᱣ',
    'is': 'ᱥ',
    's': 'ᱥ',
    'ih': 'ᱦ',
    'h': 'ᱦ',
    'ud': 'ᱫ',
    'd': 'ᱫ',
    'ir': 'ᱨ',
    'r': 'ᱨ',
    'ot': 'ᱴ',
    'od': 'ᱰ',
    'en': 'ᱱ',
    'n': 'ᱱ',
    'op': 'ᱯ',
    'p': 'ᱯ',
    'ob': 'ᱵ',
    'b': 'ᱵ',
    'oy': 'ᱭ',
    'y': 'ᱭ',
    'ur': 'ᱲ',
  };

  final digit = asciiToOlChikiDigits[decoded];
  if (digit != null) return digit;

  final exactStroke = olChikiStrokes[decoded];
  if (exactStroke != null) return decoded;

  final olChikiMatch = RegExp(r'[\u1C50-\u1C7F]').firstMatch(decoded);
  if (olChikiMatch != null) {
    return olChikiMatch.group(0)!;
  }

  return latinToOlChiki[decoded.toLowerCase()] ?? decoded;
}

/// Fallback path for letters without stroke data
Path _buildFallbackPath(Size size, String letter) {
  final path = Path();
  final seed = letter.runes.fold<int>(0, (sum, rune) => sum + rune);
  final variant = seed % 3;

  final left = size.width * 0.18;
  final top = size.height * 0.14;
  final right = size.width * 0.82;
  final bottom = size.height * 0.86;
  final centerX = size.width * 0.5;
  final centerY = size.height * 0.5;

  switch (variant) {
    case 0:
      path
        ..moveTo(centerX, top)
        ..lineTo(centerX, bottom)
        ..moveTo(centerX, centerY)
        ..quadraticBezierTo(right, centerY - size.height * 0.08, right, top)
        ..moveTo(centerX, centerY)
        ..quadraticBezierTo(right, centerY + size.height * 0.08, right, bottom);
      break;
    case 1:
      path
        ..moveTo(left, top)
        ..lineTo(left, bottom)
        ..quadraticBezierTo(centerX, bottom + size.height * 0.02, right, bottom)
        ..moveTo(left, centerY)
        ..quadraticBezierTo(
          centerX,
          centerY - size.height * 0.06,
          right,
          centerY,
        )
        ..moveTo(left, top)
        ..quadraticBezierTo(centerX, top - size.height * 0.04, right, top);
      break;
    default:
      path
        ..moveTo(right, top)
        ..quadraticBezierTo(centerX, top - size.height * 0.05, left, centerY)
        ..quadraticBezierTo(centerX, bottom + size.height * 0.05, right, bottom)
        ..moveTo(centerX, top)
        ..lineTo(centerX, bottom);
      break;
  }

  return path;
}

List<Offset> samplePath(Path path, {int samplesPerMetric = 48}) {
  final result = <Offset>[];
  for (final metric in path.computeMetrics()) {
    final length = metric.length;
    if (length <= 0) {
      continue;
    }

    final sampleCount = math.max(8, (length / 5).ceil());
    final cappedSampleCount = math.min(sampleCount, samplesPerMetric * 3);

    for (var i = 0; i <= cappedSampleCount; i++) {
      final distance = (i / cappedSampleCount) * length;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        result.add(tangent.position);
      }
    }
  }

  return result;
}

class TraceScore {
  static const double autoAdvanceThreshold = 0.70;

  final double overall;
  final double coverage;
  final double precision;
  final double startAccuracy;
  final double completion;

  const TraceScore({
    required this.overall,
    required this.coverage,
    required this.precision,
    required this.startAccuracy,
    required this.completion,
  });

  static const zero = TraceScore(
    overall: 0,
    coverage: 0,
    precision: 0,
    startAccuracy: 0,
    completion: 0,
  );

  bool get isComplete {
    return overall >= 0.86 &&
        coverage >= 0.82 &&
        precision >= 0.64 &&
        startAccuracy >= 0.45;
  }

  bool get shouldAutoAdvance => overall >= autoAdvanceThreshold;
}

double computeTraceProgress({
  required List<Offset> guidePoints,
  required List<Offset?> tracedPoints,
  required double tolerance,
}) {
  return computeTraceScore(
    guidePoints: guidePoints,
    tracedPoints: tracedPoints,
    tolerance: tolerance,
  ).overall;
}

TraceScore computeTraceScore({
  required List<Offset> guidePoints,
  required List<Offset?> tracedPoints,
  required double tolerance,
}) {
  if (guidePoints.isEmpty) {
    return TraceScore.zero;
  }

  final userPoints = tracedPoints.whereType<Offset>().toList(growable: false);
  if (userPoints.isEmpty) {
    return TraceScore.zero;
  }

  final toleranceSquared = math.pow(tolerance, 2).toDouble();
  final softToleranceSquared = math.pow(tolerance * 1.35, 2).toDouble();

  var matchedGuidePoints = 0;

  for (final guidePoint in guidePoints) {
    final isCovered = userPoints.any((userPoint) {
      final dx = userPoint.dx - guidePoint.dx;
      final dy = userPoint.dy - guidePoint.dy;
      return (dx * dx + dy * dy) <= toleranceSquared;
    });
    if (isCovered) {
      matchedGuidePoints++;
    }
  }

  var accurateUserPoints = 0;
  for (final userPoint in userPoints) {
    if (_isNearAnyGuidePoint(
      userPoint: userPoint,
      guidePoints: guidePoints,
      toleranceSquared: softToleranceSquared,
    )) {
      accurateUserPoints++;
    }
  }

  final startDistance = (userPoints.first - guidePoints.first).distance;
  final startAccuracy = (1 - (startDistance / (tolerance * 2.4))).clamp(
    0.0,
    1.0,
  );

  final coverage = (matchedGuidePoints / guidePoints.length).clamp(0.0, 1.0);
  final precision = (accurateUserPoints / userPoints.length).clamp(0.0, 1.0);
  final completion =
      (_strokeLength(tracedPoints) / _polylineLength(guidePoints)).clamp(
        0.0,
        1.0,
      );

  final overall =
      (coverage * 0.48) +
      (precision * 0.28) +
      (startAccuracy * 0.12) +
      (completion * 0.12);

  return TraceScore(
    overall: overall.clamp(0.0, 1.0),
    coverage: coverage,
    precision: precision,
    startAccuracy: startAccuracy,
    completion: completion,
  );
}

bool _isNearAnyGuidePoint({
  required Offset userPoint,
  required List<Offset> guidePoints,
  required double toleranceSquared,
}) {
  for (final guidePoint in guidePoints) {
    final dx = userPoint.dx - guidePoint.dx;
    final dy = userPoint.dy - guidePoint.dy;
    if ((dx * dx + dy * dy) <= toleranceSquared) {
      return true;
    }
  }
  return false;
}

double _strokeLength(List<Offset?> points) {
  var length = 0.0;
  Offset? previous;
  for (final point in points) {
    if (point == null) {
      previous = null;
      continue;
    }
    if (previous != null) {
      length += (point - previous).distance;
    }
    previous = point;
  }
  return length;
}

double _polylineLength(List<Offset> points) {
  if (points.length < 2) {
    return 1;
  }

  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    length += (points[i] - points[i - 1]).distance;
  }
  return math.max(length, 1);
}
