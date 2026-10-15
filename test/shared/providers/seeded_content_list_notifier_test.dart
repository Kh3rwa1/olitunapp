import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_content_client.dart';
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/shared/providers/seeded_content_list_notifier.dart';

import '../../helpers/fake_admin_worker.dart';

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
  String get collectionId => 'words';

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
  Future<List<_Item>> loadList() async {
    loadListCalls++;
    try {
      final remote = await fetchRemote();
      return remote..sort((a, b) => itemOrder(a).compareTo(itemOrder(b)));
    } catch (_) {
      return List.of(seedItems);
    }
  }
}

typedef _Provider =
    AsyncNotifierProvider<SeededContentListNotifier<_Item>, List<_Item>>;

_Provider _providerOf(_TestNotifier notifier) => _Provider(() => notifier);

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  const seed = [_Item('s_2', 2), _Item('s_1', 1)];

  late FakeAdminWorker worker;
  late List<Map<String, dynamic>> edgeRows;
  late int edgeStatus;
  late List<Uri> edgeRequests;

  setUp(() {
    worker = FakeAdminWorker();
    edgeRows = const [];
    edgeStatus = 200;
    edgeRequests = [];
  });

  Future<(ProviderContainer, _Provider)> harness(_TestNotifier notifier) async {
    final container = ProviderContainer(
      overrides: [
        adminContentClientProvider.overrideWithValue(worker.adminClient),
        seededContentHttpClientProvider.overrideWithValue(
          MockClient((request) async {
            edgeRequests.add(request.url);
            return http.Response(
              jsonEncode({'ok': true, 'words': edgeRows}),
              edgeStatus,
            );
          }),
        ),
      ],
    );
    return (container, _providerOf(notifier));
  }

  test('build starts in loading and then emits the loaded list', () async {
    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);

    expect(container.read(p).isLoading, isTrue);
    await _flush();

    // _TestNotifier.loadList treats the (empty) Worker list as authoritative.
    expect(container.read(p).value, isEmpty);
    expect(notifier.loadListCalls, 1);
    expect(edgeRequests.single.path, '/api/v1/words');
    expect(worker.requests, isEmpty);
  });

  test('fetchRemote maps documents and emits them sorted by order', () async {
    edgeRows = [
      {'id': 'r_9', 'order': 9},
      {'id': 'r_3', 'order': 3},
    ];

    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);

    container.read(p);
    await _flush();
    await _flush();

    final value = container.read(p).value!;
    expect(value.map((e) => e.id), ['r_3', 'r_9']);
    expect(worker.requests, isEmpty);
  });

  test('loadList falls back to the seed when the Worker fetch fails', () async {
    edgeStatus = 503;

    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);

    container.read(p);
    await _flush();

    expect(container.read(p).value!.map((e) => e.id), ['s_2', 's_1']);
  });

  test('add PUTs to the Worker admin route and reloads', () async {
    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);
    container.read(p);
    await _flush();

    await container.read(p.notifier).add(const _Item('n_1', 5));

    final put = worker.requestsWith('PUT').single;
    expect(put.url.path, '/api/v1/admin/content/words/n_1');
    expect(put.headers['Authorization'], 'Bearer ${FakeAdminWorker.jwt}');
    expect(worker.bodyOf(put), {'order': 5});
    expect(notifier.loadListCalls, greaterThanOrEqualTo(2));
  });

  test('update and delete target the item id and reload', () async {
    worker.rows['words'] = {
      's_2': {'id': 's_2', 'order': 2},
    };
    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);
    container.read(p);
    await _flush();

    await container.read(p.notifier).updateItem(const _Item('s_1', 1));
    await container.read(p.notifier).delete('s_2');

    expect(
      worker.requestsWith('PUT').single.url.path,
      '/api/v1/admin/content/words/s_1',
    );
    expect(
      worker.requestsWith('DELETE').single.url.path,
      '/api/v1/admin/content/words/s_2',
    );
    expect(worker.rows['words']!.keys, ['s_1']);
  });

  test(
    'rethrowCrudErrors defaults to true and is honoured on failure',
    () async {
      final notifier = _TestNotifier(seed);
      expect(notifier.rethrowCrudErrors, isTrue);
      worker.failStatus = 403;

      final (container, p) = await harness(notifier);
      addTearDown(container.dispose);
      container.read(p);
      await _flush();

      await expectLater(
        container.read(p.notifier).delete('s_2'),
        throwsA(
          isA<EdgeApiException>().having((e) => e.statusCode, 'status', 403),
        ),
      );
    },
  );

  test('seed backfills only the ids missing remotely', () async {
    // seed() is an admin backfill: it lists the full admin table.
    worker.rows['words'] = {
      's_1': {'id': 's_1', 'order': 1},
    };

    final notifier = _TestNotifier(seed);
    final (container, p) = await harness(notifier);
    addTearDown(container.dispose);
    container.read(p);
    await _flush();

    await container.read(p.notifier).seed();

    // s_1 already exists remotely; only s_2 is backfilled.
    expect(
      worker.requestsWith('GET').single.url.path,
      '/api/v1/admin/content/words',
    );
    expect(worker.requestsWith('PUT').map((r) => r.url.path), [
      '/api/v1/admin/content/words/s_2',
    ]);
  });
}
