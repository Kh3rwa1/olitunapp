// ignore_for_file: experimental_member_use
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/core/storage/video_web_helper.dart';
import 'package:itun/core/storage/worker_media_api.dart';

/// CANONICAL upload path for ALL audio/image/video media in the app.
///
/// - Uploads to R2 through the Cloudflare Worker (admin JWT); public buckets
///   are served at `/api/v1/assets/<bucket>/<fileId>`.
/// - For audio MIME types, probes duration synchronously via just_audio
///   before returning. Result includes durationMs.
/// - Reports upload state via MediaPickerField's onUploadStateChanged
///   callback so editors can block Save during in-flight uploads.
/// - DO NOT create parallel upload utilities — extend this instead.
///
/// The Worker serves assets with byte-range support, which HTML5 audio needs
/// for seek/duration.
class MediaUploader {
  final WorkerMediaApi _api;

  MediaUploader(this._api);

  /// Buckets tried, in order, when [delete] is called without a bucket.
  static const List<String> deleteFallbackBuckets = [
    'images',
    'videos',
    'audio',
    'animations',
    'cover_videos',
  ];

  /// Picks a file and uploads it to R2 via the Worker, returning `Either<Failure, ContentMedia>`.
  /// If [allowedExtensions] is provided, it filters the file picker.
  Future<Either<Failure, ContentMedia>> pickAndUpload({
    required ContentMediaKind kind,
    String folder = 'content',
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: _getFileType(kind),
        allowedExtensions: _getAllowedExtensions(kind),
      );

      if (result == null || result.files.isEmpty) {
        return left(const ValidationFailure(message: 'No file selected'));
      }

      final file = result.files.first;
      final validationRes = await validateFile(file, kind);
      int? probedDurationMs;
      final failure = validationRes.fold((f) => f, (duration) {
        probedDurationMs = duration;
        return null;
      });
      if (failure != null) {
        return left(failure);
      }

      final bucketId = _getBucketId(kind, file.name);
      final filename = _storageFilename(file.name, folder);
      final contentType =
          mediaContentTypes[file.name.split('.').last.toLowerCase()];
      if (contentType == null) {
        return left(
          ValidationFailure(message: 'Unsupported file type: ${file.name}'),
        );
      }
      if (file.bytes == null && file.path == null) {
        return left(
          const ValidationFailure(
            message:
                'File data is not available (both bytes and path are null)',
          ),
        );
      }

      final uploaded = await _api.uploadFile(
        file: file,
        bucketId: bucketId,
        contentType: contentType,
        filename: filename,
      );

      int? durationMs = probedDurationMs;
      if (kind == ContentMediaKind.audio ||
          file.name.toLowerCase().endsWith('.mp3') ||
          file.name.toLowerCase().endsWith('.m4a') ||
          file.name.toLowerCase().endsWith('.wav') ||
          file.name.toLowerCase().endsWith('.ogg') ||
          file.name.toLowerCase().endsWith('.aac')) {
        durationMs = await _probeAudioDurationMs(file);
      }

      final media = ContentMedia(
        url: workerAssetUrl(bucketId, uploaded.fileId),
        fileId: uploaded.fileId,
        kind: kind,
        durationMs: durationMs,
      );

      return right(media);
    } catch (e) {
      return left(ServerFailure(message: 'Storage upload failed: $e'));
    }
  }

  /// Deletes a file from R2 via the Worker. Without [bucketId], tries
  /// [deleteFallbackBuckets] until one held the file.
  Future<Either<Failure, Unit>> delete(
    String fileId, [
    String? bucketId,
  ]) async {
    try {
      if (bucketId != null) {
        await _api.delete(bucketId, fileId);
      } else {
        for (final bucket in deleteFallbackBuckets) {
          if (await _api.delete(bucket, fileId)) break;
        }
      }
      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: 'Storage deletion failed: $e'));
    }
  }

  /// Deletes a file ONLY if no D1 content row references it (checked by the
  /// Worker across all content tables; [checks] name the expected referrers
  /// for logging). Refuses deletion if references are found or the check
  /// fails (fail-safe).
  Future<Either<Failure, Unit>> deleteIfUnreferenced({
    required String fileId,
    required List<ReferenceCheck> checks,
    String? bucketId,
  }) async {
    if (fileId.isEmpty) {
      return right(unit);
    }

    final bool referenced;
    try {
      referenced = await _api.isReferenced(fileId);
    } catch (e) {
      AppLogger.error(
        'Reference check failed for $fileId: $e. Refusing deletion as a fail-safe.',
        name: 'MediaUploader',
      );
      return right(unit); // Refuse deletion, return successful no-op
    }
    if (referenced) {
      AppLogger.warning(
        'Refusing to delete actively-referenced file $fileId '
        '(checked: ${checks.map((c) => c.collectionId).join(', ')})',
        name: 'MediaUploader',
      );
      return right(unit); // Refuse deletion, return successful no-op
    }
    return delete(fileId, bucketId);
  }

  FileType _getFileType(ContentMediaKind kind) {
    switch (kind) {
      case ContentMediaKind.image:
      case ContentMediaKind.svg:
        return FileType.image;
      case ContentMediaKind.video:
        return FileType.video;
      case ContentMediaKind.audio:
        return FileType.audio;
      case ContentMediaKind.lottie:
        return FileType.custom;
    }
  }

  List<String>? _getAllowedExtensions(ContentMediaKind kind) {
    if (kind == ContentMediaKind.lottie) {
      return ['json', 'lottie'];
    }
    if (kind == ContentMediaKind.video) {
      return ['mp4', 'webm', 'mov'];
    }
    return null;
  }

  /// Exposed only for unit testing bucket routing.
  String getBucketIdForTesting(ContentMediaKind kind, String filename) {
    return _getBucketId(kind, filename);
  }

  String _getBucketId(ContentMediaKind kind, String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'svg') return 'images';
    if (ext == 'json' || ext == 'lottie') return 'animations';

    switch (kind) {
      case ContentMediaKind.image:
      case ContentMediaKind.svg:
        return 'images';
      case ContentMediaKind.video:
        return 'cover_videos';
      case ContentMediaKind.audio:
        return 'audio';
      case ContentMediaKind.lottie:
        return 'animations';
    }
  }

  String _storageFilename(String filename, String folder) {
    final sanitizedFolder = folder
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final cleanFolder = sanitizedFolder.isEmpty ? 'content' : sanitizedFolder;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final sanitizedFilename = filename
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return '$cleanFolder-$timestamp-$sanitizedFilename';
  }

  /// Probes audio duration synchronously before upload completes.
  /// Visible for testing.
  Future<int?> probeAudioDurationMs(PlatformFile file) =>
      _probeAudioDurationMs(file);

  /// Probes audio duration synchronously before upload completes.
  /// On native: uses setFilePath (memory-efficient).
  /// On web: loads full file into memory via BytesAudioSource.
  /// TODO(perf): For web with files >10MB, parse MP3 header directly
  ///   instead of loading full bytes into just_audio.
  Future<int?> _probeAudioDurationMs(PlatformFile file) async {
    final probe = AudioPlayer();
    try {
      if (kIsWeb) {
        if (file.bytes == null) return null;
        await probe
            .setAudioSource(_BytesAudioSource(file.bytes!))
            .timeout(const Duration(seconds: 10));
      } else {
        if (file.path == null) return null;
        await probe
            .setFilePath(file.path!)
            .timeout(const Duration(seconds: 10));
      }
      return probe.duration?.inMilliseconds;
    } catch (e, st) {
      AppLogger.debug(
        'Audio duration probe failed',
        name: 'MediaUploader',
        fields: {'error': e.toString(), 'stackTrace': st.toString()},
      );
      return null;
    } finally {
      await probe.dispose();
    }
  }

  /// Visible for testing to override video duration probing.
  Future<int?> Function(PlatformFile)? videoDurationProberOverride;

  /// Validates picked media files against size, mime, and duration rules.
  Future<Either<Failure, int?>> validateFile(
    PlatformFile file,
    ContentMediaKind kind,
  ) async {
    try {
      int? durationMs;
      if (kind == ContentMediaKind.video) {
        // 1. Size check
        if (file.size > 10485760) {
          throw const MediaValidationException(
            'File size exceeds the 10 MB limit',
          );
        }

        // 2. Mime / extension check
        final ext = file.name.split('.').last.toLowerCase();
        if (ext != 'mp4' && ext != 'webm' && ext != 'mov') {
          throw MediaValidationException(
            'Unsupported file format: .$ext. Only mp4, webm, and mov are allowed.',
          );
        }

        // 3. Duration check
        durationMs = await _probeVideoDurationMs(file);
        if (durationMs != null && durationMs > 300000) {
          throw const MediaValidationException(
            'Video duration exceeds the 5 minutes limit',
          );
        }
      }
      return right(durationMs);
    } on MediaValidationException catch (e) {
      return left(ValidationFailure(message: e.message));
    } catch (e) {
      return left(ValidationFailure(message: 'Validation failed: $e'));
    }
  }

  Future<int?> _probeVideoDurationMs(PlatformFile file) async {
    VideoPlayerController? controller;
    try {
      if (videoDurationProberOverride != null) {
        return await videoDurationProberOverride!(file);
      }

      if (kIsWeb) {
        if (file.bytes == null) return null;
        final url = createObjectUrl(file.bytes!);
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await controller.initialize().timeout(const Duration(seconds: 10));
        revokeObjectUrl(url);
      } else {
        if (file.path == null) return null;
        controller = VideoPlayerController.file(File(file.path!));
        await controller.initialize().timeout(const Duration(seconds: 10));
      }
      return controller.value.duration.inMilliseconds;
    } catch (e, st) {
      AppLogger.warning(
        'Video duration probe failed',
        name: 'MediaUploader',
        fields: {'error': e.toString(), 'stackTrace': st.toString()},
      );
      throw const MediaValidationException('Could not read video duration');
    } finally {
      if (controller != null) {
        await controller.dispose();
      }
    }
  }
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _buffer;
  _BytesAudioSource(this._buffer) : super(tag: '_BytesAudioSource');
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

class ReferenceCheck {
  final String databaseId;
  final String collectionId;
  final List<String> fieldNames; // e.g., ['audioFileId', 'coverFileId']

  const ReferenceCheck({
    required this.databaseId,
    required this.collectionId,
    required this.fieldNames,
  });
}

final mediaUploaderProvider = Provider<MediaUploader>(
  (ref) => MediaUploader(ref.watch(workerMediaApiProvider)),
);
