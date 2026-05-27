import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/practice/data/typing_practice_settings.dart';

void main() {
  group('TypingPracticeSettings', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('1. Defaults to enabled = true, lenientPunctuation = true when prefs are empty', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final settings = container.read(typingPracticeSettingsProvider);
      expect(settings.enabled, isTrue);
      expect(settings.lenientPunctuation, isTrue);
    });

    test('2. Restores saved settings from SharedPreferences', () {
      prefs.setBool('typing_practice_enabled', false);
      prefs.setBool('typing_lenient_punctuation', false);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final settings = container.read(typingPracticeSettingsProvider);
      expect(settings.enabled, isFalse);
      expect(settings.lenientPunctuation, isFalse);
    });

    test('3. toggleEnabled and setEnabled persists updates in SharedPreferences', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(typingPracticeSettingsProvider.notifier);

      expect(container.read(typingPracticeSettingsProvider).enabled, isTrue);

      await notifier.toggleEnabled();
      expect(container.read(typingPracticeSettingsProvider).enabled, isFalse);
      expect(prefs.getBool('typing_practice_enabled'), isFalse);

      await notifier.setEnabled(true);
      expect(container.read(typingPracticeSettingsProvider).enabled, isTrue);
      expect(prefs.getBool('typing_practice_enabled'), isTrue);
    });

    test('4. toggleLenientPunctuation persists update in SharedPreferences', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(typingPracticeSettingsProvider.notifier);

      expect(container.read(typingPracticeSettingsProvider).lenientPunctuation, isTrue);

      await notifier.toggleLenientPunctuation();
      expect(container.read(typingPracticeSettingsProvider).lenientPunctuation, isFalse);
      expect(prefs.getBool('typing_lenient_punctuation'), isFalse);
    });
  });
}
