import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';

/// Fake Worker for `/api/v1/bakhed/content`.
class FakeBakhedEdge {
  Map<String, dynamic>? payload;
  bool shouldFail = false;
  int requests = 0;

  http.Client get client => MockClient((request) async {
    requests++;
    if (shouldFail) return http.Response('unavailable', 503);
    return http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'ok': true,
          'bakhedId': request.url.queryParameters['id'],
          ...?payload,
        }),
      ),
      200,
      headers: const {'content-type': 'application/json'},
    );
  });
}

ProviderContainer _containerFor(FakeBakhedEdge edge) => ProviderContainer(
  overrides: [bakhedContentHttpClientProvider.overrideWithValue(edge.client)],
);

BakhedLearningContent _sampleContent() {
  return const BakhedLearningContent(
    lyrics: [
      BakhedLyricLine(
        id: 'l1',
        lineIndex: 0,
        startMs: 0,
        endMs: 1200,
        olChiki: 'ᱡᱚᱦᱟᱨ',
        latin: 'Johar',
        meaning: 'Greetings',
      ),
    ],
    vocabulary: [
      BakhedVocabularyItem(
        id: 'v1',
        olChiki: 'ᱥᱮᱨᱮᱧ',
        latin: 'Sereng',
        meaning: 'Song',
        audioFileId: 'audio1',
        sortOrder: 0,
      ),
    ],
    culturalNotes: [
      BakhedCulturalNote(
        noteId: 'n1',
        title: 'Sohrai',
        body: 'Harvest festival',
        source: 'Elders',
        isPublished: true,
      ),
    ],
  );
}

void main() {
  group('BakhedLearningContent offline cache', () {
    setUpAll(() async {
      Hive.init(
        (await Directory.systemTemp.createTemp('test_hive_bakhed_v2_')).path,
      );
      CacheService.resetForTesting();
    });

    tearDownAll(() async {
      await CacheService.clear();
    });

    setUp(() async {
      await CacheService.clear();
    });

    test('cache JSON round-trips lyrics, vocabulary and notes', () {
      final content = _sampleContent();
      final restored = BakhedLearningContent.fromCacheJson(
        content.toCacheJson(),
      );

      expect(restored.lyrics.map((line) => line.id), ['l1']);
      expect(restored.lyrics.single.olChiki, 'ᱡᱚᱦᱟᱨ');
      expect(restored.vocabulary.map((item) => item.id), ['v1']);
      expect(restored.vocabulary.single.audioFileId, 'audio1');
      expect(restored.culturalNotes.map((note) => note.noteId), ['n1']);
      expect(restored.culturalNotes.single.isPublished, isTrue);
    });

    test('serves Hive-cached content when the Worker is unreachable', () async {
      await CacheService.set(
        'bakhed_content_r1',
        _sampleContent().toCacheJson(),
      );
      final edge = FakeBakhedEdge()..shouldFail = true;
      final container = _containerFor(edge);
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('r1').future,
      );

      expect(content.lyrics.map((line) => line.id), ['l1']);
      expect(content.vocabulary.map((item) => item.id), ['v1']);
      expect(content.culturalNotes.map((note) => note.noteId), ['n1']);
    });

    test('fetches once and persists for the next offline open', () async {
      final edge = FakeBakhedEdge()..payload = _sampleContent().toCacheJson();
      final container = _containerFor(edge);
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('r1').future,
      );

      expect(content.lyrics.map((line) => line.id), ['l1']);
      expect(edge.requests, 1);

      final cached = await CacheService.get(
        'bakhed_content_r1',
        BakhedLearningContent.fromCacheJson,
      );
      expect(cached?.lyrics.map((line) => line.id), ['l1']);
      expect(cached?.vocabulary.single.audioFileId, 'audio1');
    });

    test('empty Worker payload is a valid empty result', () async {
      final edge = FakeBakhedEdge();
      final container = _containerFor(edge);
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('r2').future,
      );

      expect(content.isEmpty, isTrue);
      expect(edge.requests, 1);
    });

    test('Worker failure with nothing cached yields empty content', () async {
      final edge = FakeBakhedEdge()..shouldFail = true;
      final container = _containerFor(edge);
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('r3').future,
      );

      expect(content.isEmpty, isTrue);
      expect(edge.requests, 1);
    });

    test('blank id returns empty without touching the network', () async {
      final edge = FakeBakhedEdge();
      final container = _containerFor(edge);
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('   ').future,
      );

      expect(content.isEmpty, isTrue);
      expect(edge.requests, 0);
    });
  });
}
