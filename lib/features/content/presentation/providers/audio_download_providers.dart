import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/config/feature_flags.dart';
import 'package:itun/core/logging/app_logger.dart';

import '../../data/offline/audio_download_manager.dart';
import '../../data/offline/audio_download_store.dart';
import '../../domain/entities/audio_track_entity.dart';
import '../../domain/entities/story_segment_entity.dart';

/// Phase 6 wiring: the offline download manager + reactive download
/// state (spec §13 "Offline download", §15 cache management).
///
/// Downloads are gated by BOTH the `audio_downloads_enabled` feature
/// flag AND the platform store's capability (web is not supported), so
/// download UI can simply check [downloadsAvailableProvider] and never
/// worry about crashing on the web build (spec §27: keep web
/// functional).

final audioDownloadStoreProvider = Provider<AudioDownloadStore>((ref) {
  return createAudioDownloadStore();
});

/// The shared [AudioDownloadManager]; constructed even when downloads
/// are flag-disabled because its query methods degrade safely — UI
/// surfaces check [downloadsAvailableProvider] instead.
final audioDownloadManagerProvider = Provider<AudioDownloadManager>((ref) {
  return AudioDownloadManager(store: ref.watch(audioDownloadStoreProvider));
});

/// Whether offline downloads can be used at all on this build
/// (flag + platform capable). Web builds stay functional with download
/// affordances simply hidden.
final downloadsAvailableProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  final store = ref.watch(audioDownloadStoreProvider);
  return flags.audioDownloadsEnabled && store.isSupported;
});

/// State of one item in the [audioDownloadProvider] map.
enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

/// Per-track download state surfaced to the UI.
class TrackDownloadState {
  final DownloadStatus status;

  const TrackDownloadState({required this.status});

  const TrackDownloadState.initial()
    : this(status: DownloadStatus.notDownloaded);

  const TrackDownloadState.downloaded()
    : this(status: DownloadStatus.downloaded);

  const TrackDownloadState.failed() : this(status: DownloadStatus.failed);

  bool get isDownloading => status == DownloadStatus.downloading;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackDownloadState && other.status == status;

  @override
  int get hashCode => status.hashCode;
}

/// Aggregated progress for a story pack download keyed by story id.
class StoryDownloadState {
  final DownloadStatus status;
  final int completed;
  final int total;
  final int bytesWritten;

  const StoryDownloadState({
    this.status = DownloadStatus.notDownloaded,
    this.completed = 0,
    this.total = 0,
    this.bytesWritten = 0,
  });

  double get progress => total <= 0 ? 0 : (completed / total).clamp(0.0, 1.0);

