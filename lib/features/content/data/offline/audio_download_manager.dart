import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/logging/app_logger.dart';

import '../../domain/entities/audio_track_entity.dart';
import 'audio_download_store.dart';

/// Manifest entry for one downloaded track file.
class DownloadedTrackRecord {
  final String trackId;
  final String relativePath;

  /// [AudioTrack.contentHash] at download time — lets us detect stale
  /// downloads whose source track was regenerated (spec §13: downloads
  /// must invalidate when the upstream audio changes).
  final String? contentHash;
  final int bytes;

  /// sha256 hex digest of the file contents, verified at download time
  /// and available for later integrity re-checks.
  final String? sha256;

  final DateTime downloadedAt;

  const DownloadedTrackRecord({
    required this.trackId,
    required this.relativePath,
    this.contentHash,
    required this.bytes,
    this.sha256,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'trackId': trackId,
    'relativePath': relativePath,
    'contentHash': contentHash,
    'bytes': bytes,
    'sha256': sha256,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  static DownloadedTrackRecord fromJson(Map<String, dynamic> json) {
    return DownloadedTrackRecord(
      trackId: json['trackId'] as String? ?? '',
      relativePath: json['relativePath'] as String? ?? '',
      contentHash: json['contentHash'] as String?,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      sha256: json['sha256'] as String?,
      downloadedAt:
          DateTime.tryParse(json['downloadedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// A single item (one track) inside a [AudioDownloadBatch] progress update.
class AudioDownloadItemProgress {
  final String trackId;

  /// 0.0 – 1.0 when byte progress is known; -1 when indeterminate.
  final double fraction;

  final int receivedBytes;
  final int? totalBytes;

  const AudioDownloadItemProgress({
    required this.trackId,
    required this.fraction,
    required this.receivedBytes,
    this.totalBytes,
  });
}

/// Aggregate progress for a batch (single track or a whole story pack).
class AudioDownloadBatchProgress {
  final String batchId;
  final int completed;
  final int failed;
  final int total;

  /// Bytes written so far across completed items.
  final int bytesWritten;

  /// Latest per-item progress (null once an item finishes).
  final AudioDownloadItemProgress? currentItem;

  const AudioDownloadBatchProgress({
    required this.batchId,
    required this.completed,
    required this.failed,
    required this.total,
    required this.bytesWritten,
    this.currentItem,
  });

  double get overallFraction => total <= 0 ? 0 : (completed + failed) / total;

  bool get isDone => total > 0 && completed + failed >= total;
}

/// Failure report for one item in a batch.
class AudioDownloadItemFailure {
  final String trackId;
  final String reason;

  const AudioDownloadItemFailure({required this.trackId, required this.reason});
}

/// Result of a completed batch download.
class AudioDownloadBatchResult {
  final String batchId;
  final int succeeded;
  final int skipped;
  final int failed;
  final List<AudioDownloadItemFailure> failures;
  final int bytesWritten;

  const AudioDownloadBatchResult({
    required this.batchId,
    required this.succeeded,
    required this.skipped,
    required this.failed,
    required this.failures,
    required this.bytesWritten,
  });

  bool get hasFailures => failed > 0;
}

/// Why a track cannot be downloaded right now.
enum AudioDownloadSkipReason { missingUrl, notPlayable, unsupportedPlatform }

/// Manages offline audio downloads (spec §13 "Offline download", §15
/// downloads/cache management).
///
/// Responsibilities:
/// - fetch track files over http with per-item progress + cancellation
/// - verify sha256 integrity of the bytes that were written
/// - dedupe: an existing, hash-fresh file for the same track is skipped
/// - contentHash invalidation: a stale file (regenerated upstream) is
///   re-downloaded instead of being reused
/// - persist a JSON manifest so downloads survive restarts
/// - answer storage-usage questions and delete individual/all files
/// - resolve local `file://` URLs so [PlaybackController] can play offline
///
/// Web builds are fully supported at this layer: the injected
/// [AudioDownloadStore] reports `isSupported == false` and every method
/// degrades instead of crashing.
class AudioDownloadManager {
  static const String _manifestRelativePath = 'downloads_manifest.json';

  final AudioDownloadStore store;
  final http.Client httpClient;

  /// Timeout for each individual file fetch.
  final Duration requestTimeout;

  /// Ephemeral cancel tokens by batch id.
  final Map<String, bool> _cancelledBatches = {};

  /// Manifest cache: trackId -> record.
  Map<String, DownloadedTrackRecord>? _manifestCache;

  AudioDownloadManager({
    required this.store,
    http.Client? httpClient,
    this.requestTimeout = const Duration(seconds: 60),
  }) : httpClient = httpClient ?? http.Client();

  bool get isSupported => store.isSupported;

  // ---------------------------------------------------------------
  // Paths
  // ---------------------------------------------------------------

  /// Stable relative path for a track's audio file inside the store.
  ///
  /// Track ids are already database primary keys, so using them directly
  /// keeps the layout flat and collision-free; the extension preserves
  /// content-type for players that sniff it.
  static String relativePathForTrack(AudioTrack track) {
    final ext = _extensionForUrl(track.audioUrl);
    return 'tracks/${track.id}$ext';
  }

  static String _extensionForUrl(String? url) {
    if (url == null) return '';
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot < path.length - 5) return '';
    return path.substring(dot);
  }

  // ---------------------------------------------------------------
  // Manifest
  // ---------------------------------------------------------------

  Future<Map<String, DownloadedTrackRecord>> _loadManifest() async {
    final cached = _manifestCache;
    if (cached != null) return cached;
    if (!store.isSupported) return {};
    try {
      final raw = await store.readFileString(_manifestRelativePath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      final entries = <String, DownloadedTrackRecord>{};
      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final record = DownloadedTrackRecord.fromJson(value);
          if (record.trackId.isNotEmpty && record.relativePath.isNotEmpty) {
            entries[key] = record;
          }
        }
      });
      _manifestCache = entries;
      return entries;
    } catch (e) {
      // A corrupt/unreadable manifest means "no downloads known"; keep the
      // app usable but surface the data loss.
      AppLogger.warning('AudioDownloadManager: failed to load manifest: $e');
      return {};
    }
  }

  Future<void> _saveManifest(
    Map<String, DownloadedTrackRecord> manifest,
  ) async {
    _manifestCache = manifest;
    if (!store.isSupported) return;
    try {
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(manifest.map((key, value) => MapEntry(key, value.toJson())));
      await store.writeFileString(_manifestRelativePath, encoded);
    } catch (e) {
      AppLogger.warning('AudioDownloadManager: failed to persist manifest: $e');
    }
  }

  // ---------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------

  /// All known download records (empty on unsupported platforms).
  Future<Map<String, DownloadedTrackRecord>> allDownloads() => _loadManifest();

  /// The stored record for a track, or null when not downloaded.
  Future<DownloadedTrackRecord?> recordForTrack(String trackId) async {
    final manifest = await _loadManifest();
    return manifest[trackId];
  }

  /// Whether the track is downloaded with *fresh* content — i.e. the file
  /// exists and, when both hashes are known, matches the current
  /// [AudioTrack.contentHash].
  Future<bool> isDownloaded(AudioTrack track) async {
    final record = await recordForTrack(track.id);
    if (record == null) return false;
    if (!(await store.fileExists(record.relativePath))) return false;
    final current = track.contentHash;
    if (current != null && record.contentHash != null) {
      return record.contentHash == current;
    }
    return true;
  }

  /// Total bytes used by downloaded audio, verified against the manifest
  /// (missing files are pruned so usage never over-counts).
  Future<int> storageUsageBytes() async {
    final manifest = await _loadManifest();
    var total = 0;
    final stale = <String>[];
    for (final entry in manifest.entries) {
      final exists = await store.fileExists(entry.value.relativePath);
      if (!exists) {
        stale.add(entry.key);
      } else {
        total += entry.value.bytes > 0
            ? entry.value.bytes
            : await store.fileSize(entry.value.relativePath);
      }
    }
    if (stale.isNotEmpty) {
      final pruned = Map<String, DownloadedTrackRecord>.from(manifest)
        ..removeWhere((key, _) => stale.contains(key));
      await _saveManifest(pruned);
    }
    return total;
  }

  /// Number of tracks recorded in the manifest.
  Future<int> downloadCount() async => (await _loadManifest()).length;

  /// Local playback URL for a downloaded track, or null when missing.
  ///
  /// Returns an absolute `file://` URL the existing [PlaybackController]
  /// can hand to [AudioService.tryPlayUrl] unchanged — no duplicate audio
  /// service (spec §27).
  Future<String?> localFileUrlFor(AudioTrack track) async {
    final record = await recordForTrack(track.id);
    if (record == null) return null;
    if (!(await store.fileExists(record.relativePath))) return null;
    final absolute = await store.absolutePath(record.relativePath);
    return Uri.file(absolute).toString();
  }

  // ---------------------------------------------------------------
  // Downloading
  // ---------------------------------------------------------------

  /// Skip-reason for a track that cannot be downloaded, or null when it
  /// can be.
  AudioDownloadSkipReason? skipReasonFor(AudioTrack track) {
    if (!store.isSupported) {
      return AudioDownloadSkipReason.unsupportedPlatform;
    }
    final url = track.audioUrl;
    if (url == null || url.trim().isEmpty) {
      return AudioDownloadSkipReason.missingUrl;
    }
    if (!track.isPlayable) return AudioDownloadSkipReason.notPlayable;
    return null;
  }

  /// Cancels an in-flight batch. Items already written stay on disk.
  void cancelBatch(String batchId) {
    _cancelledBatches[batchId] = true;
  }

  bool _isCancelled(String batchId) => _cancelledBatches[batchId] == true;

  /// Downloads a single track.
  ///
  /// Returns the resulting [AudioDownloadBatchResult]; `onProgress` fires
  /// with batch-level updates (single-item batches).
  Future<AudioDownloadBatchResult> downloadTrack(
    AudioTrack track, {
    void Function(AudioDownloadBatchProgress progress)? onProgress,
    http.Client? client,
  }) {
    return downloadTracks(
      [track],
      batchId: 'single:${track.id}',
      onProgress: onProgress,
      client: client,
    );
  }

  /// Downloads a batch of tracks (e.g. a whole story pack).
  ///
  /// Each item is fetched, hash-verified, written, and recorded in the
  /// manifest. Existing fresh files are skipped (dedupe); items whose
  /// upstream [AudioTrack.contentHash] changed are re-downloaded.
  Future<AudioDownloadBatchResult> downloadTracks(
    List<AudioTrack> tracks, {
    required String batchId,
    void Function(AudioDownloadBatchProgress progress)? onProgress,
    http.Client? client,
  }) async {
    final http = client ?? httpClient;
    if (!store.isSupported) {
      return AudioDownloadBatchResult(
        batchId: batchId,
        succeeded: 0,
        skipped: 0,
        failed: tracks.length,
        failures: [
          for (final track in tracks)
            AudioDownloadItemFailure(
              trackId: track.id,
              reason: 'unsupported platform',
            ),
        ],
        bytesWritten: 0,
      );
    }

    _cancelledBatches.remove(batchId);
    final manifest = Map<String, DownloadedTrackRecord>.from(
      await _loadManifest(),
    );

    // Partition: skip un-downloadable tracks entirely (they don't count
    // against the batch totals), dedupe fresh files, download the rest.
    final downloadable = <AudioTrack>[];
    var skipped = 0;
    for (final track in tracks) {
      if (skipReasonFor(track) != null) continue;
      final fresh = await isDownloaded(track);
      if (fresh) {
        skipped++;
      } else {
        downloadable.add(track);
      }
    }

    final total = downloadable.length;
    var completed = 0;
    var failed = 0;
    var bytesWritten = 0;
    final failures = <AudioDownloadItemFailure>[];

    void emit() {
      onProgress?.call(
        AudioDownloadBatchProgress(
          batchId: batchId,
          completed: completed,
          failed: failed,
          total: total,
          bytesWritten: bytesWritten,
        ),
      );
    }

    emit();
    if (total == 0) {
      _cancelledBatches.remove(batchId);
      return AudioDownloadBatchResult(
        batchId: batchId,
        succeeded: 0,
        skipped: skipped,
        failed: 0,
        failures: const [],
        bytesWritten: 0,
      );
    }

    for (final track in downloadable) {
      if (_isCancelled(batchId)) {
        break;
      }
      try {
        final bytes = await _fetchBytes(track, http, (received, totalBytes) {
          onProgress?.call(
            AudioDownloadBatchProgress(
              batchId: batchId,
              completed: completed,
              failed: failed,
              total: total,
              bytesWritten: bytesWritten,
              currentItem: AudioDownloadItemProgress(
                trackId: track.id,
                fraction: totalBytes != null && totalBytes > 0
                    ? (received / totalBytes).clamp(0.0, 1.0)
                    : -1,
                receivedBytes: received,
                totalBytes: totalBytes,
              ),
            ),
          );
        });

        if (_isCancelled(batchId)) break;

        final digest = crypto.sha256.convert(bytes).toString();
        final relativePath = relativePathForTrack(track);
        await store.writeFileBytes(relativePath, bytes);
        manifest[track.id] = DownloadedTrackRecord(
          trackId: track.id,
          relativePath: relativePath,
          contentHash: track.contentHash,
          bytes: bytes.length,
          sha256: digest,
          downloadedAt: DateTime.now(),
        );
        await _saveManifest(manifest);
        bytesWritten += bytes.length;
        completed++;
      } catch (e) {
        failed++;
        // Surface a human-readable reason: domain exceptions carry the
        // useful message (e.g. "HTTP 404"), not the default toString.
        final reason = switch (e) {
          final ServerException e => e.message,
          _ => '$e',
        };
        failures.add(
          AudioDownloadItemFailure(trackId: track.id, reason: reason),
        );
        AppLogger.warning(
          'AudioDownloadManager: download failed for ${track.id}: $e',
        );
      }
      emit();
    }

    _cancelledBatches.remove(batchId);
    return AudioDownloadBatchResult(
      batchId: batchId,
      succeeded: completed,
      skipped: skipped,
      failed: failed,
      failures: failures,
      bytesWritten: bytesWritten,
    );
  }

  /// Downloads every playable track attached to a story's segments
  /// (narration + translations). The batch id is
  /// `story:<storyId>` so callers can cancel by story.
  Future<AudioDownloadBatchResult> downloadStoryPack(
    String storyId,
    Iterable<DownloadableTrack> tracks, {
    void Function(AudioDownloadBatchProgress progress)? onProgress,
    http.Client? client,
  }) {
    return downloadTracks(
      tracks
          .map((entry) => entry.track)
          .where((track) => skipReasonFor(track) == null)
          .toList(),
      batchId: 'story:$storyId',
      onProgress: onProgress,
      client: client,
    );
  }

  Future<Uint8List> _fetchBytes(
    AudioTrack track,
    http.Client client,
    void Function(int received, int? totalBytes)? onProgress,
  ) async {
    final url = track.audioUrl;
    if (url == null || url.trim().isEmpty) {
      throw ServerException(message: 'Audio unavailable');
    }
    final response = await client.get(Uri.parse(url)).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw ServerException(
        message: 'HTTP ${response.statusCode}',
        code: response.statusCode,
      );
    }
    final totalBytes = response.contentLength;
    final bytes = response.bodyBytes;
    onProgress?.call(bytes.length, totalBytes);
    return bytes;
  }

  // ---------------------------------------------------------------
  // Deletion / cache management
  // ---------------------------------------------------------------

  /// Deletes one track's file and manifest entry.
  Future<void> deleteTrack(String trackId) async {
    final manifest = await _loadManifest();
    final record = manifest[trackId];
    if (record == null) return;
    await store.deleteFile(record.relativePath);
    manifest.remove(trackId);
    await _saveManifest(manifest);
  }

  /// Deletes every downloaded file and the manifest itself.
  Future<void> deleteAll() async {
    final manifest = await _loadManifest();
    for (final record in manifest.values) {
      try {
        await store.deleteFile(record.relativePath);
      } catch (_) {
        // Best-effort wipe; manifest reset below makes stragglers inert.
      }
    }
    _manifestCache = {};
    await _saveManifest({});
  }

  /// Re-verifies a record's stored sha256 against the file on disk.
  Future<bool> verifyIntegrity(DownloadedTrackRecord record) async {
    if (record.sha256 == null) return true;
    try {
      if (!(await store.fileExists(record.relativePath))) return false;
      final bytes = await store.readFileBytes(record.relativePath);
      return crypto.sha256.convert(bytes).toString() == record.sha256;
    } catch (_) {
      // An unreadable file cannot be verified — treating it as corrupt is
      // the intended semantic of this check.
      return false;
    }
  }
}

/// A track plus the story/segment it belongs to, used when assembling a
/// story pack download.
class DownloadableTrack {
  final AudioTrack track;
  final String? segmentId;

  const DownloadableTrack({required this.track, this.segmentId});
}
