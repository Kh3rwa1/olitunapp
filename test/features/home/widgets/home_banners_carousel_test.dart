import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itun/features/home/presentation/widgets/home_banners_carousel.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/shared/models/content_models.dart';
import '../../../test_utils.dart';

class MockBannersNotifier extends BannersNotifier {
  final AsyncValue<List<FeaturedBannerModel>> _initial;

  MockBannersNotifier(this._initial);

  @override
  AsyncValue<List<FeaturedBannerModel>> build() => _initial;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Animate.restartOnHotReload = false;
  });

  testWidgets(
    'HomeBannersCarousel renders nothing when banners list is empty',
    (tester) async {
      final notifier = MockBannersNotifier(const AsyncValue.data([]));

      await tester.pumpWidget(
        createTestableWidget(
          child: const HomeBannersCarousel(isDark: false, autoScroll: false),
          overrides: [bannersProvider.overrideWith(() => notifier)],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomeBannersCarousel), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    },
  );

  testWidgets('HomeBannersCarousel renders active banners and their titles', (
    tester,
  ) async {
    final banner1 = FeaturedBannerModel(
      id: 'b1',
      title: 'Banner 1 Title',
      subtitle: 'Banner 1 Subtitle',
      gradientPreset: 'peach',
      order: 1,
    );
    final banner2 = FeaturedBannerModel(
      id: 'b2',
      title: 'Banner 2 Title',
      subtitle: 'Banner 2 Subtitle',
      gradientPreset: 'mint',
      order: 2,
    );
    final inactiveBanner = FeaturedBannerModel(
      id: 'b3',
      title: 'Inactive Banner',
      isActive: false,
      order: 3,
    );

    final notifier = MockBannersNotifier(
      AsyncValue.data([banner2, inactiveBanner, banner1]),
    );

    await tester.pumpWidget(
      createTestableWidget(
        child: const HomeBannersCarousel(isDark: false, autoScroll: false),
        overrides: [bannersProvider.overrideWith(() => notifier)],
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The PageView should be present since we have active banners
    expect(find.byType(PageView), findsOneWidget);

    // Banners are sorted by order: banner1 (order 1) then banner2 (order 2)
    // Initially showing banner 1
    expect(find.text('Banner 1 Title'), findsOneWidget);
    expect(find.text('Banner 1 Subtitle'), findsOneWidget);
    expect(find.text('Banner 2 Title'), findsNothing);
    expect(find.text('Inactive Banner'), findsNothing);

    // Clean up timer by disposing the widget
    await tester.pumpWidget(const SizedBox());
  });
}
