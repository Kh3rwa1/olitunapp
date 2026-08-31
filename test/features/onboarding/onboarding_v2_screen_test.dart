import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/onboarding/presentation/onboarding_v2_screen.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> pumpOnboarding(
    WidgetTester tester, {
    required VoidCallback onFinished,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Tall surface so every option card is laid out and hittable.
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // No-op analytics: the real provider constructs an Appwrite
          // client and would attempt network writes in tests.
          learningAnalyticsServiceProvider.overrideWithValue(
            LearningAnalyticsService(
              prefs: prefs,
              remoteWriter: (_, _) async {},
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingV2Screen(onFinished: onFinished),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  testWidgets('walks all five steps and persists every choice', (tester) async {
    var finished = false;
    final prefs = await pumpOnboarding(
      tester,
      onFinished: () => finished = true,
    );

    // Step 1 — language.
    expect(find.text('Which language do you understand best?'), findsOne);
    await tester.tap(find.text('हिंदी'));
    await tester.pumpAndSettle();
    expect(prefs.getString('app_language'), 'hi');
    expect(prefs.getString('teaching_language'), 'hi');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2 — proficiency.
    expect(find.text('How much Santali do you know?'), findsOne);
    await tester.tap(find.text('I speak Santali'));
    await tester.pumpAndSettle();
    expect(prefs.getString('santali_proficiency'), 'fluentSpeaker');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3 — goals (multi-select).
    await tester.tap(find.text('Speak Santali'));
    await tester.tap(find.text('Read Ol Chiki'));
    await tester.pumpAndSettle();
    expect(
      prefs.getStringList('learning_goals'),
      containsAll(['speakSantali', 'readOlChiki']),
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4 — audio mode.
    await tester.tap(find.text('Santali, then my language'));
    await tester.pumpAndSettle();
    expect(prefs.getString('lesson_audio_mode'), 'bilingual');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 5 — daily goal + finish.
    await tester.tap(find.text('10 min/day'));
    await tester.pumpAndSettle();
    expect(prefs.getInt('daily_goal_minutes'), 10);
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    // Onboarding completion flag is written by the shared onboarding
    // provider, same as the legacy flow.
    expect(prefs.getBool('show_onboarding'), isFalse);
  });

  testWidgets('guest finish without any selection keeps safe defaults', (
    tester,
  ) async {
    var finished = false;
    final prefs = await pumpOnboarding(
      tester,
      onFinished: () => finished = true,
    );

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    // Interface language untouched -> provider default 'en'.
    expect(prefs.getString('app_language'), isNull);
    // The finish path reads the new providers, which seeds migrated
    // defaults on first read.
    expect(prefs.getString('teaching_language'), 'en');
    expect(prefs.getString('santali_proficiency'), 'none');
    expect(prefs.getString('lesson_audio_mode'), 'translationOnDemand');
    expect(prefs.getBool('show_onboarding'), isFalse);
  });
}
