import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/audio/playback_controller.dart';
import 'package:itun/core/config/feature_flags.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/content/data/offline/audio_download_manager.dart';
import 'package:itun/features/content/data/offline/audio_download_store.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart'
    show ReviewStatus;
import 'package:itun/features/content/domain/entities/story_segment_entity.dart';
import 'package:itun/features/content/presentation/providers/audio_download_providers.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/features/content/presentation/providers/story_segment_providers.dart';
import 'package:itun/features/content/presentation/widgets/story_player_body.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:shared_preferences/shared_preferences.dart';

/// AudioService test double: records played URLs, never touches real
/// audio, and exposes empty streams so the PlaybackController stays idle
/// (audio_controls_bar_test.dart precedent).
class _MockAudioService extends AudioService {
  final List<String> playedUrls = [];

  @override
  Future<bool> tryPlayUrl(String url) async {
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
  Future<void> setSpeed(double speed) async {}

  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<bool> get isPlayingStream => const Stream.empty();
}

/// In-memory store double so the download affordance is deterministic
/// and no test ever performs real network/file IO.
class _FakeStore implements AudioDownloadStore {
  final Map<String, List<int>> files = {};
  final Map<String, String> strings = {};

  @override
  bool get isSupported => true;

  @override
  Future<String> absolutePath(String relativePath) async =>
      '/fake_root/$relativePath';

  @override
  Future<bool> fileExists(String relativePath) async =>
      files.containsKey(relativePath) || strings.containsKey(relativePath);

  @override
  Future<int> fileSize(String relativePath) async =>
      files[relativePath]?.length ?? strings[relativePath]?.length ?? 0;

  @override
  Future<Uint8List> readFileBytes(String relativePath) async =>
      Uint8List.fromList(files[relativePath] ?? const []);

  @override
  Future<String> readFileString(String relativePath) async =>
      strings[relativePath] ?? '';

  @override
  Future<void> deleteFile(String relativePath) async {
    files.remove(relativePath);
    strings.remove(relativePath);
  }

  @override
  Future<void> writeFileBytes(String relativePath, List<int> bytes) async =>
      files[relativePath] = List<int>.from(bytes);

