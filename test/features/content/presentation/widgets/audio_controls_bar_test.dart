import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/audio/playback_controller.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/features/content/presentation/widgets/audio_controls_bar.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:shared_preferences/shared_preferences.dart';

/// Test double for [AudioService]. The central PlaybackController
/// subscribes to the position/duration/processing-state streams in its
/// constructor — empty stream overrides keep it idle without leaking
/// just_audio's periodic position timer into the test binding.
/// [tryPlayUrl] records the URL because the controller uses it (not
/// [playUrl]) and reports success/failure.
class MockAudioService extends AudioService {
  final List<String> playedUrls = [];
  final List<double> speeds = [];
  bool failNextPlay = false;

  @override
  Future<bool> tryPlayUrl(String url) async {
    if (failNextPlay) {
      failNextPlay = false;
      return false;
    }
    playedUrls.add(url);
    return true;
  }

  @override
  Future<void> playUrl(String url) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> setSpeed(double speed) async {
    speeds.add(speed);
  }

  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<bool> get isPlayingStream => const Stream.empty();
}

AudioTrack track(
  String id,
  TrackType type, {
  String url = 'https://cdn.example.com/a.mp3',
  String languageCode = 'sat',
  bool isHumanRecorded = true,
  String reviewStatus = 'approved',
}) {
  return AudioTrack(
    id: id,
    contentKind: 'word',
    contentId: 'w1',
    languageCode: languageCode,
    trackType: type,
    audioUrl: url,
    isHumanRecorded: isHumanRecorded,
    reviewStatus: ReviewStatus.fromName(reviewStatus),
  );
}

AudioBundle bundleWith({
  List<AudioTrack> tracks = const [],
  String? legacyAudioUrl,
  String legacyMeaning = '',
  String teachingLanguage = 'en',
  LocalizedContent? localization,
}) {
  return AudioBundle(
    contentKind: 'word',
    contentId: 'w1',
    legacyAudioUrl: legacyAudioUrl,
    legacyMeaning: legacyMeaning,
    teachingLanguage: teachingLanguage,
    localization: localization,
    tracks: tracks,
  );
}

