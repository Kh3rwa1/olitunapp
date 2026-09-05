import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/config/feature_flags.dart';
import 'package:itun/features/content/data/offline/audio_download_manager.dart';
import 'package:itun/features/content/data/offline/audio_download_store.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart'
    show ReviewStatus;
import 'package:itun/features/content/domain/entities/story_segment_entity.dart';
import 'package:itun/features/content/presentation/providers/audio_download_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory store double (same shape as the manager test's fake).
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
      files.containsKey(relativePath);

  @override
  Future<int> fileSize(String relativePath) async =>
      files[relativePath]?.length ?? 0;

  @override
  Future<Uint8List> readFileBytes(String relativePath) async =>
      Uint8List.fromList(files[relativePath] ?? const []);

  @override
  Future<String> readFileString(String relativePath) async =>
      strings[relativePath] ?? '';

  @override
  Future<void> deleteFile(String relativePath) async =>
      files.remove(relativePath);

  @override
  Future<void> writeFileBytes(String relativePath, List<int> bytes) async =>
      files[relativePath] = List<int>.from(bytes);

  @override
  Future<void> writeFileString(String relativePath, String contents) async =>
      strings[relativePath] = contents;
}

AudioTrack _narration({
  required String id,
  String url = 'https://cdn.test/n.mp3',
}) {
  return AudioTrack(
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
}

AudioTrack _translationTrack({
  required String id,
  String languageCode = 'en',
  bool approved = true,
}) {
  return AudioTrack(
    id: id,
    contentKind: 'rhyme',
    contentId: 'story-1',
    segmentId: 'seg-1',
    languageCode: languageCode,
    trackType: TrackType.storyTranslation,
    audioUrl: 'https://cdn.test/$id.mp3',
    reviewStatus: approved ? ReviewStatus.approved : ReviewStatus.draft,
  );
}

StorySegment _segment({
  required String id,
  List<AudioTrack> tracks = const [],
}) {
  return StorySegment(
    id: id,
    storyId: 'story-1',
    order: 1,
    textOlChiki: 'ᱥᱟᱱᱛᱟᱞ',
    textLatin: 'santal',
    translations: const {'en': 'Santal'},
    audioTracks: tracks,
  );
}

const _allOn = FeatureFlags(
  multilingualAudioEnabled: true,
  onboardingV2Enabled: true,
  bilingualPlaybackEnabled: true,
  audioDownloadsEnabled: true,
  audioQuizzesEnabled: true,
  sarvamGenerationEnabled: true,
);

const _allOff = FeatureFlags(
  multilingualAudioEnabled: false,
  onboardingV2Enabled: false,
  bilingualPlaybackEnabled: false,
  audioDownloadsEnabled: false,
  audioQuizzesEnabled: false,
  sarvamGenerationEnabled: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeStore store;
  late http.Client okClient;
  late List<(String, Map<String, dynamic>)> analyticsEvents;
  late ProviderContainer container;

  setUp(() async {
    store = _FakeStore();
    okClient = MockClient(
      (request) async =>
          http.Response.bytes(Uint8List.fromList(List.filled(32, 7)), 200),
    );
    analyticsEvents = [];
  });

  tearDown(() async {
    container.dispose();
  });

  Future<ProviderContainer> makeContainer({
    required List<DownloadableTrack> tracks,
    FeatureFlags flags = _allOn,
    http.Client? client,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final analytics = LearningAnalyticsService(
      prefs: prefs,
      remoteWriter: (eventId, payload) async {
        // track() passes the event *id* (a UUID) here; the human-readable
        // name lives in the payload. Record the name for assertions.
        analyticsEvents.add((
          (payload['eventName'] ?? eventId) as String,
          payload,
        ));
      },
    );
    final manager = AudioDownloadManager(
      store: store,
      httpClient: client ?? okClient,
    );
    container = ProviderContainer(
      overrides: [
        featureFlagsProvider.overrideWithValue(flags),
        audioDownloadManagerProvider.overrideWithValue(manager),
        learningAnalyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
    return container;
  }

  group('downloadsAvailableProvider', () {
    test('true when flag on and platform store supported', () async {
      final c = await makeContainer(tracks: const []);
      expect(c.read(downloadsAvailableProvider), isTrue);
    });

    test('false when the audio-downloads flag is off (spec §27)', () async {
      final c = await makeContainer(tracks: const [], flags: _allOff);
      expect(c.read(downloadsAvailableProvider), isFalse);
    });
  });

  group('downloadableTracksFromSegments', () {
    test('selects playable narration + translation tracks only', () {
      final segment = _segment(
        id: 'seg-1',
        tracks: [
          _narration(id: 'n1'),
          _translationTrack(id: 't1'),
          // Draft (unapproved) translation must be excluded.
          _translationTrack(id: 't2', languageCode: 'hi', approved: false),
          // Wrong track type must be excluded.
          const AudioTrack(
            id: 'x1',
            contentKind: 'rhyme',
            contentId: 'story-1',
            segmentId: 'seg-1',
            languageCode: 'en',
            trackType: TrackType.translation,
            audioUrl: 'https://cdn.test/x.mp3',
            reviewStatus: ReviewStatus.approved,
          ),
        ],
      );

      final pack = downloadableTracksFromSegments([segment]);
      expect(pack.map((e) => e.track.id), ['n1', 't1']);
      expect(pack.every((e) => e.segmentId == 'seg-1'), isTrue);
    });

    test('empty segments produce an empty pack', () {
      expect(downloadableTracksFromSegments(const []), isEmpty);
    });

    test('segment with no playable audio produces nothing', () {
      final pack = downloadableTracksFromSegments([
        _segment(
          id: 'seg-2',
          tracks: [_translationTrack(id: 't9', approved: false)],
        ),
      ]);
      expect(pack, isEmpty);
    });
  });

  group('AudioDownloadNotifier.downloadStory', () {
    test(
      'success: downloaded state, completed analytics, track states',
      () async {
        final c = await makeContainer(
          tracks: [
            DownloadableTrack(track: _narration(id: 'n1')),
            DownloadableTrack(track: _translationTrack(id: 't1')),
          ],
        );

        await c.read(audioDownloadProvider.notifier).downloadStory('story-1', [
          DownloadableTrack(track: _narration(id: 'n1')),
          DownloadableTrack(track: _translationTrack(id: 't1')),
        ]);

        final state = c.read(storyDownloadStateProvider('story-1'));
        expect(state.status, DownloadStatus.downloaded);
        expect(state.completed, 2);
        expect(state.total, 2);

        // Analytics: started + completed, no failure event.
        expect(
          analyticsEvents.map((e) => e.$1),
          containsAll([
            LearningAnalyticsEvents.courseDownloadStarted,
            LearningAnalyticsEvents.courseDownloadCompleted,
          ]),
        );
        expect(
          analyticsEvents.map((e) => e.$1),
          isNot(contains(LearningAnalyticsEvents.courseDownloadFailed)),
        );

        // Per-track states hydrated from disk.
        final trackState =
            c.read(audioDownloadProvider)['n1'] as TrackDownloadState;
        expect(trackState.status, DownloadStatus.downloaded);

        // Storage + count providers reflect the downloads.
        expect(await c.read(downloadCountProvider.future), 2);
        expect(await c.read(downloadStorageUsageProvider.future), 64);
      },
    );

    test('failure: failed state + course_download_failed analytics', () async {
      final failing = MockClient(
        (request) async => http.Response.bytes([], 500),
      );
      final c = await makeContainer(
        tracks: [DownloadableTrack(track: _narration(id: 'n1'))],
        client: failing,
      );

      await c.read(audioDownloadProvider.notifier).downloadStory('story-1', [
        DownloadableTrack(track: _narration(id: 'n1')),
      ]);

      expect(
        c.read(storyDownloadStateProvider('story-1')).status,
        DownloadStatus.failed,
      );
      expect(
        analyticsEvents.map((e) => e.$1),
        contains(LearningAnalyticsEvents.courseDownloadFailed),
      );
    });

    test('no-op when downloads are unavailable (flag off)', () async {
      final c = await makeContainer(
        tracks: [DownloadableTrack(track: _narration(id: 'n1'))],
        flags: _allOff,
      );

      await c.read(audioDownloadProvider.notifier).downloadStory('story-1', [
        DownloadableTrack(track: _narration(id: 'n1')),
      ]);

      expect(c.read(audioDownloadProvider), isEmpty);
      expect(analyticsEvents, isEmpty);
      expect(store.files, isEmpty);
    });
  });

  group('cache management (settings)', () {
    test('deleteAll clears state and disk', () async {
      final c = await makeContainer(tracks: const []);
      final notifier = c.read(audioDownloadProvider.notifier);
      await notifier.downloadStory('story-1', [
        DownloadableTrack(track: _narration(id: 'n1')),
      ]);
      expect(store.files, isNotEmpty);

      await notifier.deleteAll();
      expect(c.read(audioDownloadProvider), isEmpty);
      expect(store.files, isEmpty);
      expect(await c.read(downloadCountProvider.future), 0);
    });

    test('deleteTrack resets that track state', () async {
      final c = await makeContainer(tracks: const []);
      final notifier = c.read(audioDownloadProvider.notifier);
      await notifier.downloadStory('story-1', [
        DownloadableTrack(track: _narration(id: 'n1')),
      ]);

      await notifier.deleteTrack('n1');
      expect(
        (c.read(audioDownloadProvider)['n1'] as TrackDownloadState).status,
        DownloadStatus.notDownloaded,
      );
      expect(store.files, isEmpty);
    });

    test('refreshTrackStates hydrates already-downloaded tracks', () async {
      final c = await makeContainer(tracks: const []);
      // Seed the store directly, then refresh state.
      await store.writeFileBytes('tracks/n1.mp3', List.filled(8, 1));
      await (c.read(audioDownloadManagerProvider)).downloadStoryPack('warm', [
        DownloadableTrack(track: _narration(id: 'n1')),
      ]);
      // Wipe provider state but keep disk; refresh must re-hydrate.
      c.read(audioDownloadProvider.notifier).state = const {};
      await c.read(audioDownloadProvider.notifier).refreshTrackStates(['n1']);
      expect(
        (c.read(audioDownloadProvider)['n1'] as TrackDownloadState).status,
        DownloadStatus.downloaded,
      );
    });

    test(
      'refreshTrackStates does not report wiped files as downloaded',
      () async {
        final c = await makeContainer(tracks: const []);
        await (c.read(audioDownloadManagerProvider)).downloadStoryPack('warm', [
          DownloadableTrack(track: _narration(id: 'n1')),
        ]);
        // External wipe (OS cleanup, user deleted files): the manifest still
        // lists the track, but the file is gone — the badge must not claim
        // "Saved".
        await store.deleteFile('tracks/n1.mp3');
        c.read(audioDownloadProvider.notifier).state = const {};
        await c.read(audioDownloadProvider.notifier).refreshTrackStates(['n1']);
        expect(
          (c.read(audioDownloadProvider)['n1'] as TrackDownloadState).status,
          DownloadStatus.notDownloaded,
        );
      },
    );

    test('downloadCount ignores records whose files are missing', () async {
      final c = await makeContainer(tracks: const []);
      final manager = c.read(audioDownloadManagerProvider);
      await manager.downloadStoryPack('warm', [
        DownloadableTrack(track: _narration(id: 'n1')),
      ]);
      expect(await manager.downloadCount(), 1);

      await store.deleteFile('tracks/n1.mp3');
      expect(await manager.downloadCount(), 0);
    });
  });

  group('storyDownloadStateProvider', () {
    test('defaults to a fresh notDownloaded state', () async {
      final c = await makeContainer(tracks: const []);
      final state = c.read(storyDownloadStateProvider('unknown'));
      expect(state.status, DownloadStatus.notDownloaded);
      expect(state.progress, 0);
    });
  });
}
