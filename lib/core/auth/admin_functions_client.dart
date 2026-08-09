import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';

@visibleForTesting
Map<String, dynamic> parseAdminMaintenanceResponse({
  required int statusCode,
  required String body,
}) {
  Map<String, dynamic> decoded = const {};
  if (body.trim().isNotEmpty) {
    final parsed = jsonDecode(body);
    if (parsed is! Map<String, dynamic>) {
      throw AppwriteException(
        'Unexpected admin maintenance response.',
        statusCode,
        'invalid_response',
      );
    }
    decoded = parsed;
  }

  if (statusCode < 200 || statusCode >= 300 || decoded['success'] != true) {
    final message = decoded['message']?.toString();
    throw AppwriteException(
      message == null || message.isEmpty
          ? 'Admin maintenance request failed.'
          : message,
      statusCode,
      'admin_maintenance_failed',
    );
  }

  return decoded;
}

String? adminMaintenanceBackupFileId(Map<String, dynamic> response) {
  final backup = response['backup'];
  if (backup is! Map<String, dynamic>) return null;
  final fileId = backup['fileId'];
  if (fileId is! String || fileId.isEmpty) return null;
  return fileId;
}
