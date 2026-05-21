import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/logging/app_logger.dart';

void main() {
  group('AppLogger', () {
    test('keeps simple debug output human-readable', () {
      expect(AppLogger.formatForTesting('loaded'), 'loaded');
      expect(
        AppLogger.formatForTesting('loaded', name: 'Cache'),
        '[Cache] loaded',
      );
    });

    test('emits structured JSON when fields are supplied', () {
      final encoded = AppLogger.formatForTesting(
        'load failed',
        name: 'Cache',
        fields: {'key': 'lessons', 'attempt': 2},
      );

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['level'], 'debug');
      expect(decoded['message'], '[Cache] load failed');
      expect(decoded['fields'], {'key': 'lessons', 'attempt': 2});
    });
  });
}
