import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/app_settings_provider.dart';

// Remote/env-driven feature flags for the multilingual audio rollout.
//
// Resolution order (highest precedence first):
// 1. `--dart-define` overrides (e.g. ONBOARDING_V2_ENABLED=true) for dev/CI.
// 2. The existing `app_settings` Appwrite collection (snake_case keys).
// 3. Safe defaults — every flag is OFF, so the app falls back to the
//    current experience when a flag is missing.
class FeatureFlags {
  final bool multilingualAudioEnabled;
  final bool onboardingV2Enabled;
  final bool bilingualPlaybackEnabled;
  final bool audioDownloadsEnabled;
  final bool audioQuizzesEnabled;
  final bool sarvamGenerationEnabled;

  const FeatureFlags({
    required this.multilingualAudioEnabled,
    required this.onboardingV2Enabled,
    required this.bilingualPlaybackEnabled,
    required this.audioDownloadsEnabled,
    required this.audioQuizzesEnabled,
    required this.sarvamGenerationEnabled,
  });

  /// Every flag disabled — the safe fallback experience.
  static const FeatureFlags off = FeatureFlags(
    multilingualAudioEnabled: false,
    onboardingV2Enabled: false,
    bilingualPlaybackEnabled: false,
    audioDownloadsEnabled: false,
    audioQuizzesEnabled: false,
    sarvamGenerationEnabled: false,
  );

  static const _envOverrides = <String, String>{
    'multilingual_audio_enabled': String.fromEnvironment(
      'MULTILINGUAL_AUDIO_ENABLED',
    ),
    'onboarding_v2_enabled': String.fromEnvironment('ONBOARDING_V2_ENABLED'),
    'bilingual_playback_enabled': String.fromEnvironment(
      'BILINGUAL_PLAYBACK_ENABLED',
    ),
    'audio_downloads_enabled': String.fromEnvironment(
      'AUDIO_DOWNLOADS_ENABLED',
    ),
    'audio_quizzes_enabled': String.fromEnvironment('AUDIO_QUIZZES_ENABLED'),
    'sarvam_generation_enabled': String.fromEnvironment(
      'SARVAM_GENERATION_ENABLED',
    ),
  };

  static bool _resolve(String key, Map<String, dynamic> settings) {
    final env = _envOverrides[key];
    if (env != null && env.isNotEmpty) return env == 'true';
    final value = settings[key];
    return value == 'true' || value == true;
  }

  factory FeatureFlags.fromSettings(Map<String, dynamic> settings) {
    return FeatureFlags(
      multilingualAudioEnabled: _resolve(
        'multilingual_audio_enabled',
        settings,
      ),
      onboardingV2Enabled: _resolve('onboarding_v2_enabled', settings),
      bilingualPlaybackEnabled: _resolve(
        'bilingual_playback_enabled',
        settings,
      ),
      audioDownloadsEnabled: _resolve('audio_downloads_enabled', settings),
      audioQuizzesEnabled: _resolve('audio_quizzes_enabled', settings),
      sarvamGenerationEnabled: _resolve('sarvam_generation_enabled', settings),
    );
  }
}

/// App-wide feature flags, backed by the existing app_settings collection.
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return FeatureFlags.fromSettings(settings ?? const {});
});
