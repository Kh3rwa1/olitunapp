import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/appwrite_auth_service.dart';
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

/// Unified serverless functions service.
///
/// Dispatches requests to Cloudflare Workers edge API for high performance
/// and 0ms cold starts, with transparent fallback to Appwrite Functions.
class AppwriteFunctionsService {
  final Functions _functions;
  final http.Client _httpClient;
  final EdgeAuth? _edgeAuth;

  AppwriteFunctionsService(
    Client client, {
    http.Client? httpClient,
    Functions? functions,
    EdgeAuth? edgeAuth,
  }) : _functions = functions ?? Functions(client),
       _httpClient = httpClient ?? http.Client(),
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
        return '${CloudflareConfig.baseUrl}/api/v1/admin/review/queue';
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

  /// Executes [functionId] with an optional JSON [body].
  ///
  /// Prefers Cloudflare Worker endpoints for sub-millisecond edge execution,
  /// with automatic fallback to Appwrite Functions.
  Future<FunctionExecutionResult> execute(
    String functionId, {
    Map<String, dynamic> body = const {},
    bool usePost = false,
  }) async {
    // 1. Try Cloudflare Worker endpoint first (Edge execution, zero Appwrite function cost)
    final cfEndpoint = _cloudflareEndpointFor(functionId);
    if (cfEndpoint != null) {
      try {
        final uri = Uri.parse(cfEndpoint);
        // The Worker identifies the caller only from this verified JWT.
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?await _edgeAuth?.headers(),
        };

        final isGet =
            !usePost &&
            body.isEmpty &&
            (functionId == 'reviewContent' || functionId == 'getUserMistakes');

        final http.Response res;
        if (isGet) {
          res = await _httpClient
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
        } else {
          res = await _httpClient
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
        }

        // 401 means the edge could not verify this session (e.g. a stale
        // JWT): drop the token and let Appwrite authenticate the session.
        if (res.statusCode == 401) _edgeAuth?.clear();
        if (res.statusCode >= 200 &&
            res.statusCode < 500 &&
            res.statusCode != 401) {
          return FunctionExecutionResult(
            status: res.statusCode < 300 ? 'completed' : 'failed',
            statusCode: res.statusCode,
            responseBody: res.body,
          );
        }
      } catch (e) {
        AppLogger.debug(
          'Cloudflare function $functionId failed: $e, falling back to Appwrite',
          name: 'AppwriteFunctionsService',
        );
      }
    }

    // 2. Fallback to Appwrite Functions
    final response = await _functions.createExecution(
      functionId: functionId,
      body: body.isEmpty ? '{}' : jsonEncode(body),
      xasync: false,
      method: usePost ? ExecutionMethod.pOST : ExecutionMethod.gET,
    );
    return FunctionExecutionResult(
      status: response.status.name,
      statusCode: response.responseStatusCode,
      responseBody: response.responseBody,
    );
  }
}

// Provider
final appwriteFunctionsServiceProvider = Provider<AppwriteFunctionsService>((
  ref,
) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return AppwriteFunctionsService(
    authService.client,
    edgeAuth: EdgeAuth.instance,
  );
});
