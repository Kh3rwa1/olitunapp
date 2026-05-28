import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:itun/features/rhymes/presentation/widgets/featured_rhyme_card.dart';
import 'package:itun/features/rhymes/domain/rhyme_model.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/features/rhymes/presentation/providers/rhyme_audio_provider.dart';

import '../../../helpers/fake_video_player_platform.dart';
import '../../../test_utils.dart';

class MockRhymeAudioNotifier extends StateNotifier<RhymeAudioState>
    with Mock
    implements RhymeAudioNotifier {
  MockRhymeAudioNotifier(super.state);
}

void main() {
  late FakeVideoPlayerPlatform fakeVideoPlayerPlatform;
  late MockRhymeAudioNotifier mockRhymeAudioNotifier;
  late SharedPreferences prefs;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    fakeVideoPlayerPlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlayerPlatform;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  setUp(() {
    fakeVideoPlayerPlatform.reset();
    mockRhymeAudioNotifier = MockRhymeAudioNotifier(const RhymeAudioState());
    registerFallbackValue(const RhymeAudioState());
  });

  Widget createFeaturedCardWidget({required RhymeModel rhyme}) {
    return createTestableWidget(
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 500,
            height: 500,
            child: FeaturedRhymeCard(rhyme: rhyme),
          ),
        ),
      ),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        rhymeAudioProvider.overrideWith((ref) => mockRhymeAudioNotifier),
        reduceVisualEffectsProvider.overrideWithValue(true),
      ],
    );
  }

  group('FeaturedRhymeCard Widget Tests', () {
    testWidgets(
      '1. Legacy/Null cover renders gradient only without image/video',
      (tester) async {
        final rhyme = RhymeModel(
          id: 'r1',
          titleOlChiki: 'ᱡᱮᱞ',
          titleLatin: 'Jel',
          contentOlChiki: 'ᱡᱮᱞ ᱡᱮᱞ',
          contentLatin: 'Jel Jel',
          category: 'animals',
        );

        await tester.pumpWidget(createFeaturedCardWidget(rhyme: rhyme));
        await tester.pump();

        // Should not render CachedNetworkImage or VideoPlayer
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(find.byType(VideoPlayer), findsNothing);

        // Renders text titles correctly
        expect(find.text('Jel'), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '2. Image cover renders CachedNetworkImage via CoverThumbnail',
      (tester) async {
        final rhyme = RhymeModel(
          id: 'r2',
          titleOlChiki: 'ᱡᱮᱞ',
          titleLatin: 'Jel',
          contentOlChiki: 'ᱡᱮᱞ ᱡᱮᱞ',
          contentLatin: 'Jel Jel',
          category: 'animals',
          coverMediaType: 'image',
          heroMedia: const ContentMedia(
            url: 'https://example.com/cover.png',
            fileId: 'img123',
            kind: ContentMediaKind.image,
          ),
        );

        await tester.pumpWidget(createFeaturedCardWidget(rhyme: rhyme));
        await tester.pump();

        // Image is rendered via CoverThumbnail
        expect(find.byType(Image), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '3. Video cover renders paused video poster via CoverThumbnail',
      (tester) async {
        final rhyme = RhymeModel(
          id: 'r3',
          titleOlChiki: 'ᱡᱮᱞ',
          titleLatin: 'Jel',
          contentOlChiki: 'ᱡᱮᱞ ᱡᱮᱞ',
          contentLatin: 'Jel Jel',
          category: 'animals',
          coverMediaType: 'video',
          heroMedia: const ContentMedia(
            url: 'https://example.com/video.mp4',
            fileId: 'vid123',
            kind: ContentMediaKind.video,
          ),
        );

        await tester.pumpWidget(createFeaturedCardWidget(rhyme: rhyme));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // VideoPlayer is rendered
        expect(find.byType(VideoPlayer), findsOneWidget);
        // Play circle badge overlay should be present
        expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('4. Tapping play toggle calls togglePlay on notifier', (
      tester,
    ) async {
      final rhyme = RhymeModel(
        id: 'r4',
        titleOlChiki: 'ᱡᱮᱞ',
        titleLatin: 'Jel',
        contentOlChiki: 'ᱡᱮᱞ ᱡᱮᱞ',
        contentLatin: 'Jel Jel',
        category: 'animals',
        audioUrl: 'https://example.com/audio.mp3',
        thumbnailUrl: 'https://example.com/art.png',
      );

      when(
        () => mockRhymeAudioNotifier.togglePlay(
          any(),
          any(),
          title: any(named: 'title'),
          artworkUrl: any(named: 'artworkUrl'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createFeaturedCardWidget(rhyme: rhyme));
      await tester.pump();

      // Find and tap the LISTEN NOW text button
      final playButtonFinder = find.text('LISTEN NOW');
      expect(playButtonFinder, findsOneWidget);
      await tester.tap(playButtonFinder);
      await tester.pump();

      verify(
        () => mockRhymeAudioNotifier.togglePlay(
          'r4',
          'https://example.com/audio.mp3',
          title: any(named: 'title'),
          artworkUrl: 'https://example.com/art.png',
        ),
      ).called(1);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
