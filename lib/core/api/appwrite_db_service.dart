import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/appwrite_auth_service.dart';

const String _databaseId = 'olitun_db';

class AppwriteDbService {
  final Databases _databases;
  final Storage storage;
  final Client _client;

  AppwriteDbService(this._client)
      : _databases = Databases(_client),
        storage = Storage(_client);

  // ─── Generic CRUD ───

  /// List documents with optional queries
  Future<List<Map<String, dynamic>>> listDocuments(
    String collectionId, {
    List<String>? queries,
  }) async {
    final result = await _databases.listDocuments(
      databaseId: _databaseId,
      collectionId: collectionId,
      queries: queries ?? [Query.limit(500)],
    );
    return result.documents.map((doc) {
      final data = Map<String, dynamic>.from(doc.data);
      data['id'] = doc.$id;
      return data;
    }).toList();
  }

  /// Get a single document by ID
  Future<Map<String, dynamic>> getDocument(
    String collectionId,
    String documentId,
  ) async {
    final doc = await _databases.getDocument(
      databaseId: _databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
    final data = Map<String, dynamic>.from(doc.data);
    data['id'] = doc.$id;
    return data;
  }

  /// Create a document
  Future<void> createDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    // Remove 'id' from data payload — Appwrite uses documentId separately
    final payload = Map<String, dynamic>.from(data)..remove('id');
    // Remove null values
    payload.removeWhere((key, value) => value == null);

    await _databases.createDocument(
      databaseId: _databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: payload,
    );
  }

  /// Update a document
  Future<void> updateDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data)..remove('id');
    payload.removeWhere((key, value) => value == null);

    await _databases.updateDocument(
      databaseId: _databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: payload,
    );
  }

  /// Delete a document
  Future<void> deleteDocument(
    String collectionId,
    String documentId,
  ) async {
    await _databases.deleteDocument(
      databaseId: _databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }

  // ─── Storage Helpers ───

  /// Get file view URL (publicly accessible)
  String getFileViewUrl(String bucketId, String fileId) {
    final endpoint = _client.endPoint;
    final projectId = '699495910038e39622c5';
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=$projectId';
  }

  /// Get file preview URL (for images with transformations)
  String getFilePreviewUrl(String bucketId, String fileId, {int? width, int? height}) {
    final endpoint = _client.endPoint;
    final projectId = '699495910038e39622c5';
    var url = '$endpoint/storage/buckets/$bucketId/files/$fileId/preview?project=$projectId';
    if (width != null) url += '&width=$width';
    if (height != null) url += '&height=$height';
    return url;
  }
}

// Provider
final appwriteDbServiceProvider = Provider<AppwriteDbService>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return AppwriteDbService(authService.client);
});

// Re-export appwriteAuthServiceProvider from providers.dart
final appwriteAuthServiceProvider = Provider<AppwriteAuthService>((ref) {
  return AppwriteAuthService();
});
