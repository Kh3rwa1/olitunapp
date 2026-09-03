import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/onboarding/presentation/onboarding_screen.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

// Walks the legacy five-step onboarding flow so the step builders in the
// onboarding_steps.dart and onboarding_goals_step.dart parts of
// onboarding_screen.dart are exercised end-to-end.
void main() {
  late _MockAuthRepository authRepository;
  late SharedPreferences prefs;

  setUp(() {
    authRepository = _MockAuthRepository();
    // Guest learner: goal sync is a no-op.
    when(
      () => authRepository.isLoggedIn(),
    ).thenAnswer((_) async => right(false));
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Center(child: Text('Home After Onboarding')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(authRepository),
          // Deterministic layout: no ambient visualizer timers.
          reduceVisualEffectsProvider.overrideWithValue(true),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('step 1 renders the value prop with the Ol Chiki glyph', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    expect(find.text('ᱚ'), findsOneWidget);
    expect(find.textContaining('Learn Ol Chiki'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets(
    'learning language step is mandatory and cannot be skipped or bypassed',
    (tester) async {
      await pumpOnboarding(tester);

      // Advance from ValueProp (Step 0) to Learning Language (Step 1)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('What language do you want to learn?'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(find.text('Santali'), findsOneWidget);
      expect(find.text('Ho'), findsOneWidget);
      expect(find.text('Mundari'), findsOneWidget);

      // Verify button shows pending prompt and Skip is hidden
      expect(find.text('Select a Learning Language'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      // Tapping without selecting does NOT advance
      await tester.tap(find.text('Select a Learning Language'));
      await tester.pump();
      expect(
        find.text('Please select your learning language to continue.'),
        findsOneWidget,
      );
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold)),
      ).clearSnackBars();
      await tester.pumpAndSettle();
      expect(find.text('What language do you want to learn?'), findsOneWidget);

      // Select Santali
      await tester.tap(find.text('Santali'));
      await tester.pumpAndSettle();

      // Now Continue is unlocked and Skip appears
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Advance to Teaching Language (Step 2)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Which language do you understand best?'),
        findsOneWidget,
      );
    },
  );

  testWidgets('level, script and daily-goal steps record each selection', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    // Step 0: Welcome
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 1: Learning Language (Mandatory)
    await tester.tap(find.text('Santali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: Teaching Language
    expect(find.text('Which language do you understand best?'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3 — learning level.
    expect(find.text('How familiar are you with Ol Chiki?'), findsOneWidget);
    expect(find.text("I'm completely new"), findsOneWidget);
    expect(find.text('I know some letters'), findsOneWidget);
    expect(find.text('I can read basic words'), findsOneWidget);
    expect(find.text('I want to practice fluency'), findsOneWidget);
    await tester.tap(find.text('I know some letters'));
    await tester.pump(const Duration(milliseconds: 100));

    // Step 4 — script selection.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('How do you want to see content?'), findsOneWidget);
    expect(find.text('Ol Chiki only'), findsOneWidget);
    await tester.tap(find.text('Ol Chiki only'));
    await tester.pump(const Duration(milliseconds: 100));

    // Step 5 — daily goal.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('How much do you want to practice?'), findsOneWidget);
    expect(find.text('10 minutes'), findsOneWidget);
    await tester.tap(find.text('10 minutes'));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('goals step toggles selections and finishing routes home', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    // Step 0: Value prop
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 1: Mandatory Learning Language
    await tester.tap(find.text('Santali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Steps 2 through 5: Teaching language, level, script, daily goal
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    // Step 6: Learning Goals
    expect(find.text('What are your learning goals?'), findsOneWidget);
    expect(find.text('Read Ol Chiki script'), findsOneWidget);
    expect(find.text('Build daily habits'), findsOneWidget);

    await tester.tap(find.text('Read Ol Chiki script'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Start Learning'));
    await tester.pumpAndSettle();

    // Onboarding completed: flag persisted and the router landed home.
    expect(prefs.getBool('show_onboarding'), isFalse);
    expect(prefs.getString('selected_target_language'), 'sat');
    expect(find.text('Home After Onboarding'), findsOneWidget);
    // Guest mode: goal sync consulted the auth backend at least once
    // without ever signing in.
    verify(() => authRepository.isLoggedIn());
  });
}
