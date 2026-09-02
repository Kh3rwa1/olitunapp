import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/hive_service.dart';
import 'language_settings_providers.dart';

// ============== APP SETTINGS ==============
// These are global app settings, not specific to the user profile stats.

enum LearnerLevel { beginner, familiar, basicReader, advanced }

final learnerLevelProvider = StateProvider<LearnerLevel>((ref) {
  final val = ref.read(sharedPreferencesProvider).getString('learner_level');
  return LearnerLevel.values.firstWhere(
    (e) => e.name == val,
    orElse: () => LearnerLevel.beginner,
  );
});

final dailyGoalMinutesProvider = StateProvider<int>((ref) {
  return ref.read(sharedPreferencesProvider).getInt('daily_goal_minutes') ?? 5;
});

final userReduceVisualEffectsProvider = StateProvider<bool>((ref) {
  return ref.read(sharedPreferencesProvider).getBool('reduce_visual_effects') ??
      false;
});

class SystemReduceMotionNotifier extends Notifier<bool>
    with WidgetsBindingObserver {
  bool _observing = false;

  void _updateState() {
    try {
      state =
          PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    } catch (_) {
      // Accessibility features may be unreadable before binding init or in
      // tests; treating it as "no reduce-motion" is the safe default.
      state = false;
    }
  }

  @override
  bool build() {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    });
    _updateState();
    return state;
  }

  @override
  void didChangeAccessibilityFeatures() {
    _updateState();
  }
}

final systemReduceMotionProvider =
    NotifierProvider<SystemReduceMotionNotifier, bool>(
      SystemReduceMotionNotifier.new,
    );

final reduceVisualEffectsProvider = Provider<bool>((ref) {
  final userPref = ref.watch(userReduceVisualEffectsProvider);
  final systemPref = ref.watch(systemReduceMotionProvider);
  return userPref || systemPref;
});

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
  final normalized = kInterfaceLanguages.contains(languageCode)
      ? languageCode
      : 'en';
  final prefs = ref.read(sharedPreferencesProvider);
  final previousLanguage = ref.read(appLanguageProvider);

  prefs.setString('app_language', normalized);
  ref.read(appLanguageProvider.notifier).state = normalized;

  // Santali UI implies Ol Chiki script; restore 'both' when leaving Santali.
  if (normalized == 'sat') {
    prefs.setString('script_mode', 'olchiki');
    ref.read(scriptModeProvider.notifier).state = 'olchiki';
  } else if (previousLanguage == 'sat' &&
      ref.read(scriptModeProvider) == 'olchiki') {
    prefs.setString('script_mode', 'both');
    ref.read(scriptModeProvider.notifier).state = 'both';
  }

  // The teaching language follows the interface language until the learner
  // customizes it explicitly (see language_settings_providers.dart).
  cascadeTeachingLanguageForInterface(ref, normalized);
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

void updateLearnerLevel(WidgetRef ref, LearnerLevel level) {
  ref.read(sharedPreferencesProvider).setString('learner_level', level.name);
  ref.read(learnerLevelProvider.notifier).state = level;
}

void updateDailyGoalMinutes(WidgetRef ref, int minutes) {
  ref.read(sharedPreferencesProvider).setInt('daily_goal_minutes', minutes);
  ref.read(dailyGoalMinutesProvider.notifier).state = minutes;
}

void toggleReduceVisualEffects(WidgetRef ref) {
  final current = ref.read(userReduceVisualEffectsProvider);
  ref
      .read(sharedPreferencesProvider)
      .setBool('reduce_visual_effects', !current);
  ref.read(userReduceVisualEffectsProvider.notifier).state = !current;
}

// ============== LESSON LAYOUT MODE SETTINGS ==============

enum LessonLayoutMode { grid, list }

final lessonLayoutModeProvider = StateProvider<LessonLayoutMode>((ref) {
  final val = ref
      .read(sharedPreferencesProvider)
      .getString('lesson_layout_mode');
  return LessonLayoutMode.values.firstWhere(
    (e) => e.name == val,
    orElse: () => LessonLayoutMode.grid,
  );
});

void updateLessonLayoutMode(WidgetRef ref, LessonLayoutMode mode) {
  ref
      .read(sharedPreferencesProvider)
      .setString('lesson_layout_mode', mode.name);
  ref.read(lessonLayoutModeProvider.notifier).state = mode;
}
