import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/shared/models/content_item.dart';

/// CANONICAL upload path for ALL audio/image/video media in the app.
///
/// - Uploads to Appwrite storage with read("any") permission.
/// - For audio MIME types, probes duration synchronously via just_audio
///   before returning. Result includes durationMs.
/// - Reports upload state via MediaPickerField's onUploadStateChanged
///   callback so editors can block Save during in-flight uploads.
/// - DO NOT create parallel upload utilities — extend this instead.
///
/// See docs/storage.md for rationale on why the audio bucket has
/// encryption: false (Range-request-to-disk-offset mapping requires
/// it for HTML5 audio seek/duration to work correctly).
class MediaUploader {
  final Client _client;
  final Storage _storage;

  MediaUploader(this._client) : _storage = Storage(_client);

  /// Picks a file and uploads it to Appwrite Storage, returning `Either<Failure, ContentMedia>`.
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
      final bucketId = _getBucketId(kind, file.name);
      final filename = _storageFilename(file.name, folder);

      InputFile inputFile;
      if (file.bytes != null) {
        inputFile = InputFile.fromBytes(bytes: file.bytes!, filename: filename);
      } else if (file.path != null) {
        inputFile = InputFile.fromPath(path: file.path!, filename: filename);
      } else {
        return left(
          const ValidationFailure(
            message:
                'File data is not available (both bytes and path are null)',
          ),
        );
      }

      final uploaded = await _storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: inputFile,
        permissions: [Permission.read(Role.any())],
      );

      int? durationMs;
      if (kind == ContentMediaKind.audio ||
          file.name.toLowerCase().endsWith('.mp3') ||
          file.name.toLowerCase().endsWith('.m4a') ||
          file.name.toLowerCase().endsWith('.wav') ||
          file.name.toLowerCase().endsWith('.ogg') ||
          file.name.toLowerCase().endsWith('.aac')) {
        durationMs = await _probeAudioDurationMs(file);
      }

      final viewUrl = _constructViewUrl(bucketId, uploaded.$id);

      final media = ContentMedia(
        url: viewUrl,
        fileId: uploaded.$id,
        kind: kind,
        durationMs: durationMs,
      );

      return right(media);
    } catch (e) {
      return left(ServerFailure(message: 'Storage upload failed: $e'));
    }
  }

  /// Deletes a file from Appwrite Storage.
  Future<Either<Failure, Unit>> delete(
    String fileId, [
    String? bucketId,
  ]) async {
    try {
      // If bucketId is not provided, try to delete from all common buckets
      if (bucketId != null) {
        await _storage.deleteFile(bucketId: bucketId, fileId: fileId);
      } else {
        final buckets = ['images', 'videos', 'audio', 'animations'];
        for (final bucket in buckets) {
          try {
            await _storage.deleteFile(bucketId: bucket, fileId: fileId);
            break;
          } catch (_) {
            // Continue trying other buckets
          }
        }
      }
      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: 'Storage deletion failed: $e'));
    }
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
    return null;
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
        return 'videos';
      case ContentMediaKind.audio:
        return 'audio';
      case ContentMediaKind.lottie:
        return 'animations';
    }
  }

  String _constructViewUrl(String bucketId, String fileId) {
    return '${_client.endPoint}/storage/buckets/$bucketId/files/$fileId/view'
        '?project=${AppwriteConfig.projectId}';
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

final mediaUploaderProvider = Provider<MediaUploader>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return MediaUploader(authService.client);
});
