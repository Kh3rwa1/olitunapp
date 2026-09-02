import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/main/presentation/main_shell/main_shell_screen.dart';
import 'package:itun/features/main/presentation/main_shell/widgets/desktop_sidebar.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Exercises the desktop drawer layout (drawer.dart part) and the mobile
// bottom-nav layout (bottom_nav.dart part) of the main shell library.
void main() {
  GoRouter shellRouter() => GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const Center(child: Text('Home Screen Content')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bakhed',
                builder: (context, state) =>
                    const Center(child: Text('Bakhed Screen Content')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    const Center(child: Text('Profile Screen Content')),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: shellRouter(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('desktop width renders the drawer sidebar and stats panel', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1600, 1000));

    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.text('Olitun'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Bakhed'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Home Screen Content'), findsOneWidget);
  });

  testWidgets('sidebar taps switch shell branches on desktop', (tester) async {
    await pumpShell(tester, const Size(1600, 1000));

    await tester.tap(find.text('Bakhed'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bakhed Screen Content'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Profile Screen Content'), findsOneWidget);
    expect(containerOf(tester).read(shellTabIndexProvider), 2);
  });

  testWidgets('mobile width renders the glass bottom navigation instead', (
    tester,
  ) async {
    await pumpShell(tester, const Size(450, 900));

    expect(find.byType(DesktopSidebar), findsNothing);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Bakhed'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Home Screen Content'), findsOneWidget);
  });
}

ProviderContainer containerOf(WidgetTester tester) {
  final element = tester.element(find.byType(DesktopSidebar));
  return ProviderScope.containerOf(element);
}
