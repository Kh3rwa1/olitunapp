import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/features/home/presentation/widgets/home_banners_carousel.dart';
import 'package:itun/features/lessons/presentation/widgets/full_bleed_hero_media.dart';
import 'package:itun/features/rhymes/presentation/widgets/cover_hero.dart';
import 'package:itun/shared/models/catalog/category_entity.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/shared/widgets/content_hero.dart';
import 'package:itun/shared/widgets/cover_thumbnail.dart';
import 'package:itun/shared/widgets/paywall/paywall_header.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../test_utils.dart';

/// Appwrite Storage answers 402 while the organisation is read-only; every
/// learner-facing image/video must therefore load from the Worker's R2 route.
const _appwrite =
    'https://sgp.cloud.appwrite.io/v1/storage/buckets/images/files/cover_1/view?project=p';
const _edge = '${CloudflareConfig.baseUrl}/api/v1/assets/images/cover_1';

class _Banners extends BannersNotifier {
  _Banners(this._initial);
  final AsyncValue<List<FeaturedBannerModel>> _initial;
  @override
  FutureOr<List<FeaturedBannerModel>> build() => asyncValueBuild(_initial);
}

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, height: 320, child: child)),
  ),
);

String _onlyImageUrl(WidgetTester tester) =>
    tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).imageUrl;

void main() {
  const media = ContentMedia(
    url: _appwrite,
    fileId: 'cover_1',
    kind: ContentMediaKind.image,
  );

  testWidgets('CoverHero loads Appwrite images from the edge', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CoverHero(
          media: media,
          coverMediaType: 'image',
          initTimeout: Duration(milliseconds: 100),
        ),
      ),
    );
    expect(_onlyImageUrl(tester), _edge);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('CoverThumbnail loads Appwrite images from the edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CoverThumbnail(
          media: media,
          coverMediaType: 'image',
          initTimeout: Duration(milliseconds: 100),
        ),
      ),
    );
    expect(_onlyImageUrl(tester), _edge);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('FullBleedHeroMedia loads Appwrite images from the edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const FullBleedHeroMedia(
          animationUrl: null,
          imageUrl: _appwrite,
          fallback: SizedBox(),
        ),
      ),
    );
    await tester.pump();
    expect(_onlyImageUrl(tester), _edge);
  });

  testWidgets('ContentHero loads an Appwrite hero image from the edge', (
    tester,
  ) async {
    final item = ContentItem(
      id: 'w_1',
      kind: ContentKind.word,
      categoryId: 'cat',
      title: 'Baba',
      olChiki: 'ᱵᱟᱵᱟ',
      subtitle: 'Father',
      blocks: const [],
      heroMedia: media,
      updatedAt: DateTime(2026),
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      createTestableWidget(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: Scaffold(
          body: ContentHero(item: item, accentColor: Colors.blue),
        ),
      ),
    );
    await tester.pump();
    expect(_onlyImageUrl(tester), _edge);
  });

  testWidgets('PaywallHeader loads the Appwrite course hero from the edge', (
    tester,
  ) async {
    const category = CategoryEntity(
      id: 'cat_paid',
      titleOlChiki: 'ᱚᱞ',
      titleLatin: 'Paid',
      courseHeroImageUrl: _appwrite,
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      createTestableWidget(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const Scaffold(
          body: SingleChildScrollView(
            child: PaywallHeader(category: category, isDark: false),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_onlyImageUrl(tester), _edge);
  });

  testWidgets('HomeBannersCarousel loads Appwrite banner art from the edge', (
    tester,
  ) async {
    final banner = FeaturedBannerModel(
      id: 'b1',
      title: 'Banner',
      subtitle: 'Sub',
      gradientPreset: 'peach',
      order: 1,
      imageUrl: _appwrite,
    );
    await tester.pumpWidget(
      createTestableWidget(
        child: const HomeBannersCarousel(isDark: false, autoScroll: false),
        overrides: [
          bannersProvider.overrideWith(
            () => _Banners(AsyncValue.data([banner])),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(_onlyImageUrl(tester), _edge);
    await tester.pumpWidget(const SizedBox());
  });
}
