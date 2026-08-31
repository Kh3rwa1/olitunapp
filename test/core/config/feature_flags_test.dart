import 'package:flutter_test/flutter_test.dart';

import 'package:itun/core/config/feature_flags.dart';

void main() {
  group('FeatureFlags.fromSettings', () {
    test('everything is off by default (safe fallback)', () {
      const flags = FeatureFlags.off;
      expect(flags.multilingualAudioEnabled, isFalse);
      expect(flags.onboardingV2Enabled, isFalse);
      expect(flags.bilingualPlaybackEnabled, isFalse);
      expect(flags.audioDownloadsEnabled, isFalse);
      expect(flags.audioQuizzesEnabled, isFalse);
      expect(flags.sarvamGenerationEnabled, isFalse);
    });

    test('empty settings map resolves to all-off', () {
      final flags = FeatureFlags.fromSettings(const {});
      expect(flags.onboardingV2Enabled, isFalse);
      expect(flags.multilingualAudioEnabled, isFalse);
    });

    test('string "true" in app_settings enables a flag', () {
      final flags = FeatureFlags.fromSettings(const {
        'onboarding_v2_enabled': 'true',
      });
      expect(flags.onboardingV2Enabled, isTrue);
      expect(flags.multilingualAudioEnabled, isFalse);
    });

    test('boolean true in app_settings enables a flag', () {
      final flags = FeatureFlags.fromSettings(const {
        'multilingual_audio_enabled': true,
      });
      expect(flags.multilingualAudioEnabled, isTrue);
    });

    test('non-true values are treated as off', () {
      final flags = FeatureFlags.fromSettings(const {
        'onboarding_v2_enabled': 'yes',
        'audio_downloads_enabled': '1',
        'sarvam_generation_enabled': 'false',
      });
      expect(flags.onboardingV2Enabled, isFalse);
      expect(flags.audioDownloadsEnabled, isFalse);
      expect(flags.sarvamGenerationEnabled, isFalse);
    });

    test('each flag resolves independently', () {
      final flags = FeatureFlags.fromSettings(const {
        'bilingual_playback_enabled': 'true',
        'audio_quizzes_enabled': 'true',
      });
      expect(flags.bilingualPlaybackEnabled, isTrue);
      expect(flags.audioQuizzesEnabled, isTrue);
      expect(flags.onboardingV2Enabled, isFalse);
      expect(flags.audioDownloadsEnabled, isFalse);
      expect(flags.multilingualAudioEnabled, isFalse);
      expect(flags.sarvamGenerationEnabled, isFalse);
    });
  });
}
