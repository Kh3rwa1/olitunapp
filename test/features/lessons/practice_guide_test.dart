import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/presentation/practice/practice_guide.dart';

void main() {
  group('computeTraceScore', () {
    late List<Offset> guidePoints;

    setUp(() {
      final path = Path()
        ..moveTo(10, 10)
        ..lineTo(110, 10);
      guidePoints = samplePath(path, samplesPerMetric: 64);
    });

    test('rewards a precise trace that starts and stays on the guide', () {
      final tracedPoints = <Offset?>[
        for (var i = 0; i < guidePoints.length; i += 2) guidePoints[i],
        guidePoints.last,
        null,
      ];

      final score = computeTraceScore(
        guidePoints: guidePoints,
        tracedPoints: tracedPoints,
        tolerance: 8,
      );

      expect(score.isComplete, isTrue);
      expect(score.overall, greaterThanOrEqualTo(0.86));
      expect(score.coverage, greaterThanOrEqualTo(0.82));
      expect(score.precision, greaterThanOrEqualTo(0.95));
      expect(score.startAccuracy, 1);
    });

    test('rejects off-guide scribbling even with lots of movement', () {
      final tracedPoints = <Offset?>[
        for (var i = 0; i <= 120; i++) Offset(10 + i.toDouble(), 80),
        null,
      ];

      final score = computeTraceScore(
        guidePoints: guidePoints,
        tracedPoints: tracedPoints,
        tolerance: 8,
      );

      expect(score.isComplete, isFalse);
      expect(score.overall, lessThan(0.45));
      expect(score.precision, lessThan(0.2));
    });

    test('penalizes traces that begin far from the start point', () {
      final tracedPoints = <Offset?>[
        for (final point in guidePoints.reversed) point,
        null,
      ];

      final score = computeTraceScore(
        guidePoints: guidePoints,
        tracedPoints: tracedPoints,
        tolerance: 8,
      );

      expect(score.isComplete, isFalse);
      expect(score.startAccuracy, 0);
    });
  });

  group('buildPracticeGuidePath', () {
    test('uses authored stroke guides for Ol Chiki and ASCII numerals', () {
      final olChikiPath = buildPracticeGuidePath(const Size.square(200), '᱑');
      final asciiPath = buildPracticeGuidePath(const Size.square(200), '1');

      final olChikiPoints = samplePath(olChikiPath, samplesPerMetric: 64);
      final asciiPoints = samplePath(asciiPath, samplesPerMetric: 64);

      expect(olChikiPoints, isNotEmpty);
      expect(asciiPoints.length, olChikiPoints.length);
      expect(asciiPoints.first, olChikiPoints.first);
    });
  });
}
