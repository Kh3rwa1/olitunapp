import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:itun/features/rhymes/presentation/widgets/bento_rhyme_card.dart';
import 'package:itun/features/rhymes/domain/rhyme_model.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/features/rhymes/presentation/providers/listened_bakhed_provider.dart';
import 'package:itun/features/rhymes/presentation/providers/rhyme_audio_provider.dart';

import '../../../helpers/fake_video_player_platform.dart';
import '../../../test_utils.dart';

class MockRhymeAudioNotifier extends RhymeAudioNotifier {
  final RhymeAudioState _initial;
  int togglePlayCalls = 0;

  MockRhymeAudioNotifier(this._initial);

  @override
  RhymeAudioState build() => _initial;

  @override
  Future<void> togglePlay(
    String rhymeId,
    String? url, {
    String? title,
    String? artworkUrl,
  }) async {
    togglePlayCalls++;
  }
}

class _ListenedFake extends ListenedBakhedNotifier {
  @override
  Set<String> build() => {'heard_1'};
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

  Widget createBentoCardWidget({
    required RhymeModel rhyme,
    required int index,
    List<Override> extraOverrides = const [],
  }) {
    return createTestableWidget(
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: BentoRhymeCard(rhyme: rhyme, index: index),
          ),
        ),
      ),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        rhymeAudioProvider.overrideWith(() => mockRhymeAudioNotifier),
        reduceVisualEffectsProvider.overrideWithValue(true),
        ...extraOverrides,
      ],
    );
  }

  group('BentoRhymeCard Widget Tests', () {
    testWidgets('0. Listened bakhed shows a heard badge on the category chip', (
      tester,
    ) async {
      final rhyme = RhymeModel(
        id: 'heard_1',
        titleOlChiki: 'ᱛᱮᱥᱴ',
        titleLatin: 'heard story',
        contentOlChiki: '',
        contentLatin: '',
        category: 'Sohrai',
      );

      await tester.pumpWidget(
        createBentoCardWidget(
          rhyme: rhyme,
          index: 0,
          extraOverrides: [
            listenedBakhedProvider.overrideWith(_ListenedFake.new),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('1. Legacy/Null cover renders category icon fallback', (
      tester,
    ) async {
      final rhyme = RhymeModel(
        id: 'r1',
        titleOlChiki: 'ᱡᱮᱞ',
        titleLatin: 'Jel',
        contentOlChiki: 'ᱡᱮᱞ ᱡᱮᱞ',
        contentLatin: 'Jel Jel',
        category: 'animals',
      );

      await tester.pumpWidget(createBentoCardWidget(rhyme: rhyme, index: 0));
      await tester.pump();

      // Should not render CachedNetworkImage or VideoPlayer
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(VideoPlayer), findsNothing);

      // Should render animal/category icon (pets in our mapping, or similar fallback)
      expect(
        find.byType(Icon),
        findsNWidgets(3),
      ); // generated-art watermark + category chip icon + play button icon

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

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

        await tester.pumpWidget(createBentoCardWidget(rhyme: rhyme, index: 0));
        await tester.pump();

        // Image is rendered via Image.network in CoverThumbnail
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

        await tester.pumpWidget(createBentoCardWidget(rhyme: rhyme, index: 0));
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

      await tester.pumpWidget(createBentoCardWidget(rhyme: rhyme, index: 0));
      await tester.pump();

      // Find and tap the play button icon (Icons.play_circle_fill_rounded)
      final playButtonFinder = find.byIcon(Icons.play_circle_fill_rounded);
      expect(playButtonFinder, findsOneWidget);
      await tester.tap(playButtonFinder);
      await tester.pump();

      expect(mockRhymeAudioNotifier.togglePlayCalls, 1);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
