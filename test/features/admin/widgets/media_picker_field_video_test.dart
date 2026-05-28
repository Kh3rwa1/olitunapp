import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/core/version/build_version_checker.dart';
import 'package:itun/core/version/build_version_status.dart';
import 'package:itun/features/admin/presentation/widgets/media_picker_field.dart';
import 'package:itun/shared/models/content_item.dart';

class MockMediaUploader extends Mock implements MediaUploader {}

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int nextTextureId = 1;
  int createCount = 0;
  int disposeCount = 0;
  final Map<int, DataSource> dataSources = {};
  final Map<int, bool> playing = {};
  final Map<int, double> volumes = {};
  final Map<int, bool> looping = {};

  @override
  Future<void> init() async {}

  @override
  Future<int> create(DataSource dataSource) async {
    createCount++;
    final id = nextTextureId++;
    dataSources[id] = dataSource;
    playing[id] = false;
    volumes[id] = 1.0;
    looping[id] = false;
    return id;
  }

  @override
  Future<void> dispose(int textureId) async {
    disposeCount++;
    dataSources.remove(textureId);
    playing.remove(textureId);
    volumes.remove(textureId);
    looping.remove(textureId);
  }

  @override
  Future<void> play(int textureId) async {
    playing[textureId] = true;
  }

  @override
  Future<void> pause(int textureId) async {
    playing[textureId] = false;
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {
    volumes[textureId] = volume;
  }

  @override
  Future<void> setLooping(int textureId, bool value) async {
    looping[textureId] = value;
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Future<Duration> getPosition(int textureId) async {
    return Duration.zero;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return Stream.value(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 45),
        size: const Size(1920, 1080),
      ),
    );
  }

  @override
  Widget buildView(int textureId) {
    return Container(color: Colors.black, key: ValueKey<int>(textureId));
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return buildView(options.playerId);
  }
}

void main() {
  late MockMediaUploader mockMediaUploader;
  late FakeVideoPlayerPlatform fakeVideoPlayerPlatform;

  setUpAll(() {
    fakeVideoPlayerPlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlayerPlatform;
    registerFallbackValue(
      const ContentMedia(url: '', fileId: '', kind: ContentMediaKind.video),
    );
  });

  setUp(() {
    mockMediaUploader = MockMediaUploader();
  });

  Widget createTestWidget({
    required List<Override> overrides,
    required ContentMedia? value,
    required ValueChanged<ContentMedia?> onChanged,
    ValueChanged<String>? onRemove,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: MediaPickerField(
            label: 'Test Video Cover',
            kind: ContentMediaKind.video,
            value: value,
            onChanged: onChanged,
            onRemove: onRemove,
          ),
        ),
      ),
    );
  }

  group('MediaPickerField Video Integration & Disposal Tests', () {
    testWidgets('1. Render empty field and verify upload action button', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            mediaUploaderProvider.overrideWithValue(mockMediaUploader),
            buildVersionStatusProvider.overrideWith(
              (ref) => Stream.value(const BuildVersionMatch()),
            ),
          ],
          value: null,
          onChanged: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Video Cover'), findsOneWidget);
      expect(find.text('Upload VIDEO'), findsOneWidget);
      expect(find.byIcon(Icons.video_library_rounded), findsOneWidget);

      // Isolation cleanup
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.idle();
    });

    testWidgets(
      '2. Render valid video cover and verify custom VideoPlayer preview plays',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [
              mediaUploaderProvider.overrideWithValue(mockMediaUploader),
              buildVersionStatusProvider.overrideWith(
                (ref) => Stream.value(const BuildVersionMatch()),
              ),
            ],
            value: const ContentMedia(
              url: 'https://example.com/video25.mp4',
              fileId: 'vid123',
              kind: ContentMediaKind.video,
              durationMs: 25000, // 25 seconds (no warning expected)
            ),
            onChanged: (_) {},
          ),
        );

        // Wait for player to initialize
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(VideoPlayer), findsOneWidget);
        expect(
          find.byIcon(Icons.pause_rounded),
          findsOneWidget,
        ); // Plays on autoplay
        expect(
          find.textContaining('Cover loops work best'),
          findsNothing,
        ); // No warning

        // Isolation cleanup
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.idle();
      },
    );

    testWidgets(
      '3. Render long video (>30s) and verify warning banner appears & can be dismissed',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [
              mediaUploaderProvider.overrideWithValue(mockMediaUploader),
              buildVersionStatusProvider.overrideWith(
                (ref) => Stream.value(const BuildVersionMatch()),
              ),
            ],
            value: const ContentMedia(
              url: 'https://example.com/video35.mp4',
              fileId: 'vid456',
              kind: ContentMediaKind.video,
              durationMs: 35000, // 35 seconds (warning expected)
            ),
            onChanged: (_) {},
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Warning banner should be visible
        expect(
          find.textContaining('Cover loops work best under 30 seconds'),
          findsOneWidget,
        );

        // Dismiss the banner
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();

        // Banner should disappear
        expect(
          find.textContaining('Cover loops work best under 30 seconds'),
          findsNothing,
        );

        // Isolation cleanup
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.idle();
      },
    );

    testWidgets('4. Verify onRemove callback triggers on remove click', (
      tester,
    ) async {
      var removeCalledWithId = '';
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            mediaUploaderProvider.overrideWithValue(mockMediaUploader),
            buildVersionStatusProvider.overrideWith(
              (ref) => Stream.value(const BuildVersionMatch()),
            ),
          ],
          value: const ContentMedia(
            url: 'https://example.com/video789.mp4',
            fileId: 'vid789',
            kind: ContentMediaKind.video,
          ),
          onChanged: (_) {},
          onRemove: (id) {
            removeCalledWithId = id;
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Remove'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pump();

      expect(removeCalledWithId, equals('vid789'));

      // Isolation cleanup
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.idle();
    });

    testWidgets(
      '5. Regression: VideoPlayerController is fully disposed on teardown',
      (tester) async {
        final initialDisposes = fakeVideoPlayerPlatform.disposeCount;
        final initialCreates = fakeVideoPlayerPlatform.createCount;

        await tester.pumpWidget(
          createTestWidget(
            overrides: [
              mediaUploaderProvider.overrideWithValue(mockMediaUploader),
              buildVersionStatusProvider.overrideWith(
                (ref) => Stream.value(const BuildVersionMatch()),
              ),
            ],
            value: const ContentMedia(
              url: 'https://example.com/videoDisposed.mp4',
              fileId: 'vidDisposed',
              kind: ContentMediaKind.video,
            ),
            onChanged: (_) {},
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(fakeVideoPlayerPlatform.createCount, equals(initialCreates + 1));

        // Destroy the widget tree
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        // Disposal should have been called
        expect(
          fakeVideoPlayerPlatform.disposeCount,
          equals(initialDisposes + 1),
        );
      },
    );
  });
}
