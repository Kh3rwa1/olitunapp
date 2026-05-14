import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/appwrite_auth_service.dart';
import '../config/appwrite_config.dart';
import '../observability/crash_reporting.dart';
import 'upload_rules.dart';

class AppwriteStorageUploadService {
  AppwriteStorageUploadService(this._client) : _storage = Storage(_client);

  final Client _client;
  final Storage _storage;

  static const Map<String, UploadTarget> _targetsByExtension = {
    'mp3': UploadTarget('audio', 'audio/mpeg', UploadCategory.audio),
    'wav': UploadTarget('audio', 'audio/wav', UploadCategory.audio),
    'ogg': UploadTarget('audio', 'audio/ogg', UploadCategory.audio),
    'aac': UploadTarget('audio', 'audio/aac', UploadCategory.audio),
    'm4a': UploadTarget('audio', 'audio/mp4', UploadCategory.audio),
    'png': UploadTarget('images', 'image/png', UploadCategory.image),
    'jpg': UploadTarget('images', 'image/jpeg', UploadCategory.image),
    'jpeg': UploadTarget('images', 'image/jpeg', UploadCategory.image),
    'gif': UploadTarget('images', 'image/gif', UploadCategory.image),
    'webp': UploadTarget('images', 'image/webp', UploadCategory.image),
    'svg': UploadTarget('images', 'image/svg+xml', UploadCategory.image),
    'json': UploadTarget(
      'animations',
      'application/json',
      UploadCategory.animation,
    ),
    'lottie': UploadTarget(
      'animations',
      'application/json',
      UploadCategory.animation,
    ),
    'mp4': UploadTarget('videos', 'video/mp4', UploadCategory.video),
    'webm': UploadTarget('videos', 'video/webm', UploadCategory.video),
    'mov': UploadTarget('videos', 'video/quicktime', UploadCategory.video),
  };

  Future<String?> uploadMedia(PlatformFile file, String folder) async {
    try {
      if (file.bytes == null && file.path == null) {
        throw Exception(
          'File data is missing. Ensure bytes or path is available.',
        );
      }

      final target = targetForFilename(file.name);

      final validationError = UploadRules.validate(
        filename: file.name,
        sizeBytes: file.size,
        category: target.category,
      );

      if (validationError != null) {
        throw Exception(validationError);
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

      CrashReporting.addUploadBreadcrumb(
        filename: file.name,
        bucket: target.bucketId,
        sizeBytes: file.size,
      );

      return fileViewUrl(target.bucketId, uploaded.$id);
    } catch (e) {
      CrashReporting.addUploadBreadcrumb(
        filename: file.name,
        bucket: 'unknown',
        success: false,
        error: e.toString(),
        sizeBytes: file.size,
      );
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
    return UploadRules.sanitizeFilename(filename);
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
  const UploadTarget(this.bucketId, this.contentType, this.category);

  final String bucketId;
  final String contentType;
  final UploadCategory category;
}

final uploadServiceProvider = Provider((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return AppwriteStorageUploadService(authService.client);
});
