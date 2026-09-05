import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';

class _AttrSpec {
  final String key;
  final String type;
  final int? size;
  final bool isArray;
  final bool required;
  final List<String>? enumValues;
  final int? min;
  final int? max;
  _AttrSpec.fromJson(Map<String, dynamic> j)
    : key = j['key'] as String,
      type = j['type'] as String,
      size = (j['size'] as num?)?.toInt(),
      isArray = (j['array'] as bool?) ?? false,
      required = (j['required'] as bool?) ?? false,
      enumValues = (j['elements'] as List?)?.cast<String>(),
      min = (j['min'] as num?)?.toInt(),
      max = (j['max'] as num?)?.toInt();
}

Map<String, _AttrSpec> _loadSchema(String collectionId) {
  final file = File('test/fixtures/schema/$collectionId.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final attrs = (json['attributes'] as List).cast<Map<String, dynamic>>();
  return {for (final a in attrs) a['key'] as String: _AttrSpec.fromJson(a)};
}

void _assertConforms(
  Map<String, dynamic> payload,
  Map<String, _AttrSpec> schema,
) {
  for (final entry in payload.entries) {
    final spec = schema[entry.key];
    if (spec == null) continue; // unknown keys (e.g. $id) are ignored
    final value = entry.value;
    if (value == null) continue;

    // Array flag check
    if (spec.isArray) {
      expect(value, isA<List>(), reason: '${entry.key} should be a List');
    } else {
      expect(
        value,
        isNot(isA<List>()),
        reason: '${entry.key} should not be a List',
      );
    }

    // Type check
    switch (spec.type) {
      case 'string':
        final values = spec.isArray ? (value as List).cast() : [value];
        for (final v in values) {
          expect(
            v,
            isA<String>(),
            reason: '${entry.key} entry should be String',
          );
          if (spec.size != null) {
            expect(
              (v as String).length,
              lessThanOrEqualTo(spec.size!),
              reason: '${entry.key} exceeds size ${spec.size}',
            );
          }
          if (spec.enumValues != null) {
            expect(
              spec.enumValues,
              contains(v),
              reason: '${entry.key} value "$v" not in enum ${spec.enumValues}',
            );
          }
        }
        break;
      case 'integer':
        expect(value, isA<int>(), reason: '${entry.key} should be int');
        if (spec.min != null) {
          expect(value as int, greaterThanOrEqualTo(spec.min!));
        }
        if (spec.max != null) {
          expect(value as int, lessThanOrEqualTo(spec.max!));
        }
        break;
      case 'boolean':
        expect(value, isA<bool>(), reason: '${entry.key} should be bool');
        break;
    }
  }

  // Required fields present
  for (final entry in schema.entries) {
    if (entry.value.required) {
      expect(
        payload.containsKey(entry.key),
        isTrue,
        reason: 'Required field ${entry.key} missing from payload',
      );
    }
  }
}

void main() {
  group('rhymes schema conformance', () {
    final schema = _loadSchema('rhymes');

    test('minimal rhyme payload conforms', () {
      final item = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        categoryId: 'cat_sohrai',
        title: 'x',
        blocks: const [],
        updatedAt: DateTime.now(),
      );
      _assertConforms(item.toAppwrite(), schema);
    });

    test('rhyme with many tags conforms (legacy + tagsList)', () {
      final item = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        categoryId: 'cat_sohrai',
        title: 'x',
        tags: const [
          'culture',
          'song',
          'sohrai',
          'traditional',
          'folk',
          'ritual',
        ],
        blocks: const [],
        updatedAt: DateTime.now(),
      );
      _assertConforms(item.toAppwrite(), schema);
    });

    test('rhyme with audio fields conforms', () {
      final item = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        categoryId: 'cat_sohrai',
        title: 'x',
        audioUrl: 'https://example.com/a.mp3',
        audioFileId:
            'abc1234567890123456789012345678901234567890123456789012345678901',
        durationMs: 180000,
        blocks: const [],
        updatedAt: DateTime.now(),
      );
      _assertConforms(item.toAppwrite(), schema);
    });

    test('rhyme with all optional fields conforms', () {
      final item = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        title: 'x',
        titleOlChiki: 'x',
        tags: const ['a', 'b'],
        categoryId: 'cat_sohrai',
        audioUrl: 'https://example.com/a.mp3',
        audioFileId:
            'abc1234567890123456789012345678901234567890123456789012345678901',
        durationMs: 180000,
        heroMedia: const ContentMedia(
          url: 'https://example.com/t.png',
          fileId: 'thumb123',
          kind: ContentMediaKind.image,
        ),
        difficulty: 'easy',
        blocks: const [],
        updatedAt: DateTime.now(),
      );
      _assertConforms(item.toAppwrite(), schema);
    });

    test('premium rhyme schema conforms and generic publication is denied', () {
      final item = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        title: 'x',
        titleOlChiki: 'x',
        tags: const ['a', 'b'],
        categoryId: 'cat_sohrai',
        audioUrl: 'https://example.com/a.mp3',
        audioFileId:
            'abc1234567890123456789012345678901234567890123456789012345678901',
        durationMs: 180000,
        heroMedia: const ContentMedia(
          url: 'https://example.com/t.png',
          fileId: 'thumb123',
          kind: ContentMediaKind.image,
        ),
        isPremium: true,
        difficulty: 'easy',
        blocks: const [],
        updatedAt: DateTime.now(),
      );
      _assertConforms(item.toAppwriteAttributes(), schema);
      expect(item.toAppwrite, throwsA(isA<StateError>()));
    });
  });

  group('bakhed_lyrics schema conformance', () {
    final schema = _loadSchema('bakhed_lyrics');

    test('minimal bakhed_lyric payload conforms', () {
      const line = BakhedLyricLine(
        id: 'l1',
        lineIndex: 0,
        startMs: 0,
        endMs: 0,
        olChiki: '',
        latin: '',
        meaning: '',
      );
      _assertConforms(line.toJson('rhyme_1'), schema);
    });

    test('full bakhed_lyric payload conforms', () {
      const line = BakhedLyricLine(
        id: 'l1',
        lineIndex: 5,
        startMs: 10000,
        endMs: 15000,
        olChiki: 'ᱴᱮᱥᱴ ᱞᱟᱭᱤᱱ',
        latin: 'Test line',
        meaning: 'Test meaning',
      );
      _assertConforms(line.toJson('rhyme_1'), schema);
    });
  });
}
