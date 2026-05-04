import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/appwrite_auth_service.dart';
import '../config/appwrite_config.dart';

class AppwriteStorageUploadService {
  AppwriteStorageUploadService(this._client) : _storage = Storage(_client);

  final Client _client;
  final Storage _storage;

  static const Map<String, UploadTarget> _targetsByExtension = {
    'mp3': UploadTarget('audio', 'audio/mpeg', 50 * 1024 * 1024),
    'wav': UploadTarget('audio', 'audio/wav', 50 * 1024 * 1024),
    'ogg': UploadTarget('audio', 'audio/ogg', 50 * 1024 * 1024),
    'aac': UploadTarget('audio', 'audio/aac', 50 * 1024 * 1024),
    'm4a': UploadTarget('audio', 'audio/mp4', 50 * 1024 * 1024),
    'png': UploadTarget('images', 'image/png', 10 * 1024 * 1024),
    'jpg': UploadTarget('images', 'image/jpeg', 10 * 1024 * 1024),
    'jpeg': UploadTarget('images', 'image/jpeg', 10 * 1024 * 1024),
    'gif': UploadTarget('images', 'image/gif', 10 * 1024 * 1024),
    'webp': UploadTarget('images', 'image/webp', 10 * 1024 * 1024),
    'svg': UploadTarget('images', 'image/svg+xml', 10 * 1024 * 1024),
    'json': UploadTarget('animations', 'application/json', 5 * 1024 * 1024),
    'lottie': UploadTarget('animations', 'application/json', 5 * 1024 * 1024),
    'mp4': UploadTarget('videos', 'video/mp4', 100 * 1024 * 1024),
    'webm': UploadTarget('videos', 'video/webm', 100 * 1024 * 1024),
    'mov': UploadTarget('videos', 'video/quicktime', 100 * 1024 * 1024),
  };

  Future<String?> uploadMedia(PlatformFile file, String folder) async {
    try {
      if (file.bytes == null && file.path == null) {
        throw Exception(
          'File data is missing. Ensure bytes or path is available.',
        );
      }

      final target = targetForFilename(file.name);
      if (file.size <= 0 || file.size > target.maxBytes) {
        throw Exception(
          'File must be between 1 byte and ${target.maxBytes ~/ (1024 * 1024)}MB.',
        );
      }

      final filename = _storageFilename(file.name, folder);
      final inputFile = file.bytes != null
          ? InputFile.fromBytes(
              bytes: file.bytes!,
              filename: filename,
              contentType: target.contentType,
            )
          : InputFile.fromPath(
              path: file.path!,
              filename: filename,
              contentType: target.contentType,
            );

      debugPrint(
        'Appwrite upload: ${file.name} (${file.size} bytes) '
        '→ ${target.bucketId}/$filename',
      );

      final uploaded = await _storage.createFile(
        bucketId: target.bucketId,
        fileId: ID.unique(),
        file: inputFile,
        permissions: [Permission.read(Role.any())],
      );

      return fileViewUrl(target.bucketId, uploaded.$id);
    } catch (e) {
      debugPrint('AppwriteStorageUploadService error: $e');
      rethrow;
    }
  }

  @visibleForTesting
  static UploadTarget targetForFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    final target = _targetsByExtension[ext];
    if (target == null) {
      throw Exception('Unsupported file type: $filename');
    }
    return target;
  }

  @visibleForTesting
  static String sanitizeFolder(String folder) {
    final sanitized = folder
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return sanitized.isEmpty ? 'admin' : sanitized;
  }

  @visibleForTesting
  static String sanitizeFilename(String filename) {
    final basename = filename.split(RegExp(r'[/\\]+')).last;
    final sanitized = basename
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return sanitized.isEmpty ? 'upload' : sanitized;
  }

  @visibleForTesting
  static String storageFilename(String filename, String folder) =>
      _storageFilename(filename, folder);

  static String _storageFilename(String filename, String folder) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${sanitizeFolder(folder)}-$timestamp-${sanitizeFilename(filename)}';
  }

  String fileViewUrl(String bucketId, String fileId) {
    return '${_client.endPoint}/storage/buckets/$bucketId/files/$fileId/view'
        '?project=${AppwriteConfig.projectId}';
  }
}

class UploadTarget {
  const UploadTarget(this.bucketId, this.contentType, this.maxBytes);

  final String bucketId;
  final String contentType;
  final int maxBytes;
}

final uploadServiceProvider = Provider((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return AppwriteStorageUploadService(authService.client);
});
