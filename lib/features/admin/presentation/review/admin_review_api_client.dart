/// Phase 5 — API client for the `reviewContent` Appwrite Function.
///
/// Follows the repo's `executeAdminMaintenance` convention: execute
/// with POST semantics, then parse responseStatusCode + responseBody.
/// Kept UI-free and Appwrite-free so tests can drive it with a fake
/// executor.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/appwrite_functions_service.dart';
import 'admin_review_models.dart';

/// Neutral, Appwrite-free view of a function execution.
class AdminReviewExecution {
  const AdminReviewExecution({required this.statusCode, required this.responseBody});

  final int statusCode;
  final String responseBody;
}

/// Executes a reviewContent request and returns the decoded
/// `data` object. Implemented against the core
/// [AppwriteFunctionsService]; fakes in tests return canned responses.
abstract class AdminReviewExecutor {
  Future<AdminReviewExecution> createExecution(
    String functionId, {
    required String body,
  });
}

class _FunctionsExecutor implements AdminReviewExecutor {
  _FunctionsExecutor(this._functions);

  final AppwriteFunctionsService _functions;

  @override
  Future<AdminReviewExecution> createExecution(
    String functionId, {
    required String body,
  }) async {
    final payload = jsonDecode(body) as Map<String, dynamic>;
    final result = await _functions.execute(
      functionId,
      body: payload,
      usePost: true,
    );
    return AdminReviewExecution(
      statusCode: result.statusCode,
      responseBody: result.responseBody,
    );
  }
}

/// Thrown when the reviewContent function returns a structured
/// error (`success == false`) or a non-2xx status.
class AdminReviewException implements Exception {
  final String message;
  final int statusCode;
  final String? code;

  const AdminReviewException(this.message, {this.statusCode = 0, this.code});

  @override
  String toString() => message;
}

class AdminReviewApiClient {
  static const String functionId = 'reviewContent';

  /// Backend caps batches at 50 ids; mirror it client-side so the
  /// UI never sends an over-limit payload.
  static const int maxBatchIds = 50;

  AdminReviewApiClient({required AdminReviewExecutor executor})
    : _executor = executor;

  final AdminReviewExecutor _executor;

  Future<Map<String, dynamic>> _execute(Map<String, dynamic> payload) async {
    final execution = await _executor.createExecution(
      functionId,
      body: jsonEncode(payload),
    );

    final statusCode = execution.statusCode;
    final rawBody = execution.responseBody.trim();
    Map<String, dynamic>? decoded;
    if (rawBody.isNotEmpty) {
      final parsed = jsonDecode(rawBody);
      if (parsed is Map<String, dynamic>) decoded = parsed;
    }

    if (statusCode < 200 || statusCode >= 300) {
      throw AdminReviewException(
        decoded?['message']?.toString() ??
            'Review request failed (HTTP $statusCode).',
        statusCode: statusCode,
        code: decoded?['error']?.toString(),
      );
    }

    if (decoded == null) {
      throw AdminReviewException(
        'Review service returned an empty response.',
        statusCode: statusCode,
      );
    }

    if (decoded['success'] != true) {
      throw AdminReviewException(
        decoded['message']?.toString() ?? 'Review request failed.',
        statusCode: statusCode,
        code: decoded['error']?.toString(),
      );
    }

    final data = decoded['data'];
    if (data is! Map) {
      throw AdminReviewException(
        'Review service returned malformed data.',
        statusCode: statusCode,
      );
    }
    return Map<String, dynamic>.from(data);
  }

  /// Lists audio_tracks rows for the given filters.
  Future<AdminAudioQueuePage> listAudioTracks({
    String reviewStatus = 'needsReview',
    String? languageCode,
    String? contentKind,
    String? generationStatus,
    int limit = 25,
    int offset = 0,
  }) async {
    final data = await _execute({
      'action': 'list_audio',
      'reviewStatus': reviewStatus,
      'languageCode': ?languageCode,
      'contentKind': ?contentKind,
      'generationStatus': ?generationStatus,
      'limit': limit,
      'offset': offset,
    });
    return AdminAudioQueuePage.fromData(data);
  }

  /// Lists localized_contents rows for the given filters.
  Future<AdminLocalizedQueuePage> listLocalizedContents({
    String reviewStatus = 'needsReview',
    String? languageCode,
    String? contentKind,
    int limit = 25,
    int offset = 0,
  }) async {
    final data = await _execute({
      'action': 'list_localized',
      'reviewStatus': reviewStatus,
      'languageCode': ?languageCode,
      'contentKind': ?contentKind,
      'limit': limit,
      'offset': offset,
    });
    return AdminLocalizedQueuePage.fromData(data);
  }

  Future<AdminReviewBatchResult> _applyDecision(
    String action,
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      throw const AdminReviewException('No items selected.');
    }
    if (ids.length > maxBatchIds) {
      throw const AdminReviewException(
        'Cannot review more than $maxBatchIds items at once.',
      );
    }
    final data = await _execute({'action': action, 'ids': ids});
    return AdminReviewBatchResult.fromData(data);
  }

  Future<AdminReviewBatchResult> approveAudio(List<String> ids) =>
      _applyDecision('approve_audio', ids);

  Future<AdminReviewBatchResult> rejectAudio(List<String> ids) =>
      _applyDecision('reject_audio', ids);

  Future<AdminReviewBatchResult> approveLocalized(List<String> ids) =>
      _applyDecision('approve_localized', ids);

  Future<AdminReviewBatchResult> rejectLocalized(List<String> ids) =>
      _applyDecision('reject_localized', ids);
}

/// Riverpod provider wired to the signed-in admin session's
/// appwrite client via the core functions service.
final adminReviewApiClientProvider = Provider<AdminReviewApiClient>((ref) {
  final functions = ref.watch(appwriteFunctionsServiceProvider);
  return AdminReviewApiClient(executor: _FunctionsExecutor(functions));
});