Future<ProviderContainer> _pumpBar(
  WidgetTester tester, {
  required MockAudioService audio,
  required AudioBundle bundle,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final playback = PlaybackController(audioService: audio);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      playbackControllerProvider.overrideWithValue(playback),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(playback.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: AudioControlsBar(bundle: bundle)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapMainButton(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.volume_up_rounded));
  await tester.pump();
}

void main() {
  testWidgets('main button plays the Santali clip through the controller', (
    tester,
  ) async {
    final audio = MockAudioService();
    final bundle = bundleWith(tracks: [track('t1', TrackType.targetNormal)]);

    await _pumpBar(tester, audio: audio, bundle: bundle);

    expect(find.byTooltip('Play Santali audio'), findsOneWidget);
    await _tapMainButton(tester);
    await tester.pump();

    expect(audio.playedUrls, equals(['https://cdn.example.com/a.mp3']));
    // Progress row appears once this item is the active playback target.
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets(
    'main button is disabled with "Audio unavailable" when nothing is playable',
    (tester) async {
      final audio = MockAudioService();
      // A synthetic, unreviewed Santali track exists but is not playable,
      // and there is no legacy URL to fall back to.
      final bundle = bundleWith(
        tracks: [
          track(
            't1',
            TrackType.targetNormal,
            isHumanRecorded: false,
            reviewStatus: 'needsReview',
          ),
        ],
      );

      await _pumpBar(tester, audio: audio, bundle: bundle);

      expect(find.byTooltip('Audio unavailable'), findsOneWidget);
      expect(find.byTooltip('Slow audio unavailable'), findsOneWidget);
      expect(find.byTooltip('Meaning audio unavailable'), findsOneWidget);

      // No play button to tap (only the disabled control) — verify the
      // controller was never asked to play anything.
      expect(audio.playedUrls, isEmpty);
    },
  );

  testWidgets('legacy inline audio URL is used as the Santali fallback', (
    tester,
  ) async {
    final audio = MockAudioService();
    final bundle = bundleWith(
      legacyAudioUrl: 'https://cdn.example.com/legacy.mp3',
    );

    await _pumpBar(tester, audio: audio, bundle: bundle);

    await _tapMainButton(tester);
    await tester.pump();

    expect(audio.playedUrls, equals(['https://cdn.example.com/legacy.mp3']));
  });

  testWidgets('bilingual mode chains Santali then teaching explanation', (
    tester,
  ) async {
    final audio = MockAudioService();
    final bundle = bundleWith(
      teachingLanguage: 'hi',
      tracks: [
        track('t1', TrackType.targetNormal),
        track(
          't2',
          TrackType.explanation,
          url: 'https://cdn.example.com/expl.mp3',
          languageCode: 'hi',
        ),
      ],
    );

    final container = await _pumpBar(tester, audio: audio, bundle: bundle);
    container.read(lessonAudioModeProvider.notifier).state =
        LessonAudioMode.bilingual;
    await tester.pumpAndSettle();

    await _tapMainButton(tester);
    await tester.pump();

    // The chain head is the Santali clip; the explanation clip is
    // queued after it via the request's `next` link and is played when
    // the first clip completes — so only the head URL plays now.
    expect(audio.playedUrls, equals(['https://cdn.example.com/a.mp3']));
  });

  testWidgets('slow button plays the explicit slow track only', (tester) async {
    final audio = MockAudioService();
    final bundle = bundleWith(
      tracks: [
        track('t1', TrackType.targetNormal),
        track(
          't2',
          TrackType.targetSlow,
          url: 'https://cdn.example.com/slow.mp3',
        ),
      ],
    );

    await _pumpBar(tester, audio: audio, bundle: bundle);

    expect(find.byTooltip('Play Santali slowly'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.slow_motion_video_rounded));
    await tester.pump();

    expect(audio.playedUrls, equals(['https://cdn.example.com/slow.mp3']));
  });

  testWidgets('meaning button plays teaching-language translation on demand', (
    tester,
  ) async {
    final audio = MockAudioService();
    final bundle = bundleWith(
      tracks: [
        track('t1', TrackType.targetNormal),
        track(
          't2',
          TrackType.translation,
          url: 'https://cdn.example.com/meaning.mp3',
          languageCode: 'en',
        ),
      ],
    );

    await _pumpBar(tester, audio: audio, bundle: bundle);

    expect(find.byTooltip('Play meaning in EN'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.translate_rounded));
    await tester.pump();

    expect(audio.playedUrls, equals(['https://cdn.example.com/meaning.mp3']));
  });

  testWidgets('main button toggles pause and resume while playing', (
    tester,
  ) async {
    final audio = MockAudioService();
    final bundle = bundleWith(tracks: [track('t1', TrackType.targetNormal)]);

    await _pumpBar(tester, audio: audio, bundle: bundle);

    await _tapMainButton(tester);
    await tester.pumpAndSettle();

    // Now the item is active and playing — the button shows pause.
    expect(find.byTooltip('Pause audio'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Resume audio'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pause audio'), findsOneWidget);
  });

  testWidgets('replay button is disabled until this item has played', (
    tester,
  ) async {
    final audio = MockAudioService();
    final bundle = bundleWith(tracks: [track('t1', TrackType.targetNormal)]);

    await _pumpBar(tester, audio: audio, bundle: bundle);

    // Idle: replay is disabled (the button ignores taps while enabled: false).
    final replayIdle = tester
        .widget<IconButton>(
          find
              .ancestor(
                of: find.byIcon(Icons.replay_rounded),
                matching: find.byType(IconButton),
              )
              .first,
        )
        .onPressed;
    expect(replayIdle, isNull);
  });

  testWidgets('speed button cycles 1.0x → 0.75x → 1.25x → 1.5x', (
    tester,
  ) async {
    final audio = MockAudioService();
    final bundle = bundleWith(tracks: [track('t1', TrackType.targetNormal)]);

    await _pumpBar(tester, audio: audio, bundle: bundle);

    expect(find.text('1.0×'), findsOneWidget);

    await tester.tap(find.text('1.0×'));
    await tester.pump();
    expect(find.text('0.75×'), findsOneWidget);

    await tester.tap(find.text('0.75×'));
    await tester.pump();
    expect(find.text('1.25×'), findsOneWidget);

    await tester.tap(find.text('1.25×'));
    await tester.pump();
    expect(find.text('1.5×'), findsOneWidget);

    await tester.tap(find.text('1.5×'));
    await tester.pump();
    expect(find.text('1.0×'), findsOneWidget);
  });

  testWidgets('playback error is surfaced in the controls bar', (tester) async {
    final audio = MockAudioService();
    final bundle = bundleWith(tracks: [track('t1', TrackType.targetNormal)]);

    await _pumpBar(tester, audio: audio, bundle: bundle);

    audio.failNextPlay = true;
    await _tapMainButton(tester);
    await tester.pumpAndSettle();

    expect(find.text('Could not play audio'), findsOneWidget);
  });

  testWidgets('bar renders with no tracks at all and stays inert', (
    tester,
  ) async {
    final audio = MockAudioService();
    final bundle = bundleWith();

    await _pumpBar(tester, audio: audio, bundle: bundle);

    expect(find.byTooltip('Audio unavailable'), findsOneWidget);
    expect(audio.playedUrls, isEmpty);
    expect(audio.speeds, isEmpty);
  });
}
