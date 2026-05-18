import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/hive_service.dart';

// ============== APP SETTINGS ==============
// These are global app settings, not specific to the user profile stats.

final shellTabIndexProvider = StateProvider<int>((ref) => 0);

final themeModeProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('theme_mode') ?? 'light';
});

final scriptModeProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('script_mode') ?? 'both';
});

final appLanguageProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('app_language') ?? 'en';
});

final effectiveScriptModeProvider = Provider<String>((ref) {
  final languageCode = ref.watch(appLanguageProvider);
  if (languageCode == 'sat') return 'olchiki';
  return ref.watch(scriptModeProvider);
});

final lastOpenedLessonIdProvider = StateProvider<String?>((ref) {
  final value = ref
      .read(sharedPreferencesProvider)
      .getString('last_opened_lesson_id');
  return value == null || value.isEmpty ? null : value;
});

final soundEnabledProvider = StateProvider<bool>((ref) {
  return ref.read(sharedPreferencesProvider).getBool('sound_enabled') ?? true;
});

void updateThemeMode(WidgetRef ref, String mode) {
  ref.read(sharedPreferencesProvider).setString('theme_mode', mode);
  ref.read(themeModeProvider.notifier).state = mode;
}

void updateScriptMode(WidgetRef ref, String mode) {
  ref.read(sharedPreferencesProvider).setString('script_mode', mode);
  ref.read(scriptModeProvider.notifier).state = mode;
}

void updateAppLanguage(WidgetRef ref, String languageCode) {
  final normalized = languageCode == 'sat' ? 'sat' : 'en';
  final prefs = ref.read(sharedPreferencesProvider);
  final previousLanguage = ref.read(appLanguageProvider);

  prefs.setString('app_language', normalized);
  ref.read(appLanguageProvider.notifier).state = normalized;

  if (normalized == 'sat') {
    prefs.setString('script_mode', 'olchiki');
    ref.read(scriptModeProvider.notifier).state = 'olchiki';
  } else if (previousLanguage == 'sat' &&
      ref.read(scriptModeProvider) == 'olchiki') {
    prefs.setString('script_mode', 'both');
    ref.read(scriptModeProvider.notifier).state = 'both';
  }
}

void updateLastOpenedLesson(WidgetRef ref, String lessonId) {
  final normalized = lessonId.trim();
  if (normalized.isEmpty) return;
  if (ref.read(lastOpenedLessonIdProvider) == normalized) return;

  ref
      .read(sharedPreferencesProvider)
      .setString('last_opened_lesson_id', normalized);
  ref.read(lastOpenedLessonIdProvider.notifier).state = normalized;
}

void toggleSound(WidgetRef ref) {
  final current = ref.read(soundEnabledProvider);
  ref.read(sharedPreferencesProvider).setBool('sound_enabled', !current);
  ref.read(soundEnabledProvider.notifier).state = !current;
}
