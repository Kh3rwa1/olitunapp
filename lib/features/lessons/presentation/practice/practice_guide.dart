import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/ol_chiki_strokes.dart';

Path buildPracticeGuidePath(Size size, String letter) {
  // Use actual stroke data if available
  final strokeData = olChikiStrokes[letter];
  if (strokeData != null) {
    return buildPathFromStrokes(size, strokeData);
  }

  // Fallback: generate a simple placeholder for unknown letters
  return _buildFallbackPath(size, letter);
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

    for (var i = 0; i <= samplesPerMetric; i++) {
      final distance = (i / samplesPerMetric) * length;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        result.add(tangent.position);
      }
    }
  }

  return result;
}

double computeTraceProgress({
  required List<Offset> guidePoints,
  required List<Offset?> tracedPoints,
  required double tolerance,
}) {
  if (guidePoints.isEmpty) {
    return 0;
  }

  final userPoints = tracedPoints.whereType<Offset>().toList(growable: false);
  if (userPoints.isEmpty) {
    return 0;
  }

  var matched = 0;
  final toleranceSquared = math.pow(tolerance, 2).toDouble();

  for (final guidePoint in guidePoints) {
    final isCovered = userPoints.any((userPoint) {
      final dx = userPoint.dx - guidePoint.dx;
      final dy = userPoint.dy - guidePoint.dy;
      return (dx * dx + dy * dy) <= toleranceSquared;
    });
    if (isCovered) {
      matched++;
    }
  }

  return (matched / guidePoints.length).clamp(0.0, 1.0);
}
