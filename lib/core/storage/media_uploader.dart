import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/shared/models/content_item.dart';

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

      final viewUrl = _constructViewUrl(bucketId, uploaded.$id);

      final media = ContentMedia(
        url: viewUrl,
        fileId: uploaded.$id,
        kind: kind,
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
}

final mediaUploaderProvider = Provider<MediaUploader>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return MediaUploader(authService.client);
});
