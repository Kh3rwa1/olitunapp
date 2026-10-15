import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/rhymes/presentation/providers/listened_bakhed_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('restores previously listened ids on first read', () async {
    final container = await containerWith({
      'listened_bakhed_ids': ['b1', 'b2'],
    });

    expect(container.read(listenedBakhedProvider), {'b1', 'b2'});
  });

  test('markListened updates state and persists', () async {
    final container = await containerWith({});

    await container.read(listenedBakhedProvider.notifier).markListened('b3');

    expect(container.read(listenedBakhedProvider), {'b3'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('listened_bakhed_ids'), ['b3']);
  });
}
