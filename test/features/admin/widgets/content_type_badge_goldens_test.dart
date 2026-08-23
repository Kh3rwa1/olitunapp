import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/content_badge_resolver.dart';
import 'package:itun/features/admin/presentation/widgets/content_type_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContentTypeBadge Golden Tests (Grouped Grids)', () {
    testWidgets('renders all 10 badge types in light theme grid', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: ContentBadgeType.values.map((type) {
                    return ContentTypeBadge(type: type);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Wrap),
        matchesGoldenFile('../../../goldens/content_badges_light_grid.png'),
      );
    });

    testWidgets('renders all 10 badge types in dark theme grid', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            backgroundColor: const Color(0xFF1E1E2E),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: ContentBadgeType.values.map((type) {
                    return ContentTypeBadge(type: type);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Wrap),
        matchesGoldenFile('../../../goldens/content_badges_dark_grid.png'),
      );
    });

    testWidgets('renders overlaid badges with shadow ring on card thumbnail', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                key: const Key('overlay_test_grid'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Light background card thumbnail overlay
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      const Positioned(
                        bottom: -4,
                        right: -4,
                        child: ContentTypeBadge(
                          type: ContentBadgeType.audio,
                          size: 24,
                          hasShadowRing: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                  // Dark background card thumbnail overlay
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFF152232),
                        child: const Icon(
                          Icons.video_library,
                          color: Colors.white24,
                        ),
                      ),
                      const Positioned(
                        bottom: -4,
                        right: -4,
                        child: ContentTypeBadge(
                          type: ContentBadgeType.video,
                          size: 24,
                          hasShadowRing: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('overlay_test_grid')),
        matchesGoldenFile('../../../goldens/content_badges_overlays.png'),
      );
    });
  });
}
