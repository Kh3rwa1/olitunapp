import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'appwrite_auth_service.dart';

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

extension AdminFunctionsAppwriteAuth on AppwriteAuthService {
  Future<Map<String, dynamic>> executeAdminMaintenance({
    required String action,
    required String confirmation,
  }) async {
    await restoreWebSession();
    final execution = await functions.createExecution(
      functionId: 'admin-maintenance',
      body: jsonEncode({'action': action, 'confirmation': confirmation}),
      xasync: false,
      method: ExecutionMethod.pOST,
    );

    return parseAdminMaintenanceResponse(
      statusCode: execution.responseStatusCode,
      body: execution.responseBody,
    );
  }

  Future<Map<String, dynamic>> executeAdminAccess(
    Map<String, dynamic> payload,
  ) async {
    await restoreWebSession();
    final execution = await functions.createExecution(
      functionId: 'manageAdminAccess',
      body: jsonEncode(payload),
      xasync: false,
      method: ExecutionMethod.pOST,
    );

    final decoded = execution.responseBody.trim().isEmpty
        ? <String, dynamic>{}
        : jsonDecode(execution.responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw AppwriteException(
        'Unexpected admin access response.',
        execution.responseStatusCode,
        'invalid_response',
      );
    }

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300 ||
        decoded['ok'] != true) {
      final message = decoded['message']?.toString();
      throw AppwriteException(
        message == null || message.isEmpty
            ? 'Admin access request failed.'
            : message,
        execution.responseStatusCode,
        'admin_access_failed',
      );
    }

    return decoded;
  }
}
