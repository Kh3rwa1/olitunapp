import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/shared/providers/seeded_content_list_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

class _TestWord {
  final String id;
  final String word;
  final int order;
  const _TestWord(this.id, this.word, this.order);

  factory _TestWord.fromJson(Map<String, dynamic> json) => _TestWord(
    json['id'] as String,
    json['word'] as String? ?? json['wordOlChiki'] as String? ?? '',
    json['order'] as int? ?? json['orderIndex'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {'id': id, 'word': word, 'order': order};
}

class _TestWordNotifier extends SeededContentListNotifier<_TestWord> {
  @override
  String get collectionId => 'words';

  @override
  String get label => 'word';

  @override
  _TestWord Function(Map<String, dynamic> json) get fromJson =>
      _TestWord.fromJson;

  @override
  String itemId(_TestWord item) => item.id;

  @override
  int itemOrder(_TestWord item) => item.order;

  @override
  Future<List<_TestWord>> loadSeed() async => const [];

  @override
  Future<List<_TestWord>> loadList() async => fetchRemote();
}

final _testWordProvider =
    AsyncNotifierProvider<_TestWordNotifier, List<_TestWord>>(
      _TestWordNotifier.new,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppwriteDbService mockDb;

  setUp(() {
    mockDb = MockAppwriteDbService();
  });

  test(
    'SeededContentListNotifier fetches words from Cloudflare Edge without hitting Appwrite',
    () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/words')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'total': 2,
              'words': [
                {'id': 'w1', 'word': 'ᱥᱟᱱᱛᱟᱲᱤ', 'order': 1},
                {'id': 'w2', 'word': 'ᱚᱞᱪᱤᱠᱤ', 'order': 2},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          seededContentHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(container.dispose);

      final words = await container.read(_testWordProvider.future);
      expect(words.length, 2);
      expect(words[0].id, 'w1');
      expect(words[0].word, 'ᱥᱟᱱᱛᱟᱲᱤ');
      expect(words[1].id, 'w2');
      verifyNever(
        () => mockDb.listAllDocuments(any(), queries: any(named: 'queries')),
      );
    },
  );

  test(
    'SeededContentListNotifier falls back to Appwrite DB when Cloudflare edge fails',
    () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('Edge error', 500);
      });

      when(
        () => mockDb.listAllDocuments('words', queries: any(named: 'queries')),
      ).thenAnswer(
        (_) async => [
          {'id': 'db_w1', 'word': 'ᱨᱚᱲ', 'order': 1},
        ],
      );

      final container = ProviderContainer(
        overrides: [
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          seededContentHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(container.dispose);

      final words = await container.read(_testWordProvider.future);
      expect(words.length, 1);
      expect(words[0].id, 'db_w1');
      expect(words[0].word, 'ᱨᱚᱲ');
      verify(
        () => mockDb.listAllDocuments('words', queries: any(named: 'queries')),
      ).called(1);
    },
  );
}
