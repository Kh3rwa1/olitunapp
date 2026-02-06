import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Configuration for Hostinger API
class AppConfig {
  // TODO: Update this to your Hostinger domain
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080', // For local testing
  );

  static String get uploadEndpoint => '$apiBaseUrl/api/upload.php';
}

/// Upload service for Hostinger PHP API
class HostingerUploadService {
  /// Uploads a file to Hostinger server
  /// [file] - The file to upload
  /// [folder] - Subfolder name (e.g., 'letters', 'lessons')
  /// Returns the public URL on success, null on failure
  Future<String?> uploadMedia(PlatformFile file, String folder) async {
    try {
      print('HostingerUpload: Uploading ${file.name} to folder: $folder');
      print(
        'HostingerUpload: File size: ${file.size}, Has bytes: ${file.bytes != null}',
      );

      if (file.bytes == null) {
        print(
          'HostingerUpload: ERROR - No bytes available (use withData: true in FilePicker)',
        );
        return null;
      }

      // Create multipart request
      final uri = Uri.parse(AppConfig.uploadEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );

      // Add folder parameter
      request.fields['folder'] = folder;

      print('HostingerUpload: Sending to ${AppConfig.uploadEndpoint}');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('HostingerUpload: Response status: ${response.statusCode}');
      print('HostingerUpload: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('HostingerUpload: Success! URL: ${data['url']}');
          return data['url'];
        } else {
          print('HostingerUpload: API error: ${data['error']}');
          return null;
        }
      } else {
        print('HostingerUpload: HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('HostingerUpload: Exception: $e');
      print('HostingerUpload: Stack trace: $stackTrace');
      return null;
    }
  }
}

/// Provider for upload service
final uploadServiceProvider = Provider((ref) => HostingerUploadService());

/// Legacy alias for compatibility (was supabaseServiceProvider)
final supabaseServiceProvider = uploadServiceProvider;
