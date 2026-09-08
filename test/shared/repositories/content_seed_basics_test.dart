import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/models/content_item_extensions.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/shared/repositories/content_seed_loader.dart';

class _Databases extends Mock implements Databases {}
class _Network extends Mock implements NetworkInfo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late _Databases databases;
  late _Network network;
  late ContentRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('olitun_basic_seeds_');
    Hive.init(directory.path);
    CacheService.resetForTesting();
    databases = _Databases();
    network = _Network();
    repository = ContentRepository(databases: databases, networkInfo: network);
  });

  tearDown(() async {
    await Hive.close();
    CacheService.resetForTesting();
    await directory.delete(recursive: true);
  });

  const counts = {ContentKind.letter: 30, ContentKind.number: 10};
  for (final entry in counts.entries) {
    test('fresh ${entry.key.name} catalog needs neither cache nor network', () async {
      final result = await repository.cachedList(entry.key);
      result.fold((failure) => fail('$failure'), (items) {
        expect(items.length, entry.value);
        expect(items.map((item) => item.id).toSet().length, entry.value);
        expect(items.map((item) => item.order), List.generate(entry.value, (i) => i));
        for (final item in items) {
          expect(item.kind, entry.key);
          expect(item.title, isNotEmpty);
          expect(item.olChiki, isNotEmpty);
          expect(item.isPublished, isTrue);
          expect(item.isPremium, isFalse);
          expect(ContentItem.fromJson(item.toJson(), null, entry.key), item);
        }
      });
      verifyZeroInteractions(databases);
      verifyZeroInteractions(network);
    });
  }

  test('offline list and individual detail reads use the real bundled catalog', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);
    for (final entry in counts.entries) {
      final result = await repository.list(entry.key, categoryId: 'legacy_category');
      result.fold((failure) => fail('$failure'), (items) => expect(items.length, entry.value));
    }
    final letter = await repository.get(ContentKind.letter, 'l_la');
    letter.fold((failure) => fail('$failure'), (item) {
      expect(item.toLetterModel().charOlChiki, 'ᱚ');
      expect(item.title, 'La (a)');
    });
    final number = await repository.get(ContentKind.number, 'n_3');
    number.fold((failure) => fail('$failure'), (item) {
      expect(item.toNumberModel().value, 3);
      expect(item.toNumberModel().numeral, '᱓');
      expect(item.toNumberModel().nameLatin, 'Pe');
    });
    verifyZeroInteractions(databases);
  });

  test('all ten numbers preserve their numeral, value and name', () async {
    final items = await ContentSeedLoader.loadBundledSeedItems(ContentKind.number, null);
    for (var i = 0; i < 10; i++) {
      final number = items[i].toNumberModel();
      expect(number.value, i);
      expect(number.numeral, String.fromCharCode(0x1c50 + i));
      expect(number.nameLatin, isNotEmpty);
      expect(number.nameOlChiki, isNotEmpty);
    }
  });

  test('newer cached content overrides a bundled ID without duplication', () async {
    final items = await ContentSeedLoader.loadBundledSeedItems(ContentKind.number, null);
    final updated = items[3].copyWith(title: 'Updated cached number');
    expect(await CacheService.set('content_list_number_all', [updated.toJson()]), isTrue);
    final result = await repository.cachedList(ContentKind.number);
    result.fold((failure) => fail('$failure'), (merged) {
      expect(merged.length, 10);
      expect(merged.singleWhere((item) => item.id == 'n_3').title, updated.title);
    });
    verifyZeroInteractions(databases);
    verifyZeroInteractions(network);
  });

  test('unknown IDs still return a failure', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);
    expect((await repository.get(ContentKind.number, 'missing-number')).isLeft(), isTrue);
    expect((await repository.get(ContentKind.letter, 'missing-letter')).isLeft(), isTrue);
    verifyZeroInteractions(databases);
  });

  test('bundling read-only basics does not weaken tracing write validation', () async {
    for (final kind in counts.keys) {
      final items = await ContentSeedLoader.loadBundledSeedItems(kind, null);
      for (final item in items) {
        expect(item.tracing, isNull);
        expect(() => ContentItem.validate(kind, item.tracing),
            throwsA(isA<ContentValidationException>()));
      }
    }
  });
}
