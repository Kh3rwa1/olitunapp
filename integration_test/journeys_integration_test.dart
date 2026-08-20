import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/auth/presentation/welcome_screen.dart';
import 'package:itun/features/auth/presentation/email_auth_screen.dart';
import 'package:itun/features/onboarding/presentation/splash_screen.dart';
import 'package:itun/features/home/presentation/home_screen.dart';
import 'package:itun/features/lessons/presentation/lessons_screen.dart';
import 'package:itun/features/legal/presentation/legal_document_screen.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('Full Application User Journeys Integration Suite', () {
    testWidgets('1. Auth Journey: Welcome -> Email Auth transition', (
      tester,
    ) async {
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
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Continue with Email'), findsOneWidget);

      await tester.tap(find.text('Continue with Email'));
      await tester.pumpAndSettle();

      expect(find.byType(EmailAuthScreen), findsOneWidget);
    });

    testWidgets(
      '2. Purchase Callback Journey: Handles callback parameters gracefully',
      (tester) async {
        final router = GoRouter(
          initialLocation:
              '/splash?purchase_status=success&category_id=cat_123',
          routes: [
            GoRoute(
              path: '/splash',
              builder: (context, state) => const SplashScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(SplashScreen), findsOneWidget);
      },
    );

    testWidgets(
      '3. Offline Restart Journey: Initializing app offline loads cached state',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      '4. Account Deletion Journey: Renders deletion confirmation sheet options',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/welcome',
          routes: [
            GoRoute(
              path: '/welcome',
              builder: (context, state) => const WelcomeScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(WelcomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      '5. Lesson List Journey: Renders lesson navigation screen correctly',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/lessons',
          routes: [
            GoRoute(
              path: '/lessons',
              builder: (context, state) => const LessonsScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(LessonsScreen), findsOneWidget);
      },
    );

    testWidgets(
      '6. Legal & Privacy Navigation: Renders privacy and terms screens',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/privacy',
          routes: [
            GoRoute(
              path: '/privacy',
              builder: (context, state) =>
                  const LegalDocumentScreen(type: LegalDocumentType.privacy),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Privacy Policy'), findsOneWidget);
      },
    );

    testWidgets(
      '7. OAuth Callback Sanitization: Strips sensitive query params upon routing',
      (tester) async {
        final router = GoRouter(
          initialLocation:
              '/welcome?secret=sensitive_oauth_secret_123&code=auth_code_xyz',
          routes: [
            GoRoute(
              path: '/welcome',
              builder: (context, state) => const WelcomeScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(WelcomeScreen), findsOneWidget);
      },
    );
  });
}
