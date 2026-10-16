import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_progression_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ad-unlocked lessons persist across app restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    final first = make();
    expect(first.read(adUnlockedLessonIdsProvider), isEmpty);
    first.read(adUnlockedLessonIdsProvider.notifier).unlock('lesson_2');
    first.read(adUnlockedLessonIdsProvider.notifier).unlock('lesson_2');
    expect(first.read(adUnlockedLessonIdsProvider), {'lesson_2'});
    first.dispose();

    final second = make();
    addTearDown(second.dispose);
    expect(second.read(adUnlockedLessonIdsProvider), {'lesson_2'});
  });
}
