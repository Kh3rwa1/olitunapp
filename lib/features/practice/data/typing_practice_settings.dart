import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';

class TypingPracticeSettings {
  final bool enabled;
  final bool lenientPunctuation;

  const TypingPracticeSettings({
    required this.enabled,
    required this.lenientPunctuation,
  });

  TypingPracticeSettings copyWith({bool? enabled, bool? lenientPunctuation}) {
    return TypingPracticeSettings(
      enabled: enabled ?? this.enabled,
      lenientPunctuation: lenientPunctuation ?? this.lenientPunctuation,
    );
  }
}

class TypingPracticeSettingsNotifier extends Notifier<TypingPracticeSettings> {
  @override
  TypingPracticeSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final enabled = prefs.getBool('typing_practice_enabled') ?? true;
    final lenient = prefs.getBool('typing_lenient_punctuation') ?? true;
    return TypingPracticeSettings(
      enabled: enabled,
      lenientPunctuation: lenient,
    );
  }

  Future<void> toggleEnabled() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newEnabled = !state.enabled;
    await prefs.setBool('typing_practice_enabled', newEnabled);
    state = state.copyWith(enabled: newEnabled);
  }

  Future<void> setEnabled(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('typing_practice_enabled', val);
    state = state.copyWith(enabled: val);
  }

  Future<void> toggleLenientPunctuation() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newLenient = !state.lenientPunctuation;
    await prefs.setBool('typing_lenient_punctuation', newLenient);
    state = state.copyWith(lenientPunctuation: newLenient);
  }
}

final typingPracticeSettingsProvider =
    NotifierProvider<TypingPracticeSettingsNotifier, TypingPracticeSettings>(
      TypingPracticeSettingsNotifier.new,
    );
