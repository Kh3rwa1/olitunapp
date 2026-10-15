import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerAt(
    DateTime now, [
    Map<String, Object> prefsValues = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        missionClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('currentDateProvider is the device clock as a UTC date', () async {
    final container = await containerAt(DateTime.utc(2026, 10, 15, 23, 59));
    expect(container.read(currentDateProvider), '2026-10-15');
  });

  test('a mission completed today reads as complete', () async {
    final container = await containerAt(DateTime.utc(2026, 10, 15, 8), {
      'mission_quiz_taken_date': '2026-10-15',
    });
    expect(container.read(quizTakenTodayProvider), isTrue);
    expect(container.read(lessonCompletedTodayProvider), isFalse);
  });

  test('a mission completed on an earlier day reads as incomplete', () async {
    final container = await containerAt(DateTime.utc(2026, 10, 16, 0, 1), {
      'mission_quiz_taken_date': '2026-10-15',
    });
    expect(container.read(quizTakenTodayProvider), isFalse);
  });

  test('setCompleted persists today and toggles back', () async {
    final container = await containerAt(DateTime.utc(2026, 10, 15, 8));
    final notifier = container.read(bakhedListenedTodayProvider.notifier);

    await notifier.setCompleted(true);
    expect(container.read(bakhedListenedTodayProvider), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mission_bakhed_listened_date'), '2026-10-15');

    await notifier.toggle();
    expect(container.read(bakhedListenedTodayProvider), isFalse);
    expect(prefs.getString('mission_bakhed_listened_date'), isNull);
  });
}
