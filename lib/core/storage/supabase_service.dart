import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Configuration for Hostinger API
class AppConfig {
  static const String uploadBaseUrl = String.fromEnvironment(
    'UPLOAD_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static String get uploadEndpoint => '$uploadBaseUrl/api/upload.php';
}

/// Upload service for Hostinger PHP API
class HostingerUploadService {
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

      final uri = Uri.parse(AppConfig.uploadEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add file data
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['url'];
        } else {
          final errorMessage = data['error'] ?? 'Unknown API error';
          throw Exception('Upload Failed: $errorMessage');
        }
      } else {
        throw Exception(
          'Server Error (${response.statusCode}): ${response.reasonPhrase}\nBody: ${response.body}',
        );
      }
    } catch (e) {
      // Log error for debugging
      print('HostingerUploadService error: $e');
      rethrow;
    }
  }
}

/// Provider for upload service
final uploadServiceProvider = Provider((ref) => HostingerUploadService());

/// Legacy alias for compatibility (was supabaseServiceProvider)
final supabaseServiceProvider = uploadServiceProvider;
