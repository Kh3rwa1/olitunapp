import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the multilingual foundation: every shipped locale must contain
/// the keys the feature reads at runtime, and hi/bn/or must be complete
/// translations of the English template.
///
/// Run with `flutter test` from the package root (paths are relative).
void main() {
  const locales = ['en', 'hi', 'bn', 'or', 'sat'];

  /// Keys introduced by the multilingual foundation feature. Missing any of
  /// these would crash or blank out onboarding v2 / settings at runtime.
  const requiredKeys = <String>[
    // Language names
    'english', 'santali', 'hindi', 'bengali', 'odia',
    // Settings tiles
    'teachingLanguage', 'teachingLanguageSubtitle',
    'lessonAudioMode', 'lessonAudioModeSubtitle',
    // Onboarding v2
    'onboardingStepLanguageTitle',
    'onboardingStepProficiencyTitle',
    'onboardingStepGoalsTitle',
    'onboardingStepGoalsSubtitle',
    'onboardingStepAudioTitle',
    'onboardingStepReadyTitle',
    'proficiencyNone',
    'proficiencyUnderstandsSome',
    'proficiencyFluentSpeaker',
    'proficiencyBeginnerReader',
    'proficiencyFluentReader',
    'goalSpeakSantali',
    'goalUnderstandSantali',
    'goalReadOlChiki',
    'goalWriteOlChiki',
    'goalLearnEverything',
    'goalHelpMyChild',
    'goalPrepareExam',
    'audioModeTargetOnly',
    'audioModeBilingual',
    'audioModeTranslationOnDemand',
    'dailyGoalLabel',
    'minutesPerDay',
    'downloadStarterAudio',
    'downloadStarterAudioSubtitle',
    'backButton',
    // Existing keys the feature reuses
    'continueButton', 'guestSignInCta', 'streakStartLearning',
  ];

  Map<String, dynamic> loadArb(String locale) {
    final file = File('lib/l10n/arb/app_$locale.arb');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Missing ARB file for locale $locale',
    );
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  test('every ARB file declares the matching @@locale', () {
    for (final locale in locales) {
      expect(loadArb(locale)['@@locale'], locale);
    }
  });

  test('every ARB file contains all required feature keys', () {
    for (final locale in locales) {
      final keys = messageKeys(loadArb(locale));
      final missing = requiredKeys.where((k) => !keys.contains(k)).toList();
      expect(
        missing,
        isEmpty,
        reason: 'app_$locale.arb is missing required keys: $missing',
      );
    }
  });

  test('hi/bn/or fully cover the English template', () {
    final templateKeys = messageKeys(loadArb('en'));
    for (final locale in ['hi', 'bn', 'or']) {
      final keys = messageKeys(loadArb(locale));
      final missing = templateKeys.where((k) => !keys.contains(k)).toList();
      expect(
        missing,
        isEmpty,
        reason: 'app_$locale.arb missing template keys: $missing',
      );
    }
  });

  test('placeholder signatures match the template for shared keys', () {
    final en = loadArb('en');

    Set<String> placeholdersFor(Map<String, dynamic> arb, String key) {
      final meta = arb['@$key'];
      if (meta is! Map) return const {};
      final placeholders = meta['placeholders'];
      if (placeholders is! Map) return const {};
      return placeholders.keys.cast<String>().toSet();
    }

    for (final key in messageKeys(en)) {
      final expected = placeholdersFor(en, key);
      if (expected.isEmpty) continue;
      for (final locale in locales) {
        final arb = loadArb(locale);
        if (!messageKeys(arb).contains(key)) continue;
        expect(
          placeholdersFor(arb, key),
          expected,
          reason: 'app_$locale.arb "$key" placeholder mismatch',
        );
        // Interpolation markers must appear in the translated text too.
        final message = arb[key] as String;
        for (final placeholder in expected) {
          expect(
            message.contains('{$placeholder}'),
            isTrue,
            reason: 'app_$locale.arb "$key" must interpolate {$placeholder}',
          );
        }
      }
    }
  });

  test('no empty translation values anywhere', () {
    for (final locale in locales) {
      final arb = loadArb(locale);
      for (final key in messageKeys(arb)) {
        final value = arb[key];
        expect(
          value is String && value.trim().isNotEmpty,
          isTrue,
          reason: 'app_$locale.arb "$key" is empty',
        );
      }
    }
  });
}