  @override
  Future<void> writeFileString(String relativePath, String contents) async =>
      strings[relativePath] = contents;
}

const _flagsOn = FeatureFlags(
  multilingualAudioEnabled: true,
  onboardingV2Enabled: false,
  bilingualPlaybackEnabled: true,
  audioDownloadsEnabled: true,
  audioQuizzesEnabled: false,
  sarvamGenerationEnabled: false,
);

const _flagsOff = FeatureFlags(
  multilingualAudioEnabled: false,
  onboardingV2Enabled: false,
  bilingualPlaybackEnabled: false,
  audioDownloadsEnabled: false,
  audioQuizzesEnabled: false,
  sarvamGenerationEnabled: false,
);

AudioTrack _narration(String url, {String id = 'n1'}) => AudioTrack(
  id: id,
  contentKind: 'rhyme',
  contentId: 'story-1',
  segmentId: 'seg-1',
  languageCode: 'sat',
  trackType: TrackType.storyNarration,
  audioUrl: url,
  reviewStatus: ReviewStatus.approved,
  isHumanRecorded: true,
);

AudioTrack _translation(String url, {String languageCode = 'en'}) => AudioTrack(
  id: 't1',
  contentKind: 'rhyme',
  contentId: 'story-1',
  segmentId: 'seg-1',
  languageCode: languageCode,
  trackType: TrackType.storyTranslation,
  audioUrl: url,
  reviewStatus: ReviewStatus.approved,
);

StorySegment _segment({
  required String id,
  required int order,
  List<AudioTrack> tracks = const [],
}) {
  return StorySegment(
    id: id,
    storyId: 'story-1',
    order: order,
    textOlChiki: 'ᱥᱟᱱᱛᱟᱞ ᱠᱟᱛᱷᱟ $order',
    textLatin: 'santal katha $order',
    translations: {'en': 'Santali story $order'},
    audioTracks: tracks,
  );
}

ContentItem _storyItem() =>
    ContentItem.empty(id: 'story-1', kind: ContentKind.rhyme);

/// track() nests the event's metadata under payload['metadata'] as a JSON
/// string; unwrap it so assertions can read the actual fields.
Map<String, dynamic> _metadataOf(
  List<(String, Map<String, dynamic>)> events,
  String name,
) {
  final payload = events.firstWhere((e) => e.$1 == name).$2;
  final raw = payload['metadata'];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  }
  return const {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync(
      'story_player_test_hive',
    );
    Hive.init(tempDir.path);
    // Open the cache box once here, on the real event loop: real file IO
    // can never complete inside the fake-async testWidgets zone, so leaving
    // the box open means no test ever awaits the (IO-backed) box open.
    // Reads are then served synchronously from the box's in-memory state.
    await Hive.openBox('content_cache');
  });

  setUp(() {
    CacheService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> makeContainer({
    required List<StorySegment> segments,
    FeatureFlags flags = _flagsOn,
    Map<String, Object> initialPrefs = const {},
    _MockAudioService? audio,
    List<(String, Map<String, dynamic>)>? analyticsEvents,
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();
    final audioService = audio ?? _MockAudioService();
    final playback = PlaybackController(audioService: audioService);
    final events = analyticsEvents ?? <(String, Map<String, dynamic>)>[];
    final analytics = LearningAnalyticsService(
      prefs: prefs,
      remoteWriter: (eventId, payload) async {
        // track() passes the event *id* (a UUID) here; the human-readable
        // name lives in the payload. Record the name for assertions.
        events.add(((payload['eventName'] ?? eventId) as String, payload));
      },
    );
    final store = _FakeStore();
    final manager = AudioDownloadManager(
      store: store,
      httpClient: MockClient(
        (request) async =>
            http.Response.bytes(Uint8List.fromList(List.filled(16, 3)), 200),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        featureFlagsProvider.overrideWithValue(flags),
        playbackControllerProvider.overrideWithValue(playback),
        learningAnalyticsServiceProvider.overrideWithValue(analytics),
        audioDownloadManagerProvider.overrideWithValue(manager),
        storySegmentsProvider.overrideWith((ref, storyId) async => segments),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(playback.dispose);
    return container;
  }

  Future<void> pumpPlayer(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: _StoryHost())),
      ),
    );
    // Let the post-frame initState callbacks (listener attach, resume
    // restore, provider resolution) run.
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders both scripts of every segment', (tester) async {
    final container = await makeContainer(
      segments: [
        _segment(
          id: 'seg-1',
          order: 1,
          tracks: [_narration('https://cdn.test/n1.mp3')],
        ),
        _segment(
          id: 'seg-2',
          order: 2,
          tracks: [_narration('https://cdn.test/n2.mp3', id: 'n2')],
        ),
      ],
    );
    await pumpPlayer(tester, container);

    expect(find.text('ᱥᱟᱱᱛᱟᱞ ᱠᱟᱛᱷᱟ 1'), findsOneWidget);
    expect(find.text('ᱥᱟᱱᱛᱟᱞ ᱠᱟᱛᱷᱟ 2'), findsOneWidget);
    // Latin rendering is visible in default 'both' script mode.
    expect(find.text('santal katha 1'), findsOneWidget);
    expect(find.text('santal katha 2'), findsOneWidget);
  });

  testWidgets('tapping a segment plays its narration audio', (tester) async {
    final audio = _MockAudioService();
    final events = <(String, Map<String, dynamic>)>[];
    final container = await makeContainer(
      segments: [
        _segment(
          id: 'seg-1',
          order: 1,
          tracks: [_narration('https://cdn.test/n1.mp3')],
        ),
      ],
      audio: audio,
      analyticsEvents: events,
    );
    await pumpPlayer(tester, container);

    await tester.tap(find.text('santal katha 1'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(audio.playedUrls, contains('https://cdn.test/n1.mp3'));
    expect(
      events.map((e) => e.$1),
      containsAll([
        LearningAnalyticsEvents.storyStarted,
        LearningAnalyticsEvents.storySegmentPlayed,
      ]),
    );
    final segmentPlayed = _metadataOf(
      events,
      LearningAnalyticsEvents.storySegmentPlayed,
    );
    expect(segmentPlayed['hasNarration'], isTrue);
  });

  testWidgets('bilingual mode chains narration before translation', (
    tester,
  ) async {
    final audio = _MockAudioService();
    final events = <(String, Map<String, dynamic>)>[];
    final container = await makeContainer(
      segments: [
        _segment(
          id: 'seg-1',
          order: 1,
          tracks: [
            _narration('https://cdn.test/n1.mp3'),
            _translation('https://cdn.test/t1.mp3'),
          ],
        ),
      ],
      initialPrefs: {'lesson_audio_mode': 'bilingual'},
      audio: audio,
      analyticsEvents: events,
    );
    await pumpPlayer(tester, container);

    await tester.tap(find.text('santal katha 1'));
    await tester.pump(const Duration(milliseconds: 100));

    // The chain head (Santali narration) plays first; the translation
    // follows via the controller's chain, not a separate play call.
    expect(audio.playedUrls.first, 'https://cdn.test/n1.mp3');
    expect(
      events.map((e) => e.$1),
      contains(LearningAnalyticsEvents.bilingualModeEnabled),
    );
  });

  testWidgets('text-only segment does not crash and emits hasNarration false', (
    tester,
  ) async {
    final audio = _MockAudioService();
    final events = <(String, Map<String, dynamic>)>[];
    final container = await makeContainer(
      segments: [_segment(id: 'seg-1', order: 1)],
      audio: audio,
      analyticsEvents: events,
    );
    await pumpPlayer(tester, container);

    // Text-only badge is visible.
    expect(find.byIcon(Icons.text_snippet_outlined), findsOneWidget);

    await tester.tap(find.text('santal katha 1'));
    await tester.pump(const Duration(milliseconds: 100));

    // No audio was requested; the reader is never blocked (spec §7).
    expect(audio.playedUrls, isEmpty);
    final segmentPlayed = _metadataOf(
      events,
      LearningAnalyticsEvents.storySegmentPlayed,
    );
    expect(segmentPlayed['hasNarration'], isFalse);
  });

  testWidgets(
    'translation toggle shows fallback text and emits fallback event',
    (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      final container = await makeContainer(
        segments: [
          _segment(
            id: 'seg-1',
            order: 1,
            tracks: [_narration('https://cdn.test/n1.mp3')],
          ),
        ],
        // Request Hindi but the segment only ships English → fallback.
        initialPrefs: {'teaching_language': 'hi'},
        analyticsEvents: events,
      );
      await pumpPlayer(tester, container);

      expect(find.text('Santali story 1'), findsNothing);
      await tester.tap(find.byIcon(Icons.visibility_off_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      // translationFor falls back to the English text — never crashes.
      expect(find.text('Santali story 1'), findsOneWidget);
      expect(
        events.map((e) => e.$1),
        contains(LearningAnalyticsEvents.translationFallbackUsed),
      );
    },
  );

  testWidgets('restoreResumePosition jumps to the saved segment', (
    tester,
  ) async {
    final audio = _MockAudioService();
    // Seed the resume cache the way _saveResumePosition writes it.
    // The box is already open (setUpAll), so CacheService.set hits no
    // open-IO; Hive applies put() to its in-memory state immediately, so
    // the entry is readable even though the returned future (file flush)
    // never completes inside the fake-async zone. Fire and forget — do NOT
    // await it.
    unawaited(
      CacheService.set('story_resume:story-1', <String, dynamic>{
        'segmentIndex': 1,
      }, ttl: const Duration(days: 30)),
    );

    final container = await makeContainer(
      segments: [
        _segment(
          id: 'seg-1',
          order: 1,
          tracks: [_narration('https://cdn.test/n1.mp3')],
        ),
        _segment(
          id: 'seg-2',
          order: 2,
          tracks: [_narration('https://cdn.test/n2.mp3', id: 'n2')],
        ),
      ],
      audio: audio,
    );
    await pumpPlayer(tester, container);
    await tester.pump(const Duration(milliseconds: 300));

    // With index 1 restored, Prev is enabled and plays segment 1's
    // audio — proving the active segment moved off the first card.
    await tester.tap(find.byIcon(Icons.skip_previous_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(audio.playedUrls, contains('https://cdn.test/n1.mp3'));
  });

  testWidgets('download button downloads the story pack', (tester) async {
    final container = await makeContainer(
      segments: [
        _segment(
          id: 'seg-1',
          order: 1,
          tracks: [
            _narration('https://cdn.test/n1.mp3'),
            _translation('https://cdn.test/t1.mp3'),
          ],
        ),
      ],
    );
    await pumpPlayer(tester, container);

    expect(container.read(downloadsAvailableProvider), isTrue);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.download_rounded));
    await tester.pump(const Duration(milliseconds: 200));

    // The pack completed: the affordance flips to "Saved".
    expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('flag off falls back to PremiumBakhedBody without crashing', (
    tester,
  ) async {
    // The fallback body drives the real (unmocked) rhyme audio provider
    // and an infinite EnchantedVisualizer animation, so pump bounded
    // durations only — never pumpAndSettle.
    //
    // PremiumBakhedBody's fixed (non-flex) column needs ~809 logical px,
    // which fits real portrait phones but overflows the default 800×600
    // test surface by 209 px (a layout-throw that fails the test). Give
    // the test a realistic portrait surface instead of touching the
    // pre-existing production layout (spec §27).
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final container = await makeContainer(
      segments: [_segment(id: 'seg-1', order: 1)],
      flags: _flagsOff,
    );
    await pumpPlayer(tester, container);
    await tester.pump(const Duration(milliseconds: 100));

    // No segment UI leaked through while the flag is off (spec §27).
    expect(find.text('santal katha 1'), findsNothing);
    expect(find.byIcon(Icons.speed_rounded), findsNothing);
  });

  testWidgets('speed control cycles playback speed', (tester) async {
    final container = await makeContainer(
      segments: [
        _segment(
          id: 'seg-1',
          order: 1,
          tracks: [_narration('https://cdn.test/n1.mp3')],
        ),
      ],
    );
    await pumpPlayer(tester, container);

    expect(find.text('1.0x'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.speed_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('0.75x'), findsOneWidget);
  });

  testWidgets('Next button plays the following segment', (tester) async {
    final audio = _MockAudioService();
    final container = await makeContainer(
      segments: [
        _segment(
          id: 'seg-1',
          order: 1,
          tracks: [_narration('https://cdn.test/n1.mp3')],
        ),
        _segment(
          id: 'seg-2',
          order: 2,
          tracks: [_narration('https://cdn.test/n2.mp3', id: 'n2')],
        ),
      ],
      audio: audio,
    );
    await pumpPlayer(tester, container);

    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(audio.playedUrls, contains('https://cdn.test/n2.mp3'));
  });
}

/// Host widget: pumps the body directly so no router is needed.
class _StoryHost extends StatelessWidget {
  const _StoryHost();

  @override
  Widget build(BuildContext context) {
    return StoryPlayerBody(item: _storyItem(), accentColor: Colors.green);
  }
}
