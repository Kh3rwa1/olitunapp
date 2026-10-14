import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/account_scope.dart';
import '../auth/appwrite_auth_service.dart';
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

  AppwriteFunctionsService(
    Client client, {
    http.Client? httpClient,
    Functions? functions,
  }) : _functions = functions ?? Functions(client),
       _httpClient = httpClient ?? http.Client();

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
      case 'mutateReviewState':
        return '${CloudflareConfig.baseUrl}/api/v1/admin/review/state';
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

  Future<String?> _resolveUserId(Map<String, dynamic> body) async {
    final bodyUser = body['userId'];
    if (bodyUser is String && bodyUser.trim().isNotEmpty) {
      return bodyUser.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = AccountScope.capture(prefs).userId;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return null;
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
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        final userId = await _resolveUserId(body);
        if (userId != null && userId.isNotEmpty) {
          headers['x-appwrite-user-id'] = userId;
        }

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
          final payload = Map<String, dynamic>.from(body);
          if (userId != null &&
              userId.isNotEmpty &&
              !payload.containsKey('userId')) {
            payload['userId'] = userId;
          }
          res = await _httpClient
              .post(uri, headers: headers, body: jsonEncode(payload))
              .timeout(const Duration(seconds: 15));
        }

        if (res.statusCode >= 200 && res.statusCode < 500) {
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
  return AppwriteFunctionsService(authService.client);
});
