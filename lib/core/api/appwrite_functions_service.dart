import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/edge_auth.dart';
import '../config/cloudflare_config.dart';
import '../logging/app_logger.dart';

/// Neutral, backend-agnostic view of a serverless function execution.
///
/// Presentation layers consume this instead of the SDK's [Execution] model so
/// that backend details stay confined to the core/data layers.
class FunctionExecutionResult {
  const FunctionExecutionResult({
    required this.status,
    required this.statusCode,
    required this.responseBody,
  });

  final String status;
  final int statusCode;
  final String responseBody;

  /// Whether the execution completed (as opposed to failed/timeout).
  bool get isCompleted => status == 'completed';

  /// Parses [responseBody] as JSON, returning null on empty or malformed
  /// payloads.
  Map<String, dynamic>? get bodyJson {
    if (responseBody.isEmpty) return null;
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      AppLogger.warning(
        'FunctionExecutionResult: malformed response body: $e',
        name: 'AppwriteFunctionsService',
      );
    }
    return null;
  }
}

/// Serverless function calls, served by the Cloudflare Worker.
///
/// Each legacy function id maps to a Worker route. Appwrite is used only for
/// authentication: the request carries the session JWT and the Worker
/// derives the caller from it. There is no Appwrite Functions fallback.
class AppwriteFunctionsService {
  final http.Client _httpClient;
  final EdgeAuth? _edgeAuth;

  AppwriteFunctionsService({http.Client? httpClient, EdgeAuth? edgeAuth})
    : _httpClient = httpClient ?? http.Client(),
      _edgeAuth = edgeAuth;

  static String? _cloudflareEndpointFor(String functionId) {
    switch (functionId) {
      case 'recordMistake':
        return CloudflareConfig.mistakesRecordEndpoint;
      case 'markMistakeMastered':
        return CloudflareConfig.mistakesMasterEndpoint;
      case 'completeMistakeReview':
        return CloudflareConfig.mistakesReviewCompleteEndpoint;
      case 'getUserMistakes':
        return CloudflareConfig.mistakesEndpoint;
      case 'recordBakhedProgress':
        return CloudflareConfig.bakhedProgressEndpoint;
      case 'getUserGamificationSummary':
        return CloudflareConfig.gamificationSummaryEndpoint;
      case 'joinWaitlist':
        return CloudflareConfig.waitlistEndpoint;
      case 'getAuthorizedLesson':
        return CloudflareConfig.lessonsAuthorizeEndpoint;
      case 'createRazorpayOrder':
        return CloudflareConfig.paymentsOrderEndpoint;
      case 'verifyCoursePurchase':
        return CloudflareConfig.paymentsVerifyEndpoint;
      case 'santaliVoice':
        return CloudflareConfig.voiceSynthesizeEndpoint;
      case 'generateAudio':
        return CloudflareConfig.audioGenerateEndpoint;
      case 'delete-account':
      case 'deleteAccount':
        return CloudflareConfig.deleteAccountEndpoint;
      case 'admin-maintenance':
        return '${CloudflareConfig.baseUrl}/api/v1/admin/maintenance';
      case 'reviewContent':
        // GET: queue summary; POST {action, ...}: reviewContent actions.
        return '${CloudflareConfig.baseUrl}/api/v1/admin/review/queue';
      case 'manageAdminAccess':
        return '${CloudflareConfig.baseUrl}/api/v1/admin/access';
      case 'backupCollections':
        return '${CloudflareConfig.baseUrl}/api/v1/admin/backup';
      case 'reconcileOrphanedDeletions':
        return '${CloudflareConfig.baseUrl}/api/v1/admin/deletions/reconcile';
      case 'aggregateLearningAnalytics':
        return '${CloudflareConfig.baseUrl}/api/v1/analytics/aggregate';
      case 'cleanupAnalyticsEvents':
        return '${CloudflareConfig.baseUrl}/api/v1/analytics/cleanup';
      default:
        return null;
    }
  }

  /// Executes [functionId] on the Worker with an optional JSON [body].
  ///
  /// A 401 retries once with a fresh JWT (the cached one may have expired).
  /// Network failures surface as a `failed` result with status code 0.
  /// Long-running admin jobs (backup, restore) pass a longer [timeout].
  Future<FunctionExecutionResult> execute(
    String functionId, {
    Map<String, dynamic> body = const {},
    bool usePost = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final endpoint = _cloudflareEndpointFor(functionId);
    if (endpoint == null) {
      AppLogger.warning(
        'No Worker route for function $functionId',
        name: 'AppwriteFunctionsService',
      );
      return const FunctionExecutionResult(
        status: 'failed',
        statusCode: 501,
        responseBody: '{"ok":false,"error":"NOT_IMPLEMENTED"}',
      );
    }

    final isGet =
        !usePost &&
        body.isEmpty &&
        (functionId == 'reviewContent' || functionId == 'getUserMistakes');

    Future<http.Response> send() async {
      // The Worker identifies the caller only from this verified JWT.
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?await _edgeAuth?.headers(),
      };
      final uri = Uri.parse(endpoint);
      final request = isGet
          ? _httpClient.get(uri, headers: headers)
          : _httpClient.post(uri, headers: headers, body: jsonEncode(body));
      return request.timeout(timeout);
    }

    try {
      var res = await send();
      if (res.statusCode == 401 && _edgeAuth != null) {
        _edgeAuth.clear();
        res = await send();
      }
      return FunctionExecutionResult(
        status: res.statusCode >= 200 && res.statusCode < 300
            ? 'completed'
            : 'failed',
        statusCode: res.statusCode,
        responseBody: res.body,
      );
    } catch (e) {
      AppLogger.debug(
        'Worker function $functionId failed: $e',
        name: 'AppwriteFunctionsService',
      );
      return const FunctionExecutionResult(
        status: 'failed',
        statusCode: 0,
        responseBody: '{"ok":false,"error":"NETWORK_ERROR"}',
      );
    }
  }
}

// Provider
final appwriteFunctionsServiceProvider = Provider<AppwriteFunctionsService>(
  (ref) => AppwriteFunctionsService(edgeAuth: EdgeAuth.instance),
);
