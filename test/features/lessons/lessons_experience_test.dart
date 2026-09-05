import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/core/theme/app_theme.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/presentation/lessons_screen.dart';
import 'package:itun/features/lessons/presentation/widgets/bento_category_card.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

List<CategoryEntity> _categories(int count) => List.generate(
  count,
  (index) => CategoryEntity(
    id: 'path_$index',
    titleLatin: 'Path $index',
    titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
    iconName: 'words',
  ),
);

class _Categories extends CategoryNotifier {
  _Categories(this.initial, this.recovered);

  final AsyncValue<List<CategoryEntity>> initial;
  final List<CategoryEntity> recovered;
  int refreshes = 0;

  @override
  AsyncValue<List<CategoryEntity>> build() => initial;

  @override
  Future<void> refresh() async {
    refreshes++;
    state = AsyncValue.data(recovered);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Categories notifier, {
  double width = 390,
  double scale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/lessons',
    routes: [
      GoRoute(
        path: '/lessons',
        builder: (_, state) => const LessonsScreen(),
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (_, state) => Text('opened:${state.pathParameters['id']}'),
      ),
      GoRoute(path: '/', builder: (_, state) => const Text('Home')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reduceVisualEffectsProvider.overrideWithValue(true),
        categoryNotifierProvider.overrideWith(() => notifier),
        adStateProvider.overrideWith(
          () => AdStateNotifier(const AdState(isAdsEnabledGlobally: false)),
        ),
      ],
      child: MaterialApp.router(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('large catalogs build only visible and cached cards', (
    tester,
  ) async {
    final data = _categories(200);
    await _pump(tester, _Categories(AsyncValue.data(data), data));
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(BentoCategoryCard).evaluate().length, lessThan(20));
    expect(find.text('Path 199'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Path 30'),
      500,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await tester.pumpAndSettle();
    expect(find.text('Path 30'), findsOneWidget);
    expect(find.byType(BentoCategoryCard).evaluate().length, lessThan(20));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    for (final dark in [false, true]) {
      testWidgets('200% text fits at width=$width dark=$dark', (
        tester,
      ) async {
        final data = _categories(8);
        await _pump(
          tester,
          _Categories(AsyncValue.data(data), data),
          width: width,
          scale: 2,
          dark: dark,
        );
        expect(find.byType(SliverGrid), findsNothing);
        expect(find.byType(SliverList), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Path 5'),
          350,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Path 5'), findsOneWidget);
      });
    }
  }

  testWidgets('error retry actually reloads and recovers the catalog', (
    tester,
  ) async {
    final notifier = _Categories(
      AsyncValue.error(StateError('offline'), StackTrace.current),
      _categories(2),
    );
    await _pump(tester, notifier);
    expect(find.text('Could not load lessons'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(notifier.refreshes, 1);
    expect(find.text('Path 0'), findsOneWidget);
    expect(find.text('Could not load lessons'), findsNothing);
  });

  testWidgets('empty catalog explains the state and offers recovery', (
    tester,
  ) async {
    final notifier = _Categories(const AsyncValue.data([]), _categories(1));
    await _pump(tester, notifier);
    expect(find.text('No learning paths yet'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(notifier.refreshes, 1);
    expect(find.text('Path 0'), findsOneWidget);
  });

  testWidgets('a lazily built category still opens the correct destination', (
    tester,
  ) async {
    final data = _categories(40);
    await _pump(tester, _Categories(AsyncValue.data(data), data));
    await tester.scrollUntilVisible(
      find.text('Path 12'),
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await tester.tap(find.text('Path 12'));
    await tester.pumpAndSettle();
    expect(find.text('opened:path_12'), findsOneWidget);
  });

  testWidgets('back is labelled and returns to home on a direct visit', (
    tester,
  ) async {
    final data = _categories(2);
    await _pump(tester, _Categories(AsyncValue.data(data), data));
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
