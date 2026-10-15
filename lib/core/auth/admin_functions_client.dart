import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';

import '../api/appwrite_functions_service.dart';

@visibleForTesting
Map<String, dynamic> parseAdminMaintenanceResponse({
  required int statusCode,
  required String body,
}) {
  Map<String, dynamic> decoded = const {};
  if (body.trim().isNotEmpty) {
    Object? parsed;
    try {
      parsed = jsonDecode(body);
    } on FormatException {
      parsed = null;
    }
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

/// Error type for admin access actions the Worker cannot perform without an
/// Appwrite server key (HTTP 501). The message says what to do instead.
const String adminAccessUnavailableType = 'admin_access_unavailable';

/// Admin maintenance and admin access calls, served by the Cloudflare
/// Worker (`/api/v1/admin/maintenance`, `/api/v1/admin/access`) with the
/// session JWT. Errors surface as [AppwriteException] carrying the HTTP
/// status and the Worker's message, as the Appwrite Functions path did.
mixin AdminFunctionsMixin {
  AppwriteFunctionsService get edgeFunctions;
  Future<void> restoreWebSession();

  /// Backups, wipes and restores can run for a while on large content.
  static const Duration maintenanceTimeout = Duration(seconds: 90);

  Future<Map<String, dynamic>> executeAdminMaintenance({
    required String action,
    required String confirmation,
  }) async {
    await restoreWebSession();
    final execution = await edgeFunctions.execute(
      'admin-maintenance',
      body: {'action': action, 'confirmation': confirmation},
      usePost: true,
      timeout: maintenanceTimeout,
    );

    return parseAdminMaintenanceResponse(
      statusCode: execution.statusCode,
      body: execution.responseBody,
    );
  }

  Future<Map<String, dynamic>> executeAdminAccess(
    Map<String, dynamic> payload,
  ) async {
    await restoreWebSession();
    final execution = await edgeFunctions.execute(
      'manageAdminAccess',
      body: payload,
      usePost: true,
    );
    return parseAdminAccessResponse(
      statusCode: execution.statusCode,
      body: execution.responseBody,
    );
  }
}

@visibleForTesting
Map<String, dynamic> parseAdminAccessResponse({
  required int statusCode,
  required String body,
}) {
  Object? decoded;
  try {
    decoded = body.trim().isEmpty ? <String, dynamic>{} : jsonDecode(body);
  } on FormatException {
    decoded = null;
  }
  if (decoded is! Map<String, dynamic>) {
    throw AppwriteException(
      'Unexpected admin access response.',
      statusCode,
      'invalid_response',
    );
  }

  if (statusCode < 200 || statusCode >= 300 || decoded['ok'] != true) {
    final message = decoded['message']?.toString();
    throw AppwriteException(
      message == null || message.isEmpty
          ? 'Admin access request failed.'
          : message,
      statusCode,
      statusCode == 501 ? adminAccessUnavailableType : 'admin_access_failed',
    );
  }

  return decoded;
}
