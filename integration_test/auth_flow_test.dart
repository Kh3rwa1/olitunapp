import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/auth/presentation/welcome_screen.dart';
import 'package:itun/features/auth/presentation/email_auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  testWidgets('Auth flow: Welcome screen to Email Auth screen', (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Explorer',
      'user_avatar_emoji': '👶',
      'user_avatar_color': 0,
      'show_onboarding': false,
    });
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const EmailAuthScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Welcome Screen
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    // Tap Email login
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    // Verify Email Auth Screen is pushed
    expect(find.byType(EmailAuthScreen), findsOneWidget);
  });
}
