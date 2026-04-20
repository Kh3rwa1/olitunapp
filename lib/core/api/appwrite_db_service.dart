import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/appwrite_config.dart';
import '../../shared/providers/auth_providers.dart';

class AppwriteDbService {
  final TablesDB _tablesDB;
  final Storage storage;
  final Client _client;

  AppwriteDbService(this._client)
      : _tablesDB = TablesDB(_client),
        storage = Storage(_client);

  // ─── Generic CRUD ───

  /// List rows with optional queries
  Future<List<Map<String, dynamic>>> listDocuments(
    String collectionId, {
    List<String>? queries,
  }) async {
    final result = await _tablesDB.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      queries: queries ?? [Query.limit(500)],
    );
    return result.rows.map((row) {
      final data = Map<String, dynamic>.from(row.data);
      data['id'] = row.$id;
      return data;
    }).toList();
  }

  /// Get a single document by ID
  Future<Map<String, dynamic>> getDocument(
    String collectionId,
    String documentId,
  ) async {
    final row = await _tablesDB.getRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: documentId,
    );
    final data = Map<String, dynamic>.from(row.data);
    data['id'] = row.$id;
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

    await _tablesDB.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: documentId,
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

    await _tablesDB.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: documentId,
      data: payload,
    );
  }

  /// Delete a document
  Future<void> deleteDocument(
    String collectionId,
    String documentId,
  ) async {
    await _tablesDB.deleteRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: documentId,
    );
  }

  // ─── Storage Helpers ───

  /// Get file view URL (publicly accessible)
  String getFileViewUrl(String bucketId, String fileId) {
    final endpoint = _client.endPoint;
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }

  /// Get file preview URL (for images with transformations)
  String getFilePreviewUrl(String bucketId, String fileId, {int? width, int? height}) {
    final endpoint = _client.endPoint;
    var url = '$endpoint/storage/buckets/$bucketId/files/$fileId/preview?project=${AppwriteConfig.projectId}';
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

