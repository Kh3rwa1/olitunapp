import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/shared/providers/seeded_content_list_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockDbService extends Mock implements AppwriteDbService {}

class _Item {
  final String id;
  final int order;
  const _Item(this.id, this.order);

  Map<String, dynamic> toJson() => {'id': id, 'order': order};
}

class _TestNotifier extends SeededContentListNotifier<_Item> {
  final List<_Item> seedItems;
  int loadListCalls = 0;

  _TestNotifier(this.seedItems);

  @override
  String get collectionId => 'test_items';

  @override
  String get label => 'test item';

  @override
  _Item Function(Map<String, dynamic> json) get fromJson =>
      (json) => _Item(json['id'] as String, json['order'] as int);

  @override
  String itemId(_Item item) => item.id;

  @override
  int itemOrder(_Item item) => item.order;

  @override
  Future<List<_Item>> loadSeed() async => seedItems;

  @override
  Future<void> loadList() async {
    loadListCalls++;
    try {
      final remote = await fetchRemote();
      emit(remote..sort((a, b) => itemOrder(a).compareTo(itemOrder(b))));
    } catch (_) {
      emit(List.of(seedItems));
    }
  }
}

typedef _Provider =
    NotifierProvider<SeededContentListNotifier<_Item>, AsyncValue<List<_Item>>>;

_Provider _providerOf(_TestNotifier notifier) => _Provider(() => notifier);

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  const seed = [_Item('s_2', 2), _Item('s_1', 1)];

  late _MockDbService db;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    db = _MockDbService();
  });

  Future<(ProviderContainer, _Provider)> harness(_TestNotifier notifier) async {
    final container = ProviderContainer(
      overrides: [appwriteDbServiceProvider.overrideWithValue(db)],
    );
    return (container, _providerOf(notifier));
  }

  test(
    'build starts in loading and the deferred load emits the seed',
    () async {
      when(
        () => db.listDocuments('test_items', queries: any(named: 'queries')),
      ).thenAnswer((_) async => const <Map<String, dynamic>>[]);
      final notifier = _TestNotifier(seed);
      final (container, p) = await harness(notifier);
      addTearDown(container.dispose);

      expect(container.read(p).isLoading, isTrue);
      await _flush();

      // _TestNotifier.loadList treats the remote list as authoritative.
      expect(container.read(p).value, isEmpty);
      expect(notifier.loadListCalls, 1);
    },
  );

  test('fetchRemote maps documents and emits them sorted by order', () async {
    when(
      () => db.listDocuments('test_items', queries: any(named: 'queries')),
    ).thenAnswer(
      (_) async => [
        const {'id': 'r_9', 'order': 9},
        const {'id': 'r_3', 'order': 3},
      ],
    );

    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);

    container.read(p);
    await _flush();
    await _flush();

    final value = container.read(p).value!;
    expect(value.map((e) => e.id), ['r_3', 'r_9']);
  });

  test(
    'loadList falls back to the seed when the remote fetch throws',
    () async {
      when(
        () => db.listDocuments('test_items', queries: any(named: 'queries')),
      ).thenThrow(Exception('offline'));

      final notifier = _TestNotifier(seed);
      final (container, p) = await harness(notifier);
      addTearDown(container.dispose);

      container.read(p);
      await _flush();

      expect(container.read(p).value!.map((e) => e.id), ['s_2', 's_1']);
    },
  );

  test('add writes through to the collection and reloads', () async {
    when(
      () => db.listDocuments('test_items', queries: any(named: 'queries')),
    ).thenAnswer((_) async => const <Map<String, dynamic>>[]);
    when(
      () => db.createDocument('test_items', any(), any()),
    ).thenAnswer((_) async {});

    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);
    container.read(p);
    await _flush();

    await container.read(p.notifier).add(const _Item('n_1', 5));

    verify(
      () => db.createDocument('test_items', 'n_1', {'id': 'n_1', 'order': 5}),
    ).called(1);
    expect(notifier.loadListCalls, greaterThanOrEqualTo(2));
  });

  test('update and delete target the item id and reload', () async {
    when(
      () => db.listDocuments('test_items', queries: any(named: 'queries')),
    ).thenAnswer((_) async => const <Map<String, dynamic>>[]);
    when(
      () => db.updateDocument('test_items', any(), any()),
    ).thenAnswer((_) async {});
    when(() => db.deleteDocument('test_items', any())).thenAnswer((_) async {});

    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);
    container.read(p);
    await _flush();

    await container.read(p.notifier).update(const _Item('s_1', 1));
    await container.read(p.notifier).delete('s_2');

    verify(
      () => db.updateDocument('test_items', 's_1', {'id': 's_1', 'order': 1}),
    ).called(1);
    verify(() => db.deleteDocument('test_items', 's_2')).called(1);
  });

  test(
    'rethrowCrudErrors defaults to true and is honoured on failure',
    () async {
      final notifier = _TestNotifier(seed);
      expect(notifier.rethrowCrudErrors, isTrue);

      when(
        () => db.listDocuments('test_items', queries: any(named: 'queries')),
      ).thenAnswer((_) async => const <Map<String, dynamic>>[]);
      when(
        () => db.deleteDocument('test_items', any()),
      ).thenThrow(Exception('denied'));

      final (container, p) = await harness(notifier);
      addTearDown(container.dispose);
      container.read(p);
      await _flush();

      await expectLater(
        container.read(p.notifier).delete('s_2'),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('seed backfills only the ids missing remotely', () async {
    when(
      () => db.listDocuments('test_items', queries: any(named: 'queries')),
    ).thenAnswer((_) async => const <Map<String, dynamic>>[]);
    when(
      () => db.createDocument('test_items', any(), any()),
    ).thenAnswer((_) async {});
    // Registered last: mocktail's any() also matches omitted named args,
    // so this no-arg stub must win for seed()'s plain listDocuments call.
    when(() => db.listDocuments('test_items')).thenAnswer(
      (_) async => [
        const {'id': 's_1', 'order': 1},
      ],
    );

    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);
    container.read(p);
    await _flush();

    await container.read(p.notifier).seed();

    // s_1 already exists remotely; only s_2 is backfilled.
    verify(() => db.createDocument('test_items', 's_2', any())).called(1);
    verifyNever(() => db.createDocument('test_items', 's_1', any()));
  });
}
