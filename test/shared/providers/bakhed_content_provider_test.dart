import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';

class FakeBakhedDbService implements AppwriteDbService {
  Map<String, List<Map<String, dynamic>>> collections = {};
  bool shouldThrow = false;
  int listRequests = 0;

  @override
  Future<List<Map<String, dynamic>>> listDocuments(
    String collectionId, {
    List<String>? queries,
    bool paginate = true,
    int pageSize = 500,
  }) async {
    listRequests++;
    if (shouldThrow) throw StateError('offline');
    return collections[collectionId] ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

Map<String, List<Map<String, dynamic>>> _sampleRows() {
  return {
    'bakhed_lyrics': [
      {
        '\$id': 'l1',
        'lineIndex': 0,
        'startMs': 0,
        'endMs': 1200,
        'olChiki': 'ᱡᱚᱦᱟᱨ',
        'latin': 'Johar',
        'meaning': 'Greetings',
      },
    ],
    'bakhed_vocabulary': [
      {
        '\$id': 'v1',
        'olChiki': 'ᱥᱮᱨᱮᱧ',
        'latin': 'Sereng',
        'meaning': 'Song',
        'audioFileId': 'audio1',
        'sortOrder': 0,
      },
    ],
    'bakhed_cultural_notes': [
      {
        '\$id': 'n1',
        'title': 'Sohrai',
        'body': 'Harvest festival',
        'source': 'Elders',
        'isPublished': true,
      },
    ],
  };
}

void main() {
  group('BakhedLearningContent offline cache', () {
    setUpAll(() async {
      Hive.init('test_hive_bakhed_v2');
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

    test('serves Hive-cached content when Appwrite is unreachable', () async {
      await CacheService.set(
        'bakhed_content_r1',
        _sampleContent().toCacheJson(),
      );
      final fakeDb = FakeBakhedDbService()..shouldThrow = true;
      final container = ProviderContainer(
        overrides: [appwriteDbServiceProvider.overrideWithValue(fakeDb)],
      );
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('r1').future,
      );

      expect(content.lyrics.map((line) => line.id), ['l1']);
      expect(content.vocabulary.map((item) => item.id), ['v1']);
      expect(content.culturalNotes.map((note) => note.noteId), ['n1']);
    });

    test('fetches once and persists for the next offline open', () async {
      final fakeDb = FakeBakhedDbService()..collections = _sampleRows();
      final container = ProviderContainer(
        overrides: [appwriteDbServiceProvider.overrideWithValue(fakeDb)],
      );
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('r1').future,
      );

      expect(content.lyrics.map((line) => line.id), ['l1']);
      expect(fakeDb.listRequests, 3);

      final cached = await CacheService.get(
        'bakhed_content_r1',
        BakhedLearningContent.fromCacheJson,
      );
      expect(cached?.lyrics.map((line) => line.id), ['l1']);
      expect(cached?.vocabulary.single.audioFileId, 'audio1');
    });

    test('blank id returns empty without touching the network', () async {
      final fakeDb = FakeBakhedDbService();
      final container = ProviderContainer(
        overrides: [appwriteDbServiceProvider.overrideWithValue(fakeDb)],
      );
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('   ').future,
      );

      expect(content.isEmpty, isTrue);
      expect(fakeDb.listRequests, 0);
    });
  });
}
