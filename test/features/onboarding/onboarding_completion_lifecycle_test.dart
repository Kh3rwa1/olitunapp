import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/languages/providers/target_language_provider.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/presentation/controllers/auth_controller.dart';
import 'package:itun/features/onboarding/presentation/onboarding_screen.dart';
import 'package:itun/features/onboarding/providers/onboarding_draft.dart';
import 'package:itun/shared/providers/providers.dart';

class _DelayedAuthController extends Fake implements AuthController {
  final completion = Completer<void>();
  int calls = 0;

  @override
  Future<void> syncOnboardingPreferences({
    required String targetLanguage,
    required String teachingLanguage,
    required List<String> goals,
  }) {
    calls++;
    return completion.future;
  }
}

class _DelayedTargetLanguage extends TargetLanguageNotifier {
  final completion = Completer<void>();

  @override
  Future<void> selectLanguage(String code) => completion.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> flush(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<SharedPreferences> pumpFlow(
    WidgetTester tester,
    _DelayedAuthController auth,
    ValueNotifier<bool> showOnboarding, {
    _DelayedTargetLanguage? targetLanguage,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await const OnboardingDraft(teachingLanguage: 'en').save(prefs);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => ValueListenableBuilder<bool>(
            valueListenable: showOnboarding,
            builder: (context, visible, child) => visible
                ? const OnboardingScreen()
                : const Scaffold(body: Text('Left onboarding')),
          ),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reduceVisualEffectsProvider.overrideWithValue(true),
          authControllerProvider.overrideWithValue(auth),
          if (targetLanguage != null)
            targetLanguageCodeProvider.overrideWith((ref) => targetLanguage),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await flush(tester);
    return prefs;
  }

  testWidgets('leaving during remote sync never reads a disposed WidgetRef', (
    tester,
  ) async {
    final auth = _DelayedAuthController();
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final prefs = await pumpFlow(tester, auth, visible);

    await tester.tap(find.text('Skip'));
    await flush(tester);
    expect(auth.calls, 1);
    visible.value = false;
    await tester.pump();
    auth.completion.complete();
    await flush(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Left onboarding'), findsOneWidget);
    expect(prefs.getBool('show_onboarding'), isNull);
    expect(OnboardingDraft.load(prefs), isNotNull);
  });

  testWidgets('leaving during language persistence stops later widget work', (
    tester,
  ) async {
    final auth = _DelayedAuthController();
    final targetLanguage = _DelayedTargetLanguage();
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final prefs = await pumpFlow(
      tester,
      auth,
      visible,
      targetLanguage: targetLanguage,
    );

    await tester.tap(find.text('Skip'));
    await tester.pump();
    visible.value = false;
    await tester.pump();
    targetLanguage.completion.complete();
    await flush(tester);

    expect(tester.takeException(), isNull);
    expect(auth.calls, 0);
    expect(prefs.getBool('show_onboarding'), isNull);
  });

  testWidgets('repeated completion taps perform one sync and clear the draft', (
    tester,
  ) async {
    final auth = _DelayedAuthController();
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final prefs = await pumpFlow(tester, auth, visible);

    await tester.tap(find.text('Skip'));
    await tester.tap(find.text('Skip'));
    await flush(tester);
    expect(auth.calls, 1);
    expect(find.text('Saving…'), findsOneWidget);
    auth.completion.complete();
    await flush(tester);

    expect(tester.takeException(), isNull);
    expect(auth.calls, 1);
    expect(prefs.getBool('show_onboarding'), isFalse);
    expect(OnboardingDraft.load(prefs), isNull);
    expect(find.text('Home'), findsOneWidget);
  });
}
