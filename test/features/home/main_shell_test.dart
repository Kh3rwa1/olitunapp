import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/features/home/presentation/main_shell.dart';

/// MainShell bottom-nav: renders the three nav destinations, keeps the
/// selected destination highlighted (label + primary color), and routes
/// taps through GoRouter while syncing the highlighted index back from
/// the matched location on dependency changes.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget shellHost() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, _) => const NoTransitionPage(
                child: Scaffold(body: Text('HomeBody')),
              ),
            ),
            GoRoute(
              path: '/lessons',
              pageBuilder: (_, _) => const NoTransitionPage(
                child: Scaffold(body: Text('LessonsBody')),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (_, _) => const NoTransitionPage(
                child: Scaffold(body: Text('ProfileBody')),
              ),
            ),
          ],
        ),
      ],
    );
    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }

  testWidgets('renders all three destinations with Home selected by default', (
    tester,
  ) async {
    await tester.pumpWidget(shellHost());
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('LessonsBody'), findsNothing);
    // Only the selected destination shows its label.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Lessons'), findsNothing);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('tapping a destination routes through GoRouter and moves the '
      'selection highlight', (tester) async {
    await tester.pumpWidget(shellHost());
    await tester.pumpAndSettle();

    // The unselected Lessons icon has no visible label; tap by index within
    // the nav row (0=Home, 1=Lessons, 2=Profile).
    final navRowItems = find.descendant(
      of: find.byType(Row),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(navRowItems.at(1));
    await tester.pumpAndSettle();

    expect(find.text('LessonsBody'), findsOneWidget);
    expect(find.text('HomeBody'), findsNothing);
    expect(find.text('Lessons'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('selection highlight follows the matched location on back '
      'navigation', (tester) async {
    await tester.pumpWidget(shellHost());
    await tester.pumpAndSettle();

    final navRowItems = find.descendant(
      of: find.byType(Row),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(navRowItems.at(2));
    await tester.pumpAndSettle();
    expect(find.text('ProfileBody'), findsOneWidget);

    // Programmatic navigation back to Home must re-sync the highlight via
    // didChangeDependencies → _updateIndex.
    // ignore: unawaited_futures
    GoRouter.of(tester.element(find.byType(Navigator).first)).go('/home');
    await tester.pumpAndSettle();

    expect(find.text('HomeBody'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });
}
