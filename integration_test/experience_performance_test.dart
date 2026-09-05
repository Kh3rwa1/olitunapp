import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/core/theme/app_theme.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/presentation/lessons_screen.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

class _ProfileCategories extends CategoryNotifier {
  @override
  AsyncValue<List<CategoryEntity>> build() => AsyncValue.data(
    List.generate(
      200,
      (index) => CategoryEntity(
        id: 'profile_$index',
        titleLatin: 'Learning path $index',
        titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
        iconName: 'words',
      ),
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('record real learning catalog frame timings in profile mode', (
    tester,
  ) async {
    if (!kProfileMode || kIsWeb) {
      markTestSkipped('Run this target in profile mode on a physical device.');
      return;
    }
    const commit = String.fromEnvironment('BUILD_SHA');
    const device = String.fromEnvironment('PROFILE_DEVICE');
    expect(commit, isNotEmpty, reason: 'Pass --dart-define=BUILD_SHA=...');
    expect(device, isNotEmpty, reason: 'Pass --dart-define=PROFILE_DEVICE=...');

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/lessons',
      routes: [
        GoRoute(
          path: '/lessons',
          builder: (_, state) => const LessonsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          categoryNotifierProvider.overrideWith(_ProfileCategories.new),
          reduceVisualEffectsProvider.overrideWithValue(false),
          // No real purchases, analytics, ad requests, or backend content.
          adStateProvider.overrideWith(
            () => AdStateNotifier(const AdState(isAdsEnabledGlobally: false)),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = find.byType(CustomScrollView);
    // Warm up the renderer separately from steady-state scrolling.
    await tester.fling(scroll, const Offset(0, -600), 1500);
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 1));

    final frames = <ui.FrameTiming>[];
    void record(List<ui.FrameTiming> values) => frames.addAll(values);
    binding.addTimingsCallback(record);
    try {
      for (var pass = 0; pass < 8; pass++) {
        await tester.fling(
          scroll,
          Offset(0, pass.isEven ? -600 : 600),
          1500,
        );
        await tester.pumpAndSettle();
      }
      // Engine timing batches arrive after the rendered frames.
      await Future<void>.delayed(const Duration(seconds: 1));
    } finally {
      binding.removeTimingsCallback(record);
    }
    expect(frames.length, greaterThanOrEqualTo(120));
    final display = binding.platformDispatcher.views.first.display;
    binding.reportData = {
      'experience': {
        'mode': 'profile',
        'commit': commit,
        'device': device,
        'refreshHz': display.refreshRate,
        'fixture': 'learning-paths-200; ads/backend disabled; warm scroll',
        'frames': frames
            .map(
              (frame) => {
                'buildMicros': frame.buildDuration.inMicroseconds,
                'rasterMicros': frame.rasterDuration.inMicroseconds,
              },
            )
            .toList(),
      },
    };
    await tester.pumpWidget(const SizedBox());
  });
}
