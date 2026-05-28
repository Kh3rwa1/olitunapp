import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:itun/features/rhymes/presentation/widgets/cover_hero.dart';
import 'package:itun/shared/models/content_item.dart';

import '../../../helpers/fake_video_player_platform.dart';

void main() {
  late FakeVideoPlayerPlatform fakeVideoPlayerPlatform;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    fakeVideoPlayerPlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlayerPlatform;
  });

  setUp(() {
    fakeVideoPlayerPlatform.reset();
  });

  Widget createCoverHeroWidget({
    required ContentMedia? media,
    required String? coverMediaType,
    Widget? fallback,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: CoverHero(
              media: media,
              coverMediaType: coverMediaType,
              fallback: fallback,
              initTimeout: const Duration(milliseconds: 100),
            ),
          ),
        ),
      ),
    );
  }

  group('CoverHero Widget Tests', () {
    testWidgets('1. Image cover renders CachedNetworkImage', (tester) async {
      const media = ContentMedia(
        url: 'https://example.com/image.png',
        fileId: 'img1',
        kind: ContentMediaKind.image,
      );

      await tester.pumpWidget(
        createCoverHeroWidget(media: media, coverMediaType: 'image'),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);

      final CachedNetworkImage image = tester.widget(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://example.com/image.png');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      '2. Video cover initializes with muted, looping, auto-playing video',
      (tester) async {
        const media = ContentMedia(
          url: 'https://example.com/video.mp4',
          fileId: 'vid1',
          kind: ContentMediaKind.video,
        );

        await tester.pumpWidget(
          createCoverHeroWidget(media: media, coverMediaType: 'video'),
        );

        // Wait for initialization to complete
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(VideoPlayer), findsOneWidget);

        final textureId = fakeVideoPlayerPlatform.createCount;
        expect(fakeVideoPlayerPlatform.volumes[textureId], 0.0);
        expect(fakeVideoPlayerPlatform.looping[textureId], true);
        expect(fakeVideoPlayerPlatform.playing[textureId], true);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('3. Null media renders fallback widget', (tester) async {
      final fallbackKey = UniqueKey();

      await tester.pumpWidget(
        createCoverHeroWidget(
          media: null,
          coverMediaType: null,
          fallback: Container(key: fallbackKey, color: Colors.red),
        ),
      );

      expect(find.byKey(fallbackKey), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. App lifecycle pause and resume pauses and plays video', (
      tester,
    ) async {
      const media = ContentMedia(
        url: 'https://example.com/video2.mp4',
        fileId: 'vid2',
        kind: ContentMediaKind.video,
      );

      await tester.pumpWidget(
        createCoverHeroWidget(media: media, coverMediaType: 'video'),
      );

      // Initialize
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final textureId = fakeVideoPlayerPlatform.createCount;
      expect(fakeVideoPlayerPlatform.playing[textureId], true);

      // Simulate app backgrounding (paused state)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Should be paused
      expect(fakeVideoPlayerPlatform.playing[textureId], false);

      // Simulate app foregrounding (resumed state)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Should play again
      expect(fakeVideoPlayerPlatform.playing[textureId], true);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
