import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:itun/shared/widgets/cover_thumbnail.dart';
import 'package:itun/shared/models/content_item.dart';

import '../../../helpers/fake_video_player_platform.dart';

void main() {
  late FakeVideoPlayerPlatform fakeVideoPlayerPlatform;

  setUpAll(() {
    fakeVideoPlayerPlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlayerPlatform;
  });

  setUp(() {
    fakeVideoPlayerPlatform.reset();
  });

  Widget createTestWidget({
    required ContentMedia? media,
    required String? coverMediaType,
    bool showVideoBadge = true,
    Widget? fallback,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: CoverThumbnail(
            media: media,
            coverMediaType: coverMediaType,
            showVideoBadge: showVideoBadge,
            fallback: fallback,
            initTimeout: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }

  group('CoverThumbnail Widget Tests', () {
    testWidgets('1. Renders image when coverMediaType is image', (
      tester,
    ) async {
      const media = ContentMedia(
        url: 'https://example.com/cover.png',
        fileId: 'img123',
        kind: ContentMediaKind.image,
      );

      await tester.pumpWidget(
        createTestWidget(media: media, coverMediaType: 'image'),
      );

      // Verify that Image.network is rendered
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image image = tester.widget(imageFinder);
      expect(image.image, isA<NetworkImage>());
      expect(
        (image.image as NetworkImage).url,
        'https://example.com/cover.png',
      );
    });

    testWidgets(
      '2. Renders VideoPlayer when coverMediaType is video and badge overlay is present',
      (tester) async {
        const media = ContentMedia(
          url: 'https://example.com/video.mp4',
          fileId: 'vid123',
          kind: ContentMediaKind.video,
        );

        await tester.pumpWidget(
          createTestWidget(media: media, coverMediaType: 'video'),
        );

        // Let controller initialization finish
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Verify that VideoPlayer is rendered
        expect(find.byType(VideoPlayer), findsOneWidget);

        // Verify video badge overlay (Icons.play_circle_fill) is present
        expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      },
    );

    testWidgets('3. Renders fallback when media is null', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          media: null,
          coverMediaType: 'image',
          fallback: const Icon(
            Icons.music_note_rounded,
            key: ValueKey('custom_fallback'),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('custom_fallback')), findsOneWidget);
    });

    testWidgets(
      '4. Renders fallback when coverMediaType is video and controller init fails',
      (tester) async {
        fakeVideoPlayerPlatform.shouldFail = true;

        const media = ContentMedia(
          url: 'https://example.com/video.mp4',
          fileId: 'vid123',
          kind: ContentMediaKind.video,
        );

        await tester.pumpWidget(
          createTestWidget(
            media: media,
            coverMediaType: 'video',
            fallback: const Icon(
              Icons.error_outline,
              key: ValueKey('error_fallback'),
            ),
          ),
        );

        // Let controller initialization try and fail
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Verify fallback rendered instead of VideoPlayer
        expect(find.byKey(const ValueKey('error_fallback')), findsOneWidget);
        expect(find.byType(VideoPlayer), findsNothing);
      },
    );

    testWidgets('5. Disposes controller on widget removal', (tester) async {
      const media = ContentMedia(
        url: 'https://example.com/video.mp4',
        fileId: 'vid123',
        kind: ContentMediaKind.video,
      );

      final initialDisposes = fakeVideoPlayerPlatform.disposeCount;

      await tester.pumpWidget(
        createTestWidget(media: media, coverMediaType: 'video'),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Replace widget tree to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      expect(fakeVideoPlayerPlatform.disposeCount, initialDisposes + 1);
    });

    testWidgets(
      '6. Disposes old and creates new controller when media.fileId changes',
      (tester) async {
        const media1 = ContentMedia(
          url: 'https://example.com/video1.mp4',
          fileId: 'vid1',
          kind: ContentMediaKind.video,
        );

        const media2 = ContentMedia(
          url: 'https://example.com/video2.mp4',
          fileId: 'vid2',
          kind: ContentMediaKind.video,
        );

        await tester.pumpWidget(
          createTestWidget(media: media1, coverMediaType: 'video'),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final prevCreates = fakeVideoPlayerPlatform.createCount;
        final prevDisposes = fakeVideoPlayerPlatform.disposeCount;

        // Update with new media fileId
        await tester.pumpWidget(
          createTestWidget(media: media2, coverMediaType: 'video'),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        // Verify that old controller was disposed and new one was created
        expect(fakeVideoPlayerPlatform.disposeCount, prevDisposes + 1);
        expect(fakeVideoPlayerPlatform.createCount, prevCreates + 1);
      },
    );

    testWidgets('7. Video badge hidden when showVideoBadge is false', (
      tester,
    ) async {
      const media = ContentMedia(
        url: 'https://example.com/video.mp4',
        fileId: 'vid123',
        kind: ContentMediaKind.video,
      );

      await tester.pumpWidget(
        createTestWidget(
          media: media,
          coverMediaType: 'video',
          showVideoBadge: false,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify badge is not visible
      expect(find.byIcon(Icons.play_circle_fill), findsNothing);
    });
  });
}