  StoryDownloadState copyWith({
    DownloadStatus? status,
    int? completed,
    int? total,
    int? bytesWritten,
  }) {
    return StoryDownloadState(
      status: status ?? this.status,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      bytesWritten: bytesWritten ?? this.bytesWritten,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryDownloadState &&
          other.status == status &&
          other.completed == completed &&
          other.total == total &&
          other.bytesWritten == bytesWritten;

  @override
  int get hashCode => Object.hash(status, completed, total, bytesWritten);
}

/// Mutable notifier holding per-story pack download progress so story
/// cards, the story player, and settings can all render download state
/// without re-implementing it.
class AudioDownloadNotifier extends Notifier<Map<String, Object>> {
  static const String storyKeyPrefix = 'story:';

  @override
  Map<String, Object> build() => const {};

  static String storyKey(String storyId) => '$storyKeyPrefix$storyId';

  void _update(String key, Object value) {
    state = {...state, key: value};
  }

  /// Hydrates state for tracks that are already on disk (called when a
  /// story's segments resolve). Verifies each file is actually present —
  /// a manifest record alone is not enough, since OS cleanup or external
  /// deletion can remove files behind our back. Safe on web: the manager
  /// degrades to "nothing downloaded".
  Future<void> refreshTrackStates(Iterable<String> trackIds) async {
    if (trackIds.isEmpty) return;
    final manager = ref.read(audioDownloadManagerProvider);
    final next = Map<String, Object>.from(state);
    for (final trackId in trackIds) {
      final present = await manager.isTrackFilePresent(trackId);
      next[trackId] = present
          ? const TrackDownloadState.downloaded()
          : const TrackDownloadState.initial();
    }
    state = next;
  }

  /// Downloads a whole story pack (narration + translation tracks).
  ///
  /// Emits `course_download_started` / `course_download_completed` /
  /// `course_download_failed` analytics (spec §16). No PII is included —
  /// only ids, counts, and byte totals.
  Future<void> downloadStory(
    String storyId,
    List<DownloadableTrack> tracks,
  ) async {
    if (!ref.read(downloadsAvailableProvider)) return;
    final manager = ref.read(audioDownloadManagerProvider);
    final batchKey = storyKey(storyId);

    _update(
      batchKey,
      StoryDownloadState(
        status: DownloadStatus.downloading,
        total: tracks.length,
      ),
    );

    final analytics = ref.read(learningAnalyticsServiceProvider);
    await analytics.track(
      LearningAnalyticsEvents.courseDownloadStarted,
      source: 'story',
      sourceId: storyId,
      metadata: {'trackCount': tracks.length},
    );

    final result = await manager.downloadTracks(
      tracks.map((entry) => entry.track).toList(),
      batchId: batchKey,
      onProgress: (progress) {
        _update(
          batchKey,
          StoryDownloadState(
            status: DownloadStatus.downloading,
            completed: progress.completed + progress.failed,
            total: progress.total,
            bytesWritten: progress.bytesWritten,
          ),
        );
      },
    );

    if (result.failed > 0) {
      final previous = state[batchKey] is StoryDownloadState
          ? state[batchKey]! as StoryDownloadState
          : const StoryDownloadState();
      _update(batchKey, previous.copyWith(status: DownloadStatus.failed));
      await analytics.track(
        LearningAnalyticsEvents.courseDownloadFailed,
        source: 'story',
        sourceId: storyId,
        metadata: {
          'failed': result.failed,
          'succeeded': result.succeeded,
          'skipped': result.skipped,
        },
      );
      AppLogger.warning(
        'AudioDownloadNotifier: story pack download for $storyId had '
        '${result.failed} failed tracks',
      );
      return;
    }

    _update(
      batchKey,
      StoryDownloadState(
        status: DownloadStatus.downloaded,
        total: result.succeeded + result.skipped,
        completed: result.succeeded + result.skipped,
        bytesWritten: result.bytesWritten,
      ),
    );
    await analytics.track(
      LearningAnalyticsEvents.courseDownloadCompleted,
      source: 'story',
      sourceId: storyId,
      metadata: {
        'succeeded': result.succeeded,
        'skipped': result.skipped,
        'bytesWritten': result.bytesWritten,
      },
    );
    // Per-track states now reflect the downloaded files.
    await refreshTrackStates([for (final entry in tracks) entry.track.id]);
  }

  /// Cancels an in-flight story download (completed items stay).
  void cancelStoryDownload(String storyId) {
    final manager = ref.read(audioDownloadManagerProvider);
    manager.cancelBatch(storyKey(storyId));
    _update(storyKey(storyId), const StoryDownloadState());
  }

  /// Deletes one downloaded track (settings cache management).
  Future<void> deleteTrack(String trackId) async {
    final manager = ref.read(audioDownloadManagerProvider);
    await manager.deleteTrack(trackId);
    final next = Map<String, Object>.from(state)
      ..[trackId] = const TrackDownloadState.initial();
    state = next;
  }

  /// Deletes all downloaded audio (settings "clear downloads").
  Future<void> deleteAll() async {
    final manager = ref.read(audioDownloadManagerProvider);
    await manager.deleteAll();
    state = const {};
  }
}

final audioDownloadProvider =
    NotifierProvider<AudioDownloadNotifier, Map<String, Object>>(
      AudioDownloadNotifier.new,
    );

/// Download state for a specific story pack.
final storyDownloadStateProvider = Provider.family<StoryDownloadState, String>((
  ref,
  storyId,
) {
  final map = ref.watch(audioDownloadProvider);
  final value = map[AudioDownloadNotifier.storyKey(storyId)];
  return value is StoryDownloadState ? value : const StoryDownloadState();
});

/// Total bytes used by downloaded audio. Re-evaluates whenever download
/// state changes.
final downloadStorageUsageProvider = FutureProvider<int>((ref) {
  ref.watch(audioDownloadProvider);
  final manager = ref.watch(audioDownloadManagerProvider);
  return manager.storageUsageBytes();
});

/// Number of downloaded tracks. Re-evaluates whenever download state
/// changes.
final downloadCountProvider = FutureProvider<int>((ref) {
  ref.watch(audioDownloadProvider);
  final manager = ref.watch(audioDownloadManagerProvider);
  return manager.downloadCount();
});

/// Assembles the downloadable pack for a story from its hydrated
/// segments: every playable narration + translation track (spec §13:
/// "download the story's audio").
List<DownloadableTrack> downloadableTracksFromSegments(
  List<StorySegment> segments,
) {
  final tracks = <DownloadableTrack>[];
  for (final segment in segments) {
    final narration = segment.narrationTrack;
    if (narration != null) {
      tracks.add(DownloadableTrack(track: narration, segmentId: segment.id));
    }
    for (final track in segment.audioTracks) {
      if (track.trackType == TrackType.storyTranslation && track.isPlayable) {
        tracks.add(DownloadableTrack(track: track, segmentId: segment.id));
      }
    }
  }
  return tracks;
}
