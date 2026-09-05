import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/onboarding/presentation/onboarding_screen.dart';
import 'package:itun/features/onboarding/providers/onboarding_draft.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingDraft storage', () {
    test('load returns null when no draft was saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(OnboardingDraft.load(prefs), isNull);
    });

    test('save/load round-trips every field', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const draft = OnboardingDraft(
        step: 3,
        teachingLanguage: 'hi',
        level: LearnerLevel.basicReader,
        scriptMode: 'olchiki',
        dailyGoal: 10,
        goals: ['readOlChiki'],
      );
      await draft.save(prefs);

      final loaded = OnboardingDraft.load(prefs)!;
      expect(loaded.step, 3);
      expect(loaded.teachingLanguage, 'hi');
      expect(loaded.level, LearnerLevel.basicReader);
      expect(loaded.scriptMode, 'olchiki');
      expect(loaded.dailyGoal, 10);
      expect(loaded.goals, ['readOlChiki']);
    });

    test('load sanitizes out-of-range step and unknown values', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_v1_draft_step': 99,
        'onboarding_v1_draft_level': 'not_a_level',
        'onboarding_v1_draft_script_mode': 'klingon',
      });
      final prefs = await SharedPreferences.getInstance();

      final loaded = OnboardingDraft.load(prefs)!;
      expect(loaded.step, OnboardingDraft.totalSteps - 1);
      expect(loaded.level, LearnerLevel.beginner);
      expect(loaded.scriptMode, 'both');
    });

    test('clear removes every draft key', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await const OnboardingDraft(step: 2, teachingLanguage: 'bn').save(prefs);
      expect(OnboardingDraft.load(prefs), isNotNull);

      await OnboardingDraft.clear(prefs);
      expect(OnboardingDraft.load(prefs), isNull);
    });
  });

  group('OnboardingScreen restart recovery', () {
    Future<SharedPreferences> pumpScreen(WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // Static screen: no ambient glyph animation in tests.
            reduceVisualEffectsProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return prefs;
    }

    testWidgets('restart mid-flow restores step and language choice', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await pumpScreen(tester);

      // Step 0 -> step 1 (mandatory language), pick Hindi, advance to step 2.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Which language do you understand best?'),
        findsOneWidget,
      );
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('How familiar are you with Ol Chiki?'), findsOneWidget);
      expect(prefs.getInt('onboarding_v1_draft_step'), 2);
      expect(prefs.getString('onboarding_v1_draft_teaching_lang'), 'hi');

      // Simulate an app restart with the same prefs store.
      await pumpScreen(tester);

      // Still on the level step, not restarted at step 0...
      expect(find.text('How familiar are you with Ol Chiki?'), findsOneWidget);
      // ...and going back shows the preserved Hindi selection.
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(
        find.text('Which language do you understand best?'),
        findsOneWidget,
      );
      expect(find.text('हिंदी'), findsOneWidget);
      // Exactly one selected card (the check mark).
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
