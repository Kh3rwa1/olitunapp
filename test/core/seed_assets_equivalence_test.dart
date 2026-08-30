import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the bundled seed content assets consumed by
/// VocabSeeder, SentenceSeeder, WordsNotifier.seed(), and
/// SentencesNotifier.seed().
void main() {
  const expectedCounts = <String, int>{
    'assets/seed/vocab_lessons.json': 14,
    'assets/seed/sentence_lessons.json': 23,
    'assets/seed/words.json': 415,
    'assets/seed/sentences.json': 250,
  };

  String? latinText(Map<String, dynamic> item) =>
      (item['titleLatin'] ?? item['wordLatin'] ?? item['sentenceLatin'])
          as String?;

  test('seed assets load, decode, and keep expected item counts', () async {
    for (final entry in expectedCounts.entries) {
      final raw =
          jsonDecode(await rootBundle.loadString(entry.key)) as List<dynamic>;
      expect(raw.length, entry.value, reason: '${entry.key} item count');

      for (final item in raw.cast<Map<String, dynamic>>()) {
        final id = item['id'] as String?;
        expect(id, isNotEmpty, reason: entry.key);
        expect(latinText(item), isNotEmpty, reason: 'latin text of $id');
        if (item.containsKey('meaning')) {
          expect(item['meaning'], isNotEmpty, reason: 'meaning of $id');
        }
      }
    }
  });

  test('lesson assets keep non-empty block lists', () async {
    for (final path in [
      'assets/seed/vocab_lessons.json',
      'assets/seed/sentence_lessons.json',
    ]) {
      final raw =
          jsonDecode(await rootBundle.loadString(path)) as List<dynamic>;
      for (final lesson in raw.cast<Map<String, dynamic>>()) {
        final blocks = lesson['blocks'] as List<dynamic>;
        expect(blocks, isNotEmpty, reason: 'blocks of ${lesson['id']}');
        for (final block in blocks) {
          expect((block as Map<String, dynamic>)['type'], isNotEmpty);
        }
      }
    }
  });

  test('seed assets stay in sync with pubspec asset declarations', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('assets/seed/'), isTrue);
    for (final path in expectedCounts.keys) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
