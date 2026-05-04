import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

/// Configuration for the media upload endpoint.
///
/// `UPLOAD_BASE_URL` must be supplied at build time via:
///
///   --dart-define=UPLOAD_BASE_URL=https://media.example.com
///
/// There is no fallback. Calling [uploadEndpoint] without it throws so the
/// misconfiguration surfaces immediately rather than producing relative
/// URIs (`/api/upload.php`) that silently break uploads in production.
///
/// **Legacy notice (Task #4):** this is the *only* surviving dependency on
/// the retired PHP admin panel. The rest of `admin-panel/` has been
/// removed; `api/upload.php` is documented in `admin-panel/README.md` as
/// owned by the admin-tooling maintainers and is tracked for migration to
/// Appwrite Storage. Do not add new consumers — port new upload flows
/// straight to Appwrite Storage.
class AppConfig {
  static const String uploadBaseUrl = String.fromEnvironment('UPLOAD_BASE_URL');

  /// Temporary legacy PHP upload token.
  /// NOTE: This is not a perfect secret in Flutter Web/APK builds.
  /// Long-term 10/10 fix: migrate uploads fully to Appwrite Storage.
  static const String uploadApiToken = String.fromEnvironment(
    'UPLOAD_API_TOKEN',
  );

  static String get uploadEndpoint {
    if (uploadBaseUrl.isEmpty) {
      throw StateError(
        'UPLOAD_BASE_URL is not configured. Pass '
        '--dart-define=UPLOAD_BASE_URL=<https://your-host> at build time.',
      );
    }
    return '$uploadBaseUrl/api/upload.php';
  }
}

/// Upload service for Hostinger PHP API
class HostingerUploadService {
  static const int _maxUploadBytes = 50 * 1024 * 1024; // 50MB
  /// Maps file extension to proper MIME type
  static MediaType? _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const mimeMap = {
      'json': 'application/json',
      'webp': 'image/webp',
      'webm': 'video/webm',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'svg': 'image/svg+xml',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'aac': 'audio/aac',
      'm4a': 'audio/mp4',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
    };
    final mime = mimeMap[ext];
    if (mime != null) {
      final parts = mime.split('/');
      return MediaType(parts[0], parts[1]);
    }
    return null;
  }

  /// Uploads a file to Hostinger server
  /// [file] - The file to upload
  /// [folder] - Subfolder name (e.g., 'letters', 'lessons', 'video')
  /// Returns the public URL on success, null on failure
  Future<String?> uploadMedia(PlatformFile file, String folder) async {
    try {
      if (file.bytes == null && file.path == null) {
        throw Exception(
          'File data is missing. Ensure bytes or path is available.',
        );
      }
      if (file.size <= 0 || file.size > _maxUploadBytes) {
        throw Exception('File must be between 1 byte and 50MB.');
      }

      final uri = Uri.parse(AppConfig.uploadEndpoint);
      final request = http.MultipartRequest('POST', uri);

      if (AppConfig.uploadApiToken.isEmpty) {
        throw StateError(
          'UPLOAD_API_TOKEN is not configured. Pass '
          '--dart-define=UPLOAD_API_TOKEN=<token> at build time.',
        );
      }

      request.headers['Authorization'] = 'Bearer ${AppConfig.uploadApiToken}';

      // Determine content type from extension
      final contentType = _getMimeType(file.name);
      if (contentType == null) {
        throw Exception('Unsupported file type: ${file.name}');
      }
      debugPrint(
        'Upload: ${file.name} (${file.size} bytes) → $contentType → folder: $folder',
      );

      // Add file data with proper content type
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
            contentType: contentType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
            contentType: contentType,
          ),
        );
      }

      // Add folder parameter
      request.fields['folder'] = folder;

      // Increase timeout for larger files (e.g., videos)
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('Upload response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['url'];
        } else {
          final errorMessage = data['error'] ?? 'Unknown API error';
          throw Exception('Upload failed: $errorMessage');
        }
      } else {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('HostingerUploadService error: $e');
      rethrow;
    }
  }
}

/// Provider for upload service
final uploadServiceProvider = Provider((ref) => HostingerUploadService());
