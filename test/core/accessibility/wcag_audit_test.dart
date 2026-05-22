import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/accessibility/wcag_audit.dart';

void main() {
  group('WcagAudit', () {
    test('calculates WCAG AA contrast thresholds', () {
      expect(
        WcagAudit.contrastRatio(Colors.black, Colors.white),
        closeTo(21, 0.01),
      );
      expect(WcagAudit.passesNormalText(Colors.black, Colors.white), isTrue);
      expect(WcagAudit.passesLargeText(Colors.grey, Colors.white), isFalse);
    });

    test('checks minimum 48dp tap targets', () {
      expect(WcagAudit.hasMinimumTapTarget(const Size(48, 48)), isTrue);
      expect(WcagAudit.hasMinimumTapTarget(const Size(47, 60)), isFalse);
    });

    test('documents the dynamic type audit scale up to 200 percent', () {
      expect(WcagAudit.supportedTextScales, containsAll([1.5, 2]));
    });
  });
}
