import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/main/presentation/main_shell_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MainShellScreen & StatefulShellRoute Integration', () {
    test('shellTabIndexForPath maps paths correctly', () {
      expect(shellTabIndexForPath('/'), 0);
      expect(shellTabIndexForPath('/categories'), 0);
      expect(shellTabIndexForPath('/bakhed'), 1);
      expect(shellTabIndexForPath('/profile'), 2);
      expect(shellTabIndexForPath('/unknown'), isNull);
    });

    testWidgets('renders shell with active branch and switches on deep-link', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return MainShellScreen(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: Center(child: Text('Home Screen Content')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/bakhed',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: Center(child: Text('Bakhed Screen Content')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: Center(child: Text('Profile Screen Content')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Home branch is visible by default
      expect(find.text('Home Screen Content'), findsOneWidget);

      // Deep-link to Bakhed branch
      router.go('/bakhed');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bakhed Screen Content'), findsOneWidget);

      // Deep-link to Profile branch
      router.go('/profile');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Profile Screen Content'), findsOneWidget);

      // Deep-link back to Home branch
      router.go('/');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Home Screen Content'), findsOneWidget);
    });
  });
}
