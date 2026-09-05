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
