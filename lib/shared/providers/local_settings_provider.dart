import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/hive_service.dart';

// ============== APP SETTINGS ==============
// These are global app settings, not specific to the user profile stats.

final shellTabIndexProvider = StateProvider<int>((ref) => 0);

final themeModeProvider = StateProvider<String>((ref) {
  return prefs.getString('theme_mode') ?? 'light';
});

final scriptModeProvider = StateProvider<String>((ref) {
  return prefs.getString('script_mode') ?? 'both';
});

final soundEnabledProvider = StateProvider<bool>((ref) {
  return prefs.getBool('sound_enabled') ?? true;
});

void updateThemeMode(WidgetRef ref, String mode) {
  prefs.setString('theme_mode', mode);
  ref.read(themeModeProvider.notifier).state = mode;
}

void updateScriptMode(WidgetRef ref, String mode) {
  prefs.setString('script_mode', mode);
  ref.read(scriptModeProvider.notifier).state = mode;
}

void toggleSound(WidgetRef ref) {
  final current = ref.read(soundEnabledProvider);
  prefs.setBool('sound_enabled', !current);
  ref.read(soundEnabledProvider.notifier).state = !current;
}
