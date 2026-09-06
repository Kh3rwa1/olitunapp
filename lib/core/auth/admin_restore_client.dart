import 'dart:convert';
import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> parseAdminRestoreResponse({
  required int statusCode,
  required String body,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    throw AppwriteException('Invalid restore response. Retry to resume.', 502);
  }
  if (decoded is! Map<String, dynamic>) {
    throw AppwriteException('Invalid restore response. Retry to resume.', 502);
  }
  if ((statusCode != 200 && statusCode != 202) || decoded['success'] != true) {
    throw AppwriteException(
      decoded['message']?.toString() ?? 'Restore interrupted. Retry to resume.',
      statusCode,
    );
  }
  if (decoded['complete'] is! bool) {
    throw AppwriteException('Restore completion is unconfirmed.', 502);
  }
  return decoded;
}

String _newRestoreId() {
  final random = Random.secure();
  return List<int>.generate(
    16,
    (_) => random.nextInt(256),
  ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}

/// A durable operation identity survives app restarts and ambiguous responses.
/// Only an acknowledged complete response clears it. The server owns progress.
class AdminRestoreClient {
  AdminRestoreClient({
    required this.prefs,
    required this.projectId,
    required this.execute,
    String Function()? newId,
  }) : _newId = newId ?? _newRestoreId;

  final SharedPreferences prefs;
  final String projectId;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) execute;
  final String Function() _newId;
  static final _inFlight = <String, Future<Map<String, dynamic>>>{};

  String pendingKey(String fileId) =>
      'admin_restore_pending:$projectId:$fileId';

  Future<Map<String, dynamic>> restore({
    required String fileId,
    String? operationId,
    void Function(Map<String, dynamic>)? onProgress,
    bool Function()? shouldContinue,
    int maxChunks = 80,
    bool dryRun = false,
  }) {
    final key = pendingKey(fileId);
    final active = _inFlight[key];
    if (active != null) return active;
    final work =
        _run(
          fileId: fileId,
          operationId: operationId,
          onProgress: onProgress,
          shouldContinue: shouldContinue,
          maxChunks: maxChunks,
          dryRun: dryRun,
        ).whenComplete(() {
          _inFlight.remove(key);
        });
    _inFlight[key] = work;
    return work;
  }

  Future<Map<String, dynamic>> rollback({
    required String restoreId,
    void Function(Map<String, dynamic>)? onProgress,
    int maxChunks = 80,
  }) async {
    final validId = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,35}$');
    if (!validId.hasMatch(restoreId)) {
      throw AppwriteException('Enter a valid restore operation ID.', 400);
    }
    for (var step = 0; step < maxChunks; step++) {
      final response = await execute({
        'action': 'rollback_restore',
        'restoreId': restoreId,
      });
      if (response['complete'] is! bool || response['success'] != true) {
        throw AppwriteException(
          'Rollback response does not match this operation.',
          502,
        );
      }
      onProgress?.call(response);
      if (response['complete'] == true) {
        return response;
      }
    }
    throw AppwriteException('Rollback paused; retry to resume.', 202);
  }

  Future<Map<String, dynamic>> _run({
    required String fileId,
    required String? operationId,
    required void Function(Map<String, dynamic>)? onProgress,
    required bool Function()? shouldContinue,
    required int maxChunks,
    required bool dryRun,
  }) async {
    final validId = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,35}$');
    if (!validId.hasMatch(fileId)) {
      throw AppwriteException('Enter a valid backup file ID.', 400);
    }
    final key = pendingKey(fileId);
    final requestedId = operationId?.trim();
    final restoreId = requestedId != null && requestedId.isNotEmpty
        ? requestedId
        : prefs.getString(key) ?? _newId();
    if (!validId.hasMatch(restoreId)) {
      throw AppwriteException('Enter a valid restore operation ID.', 400);
    }
    if (!dryRun && !await prefs.setString(key, restoreId)) {
      throw AppwriteException('Could not save the restore recovery ID.', 503);
    }
    for (var step = 0; step < maxChunks; step++) {
      if (shouldContinue != null && !shouldContinue()) break;
      final response = await execute({
        'action': 'restore_content',
        'fileId': fileId,
        'restoreId': restoreId,
        'confirmation': 'RESTORE CONTENT',
        if (dryRun) 'dryRun': true,
      });
      if (response['jobId'] != restoreId ||
          response['fileId'] != fileId ||
          response['complete'] is! bool ||
          response['success'] != true) {
        throw AppwriteException(
          'Restore response does not match this operation.',
          502,
        );
      }
      onProgress?.call(response);
      if (response['complete'] == true) {
        if (!dryRun && !await prefs.remove(key)) {
          throw AppwriteException(
            'Restore completed, but its local recovery ID could not be cleared. Retry safely.',
            503,
          );
        }
        return response;
      }
    }
    throw AppwriteException(
      'Restore paused. Reopen Restore / Resume with backup $fileId. '
      'Recovery operation: $restoreId. Do not start a different restore.',
      202,
    );
  }
}
