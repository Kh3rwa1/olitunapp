import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/appwrite_auth_service.dart';
import '../logging/app_logger.dart';

/// Neutral, Appwrite-free view of a serverless function execution.
///
/// Presentation layers consume this instead of the SDK's [Execution] model so
/// that `package:appwrite` stays confined to the core/data layers.
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

/// Thin anti-corruption facade over the Appwrite Functions API.
///
/// All function-execution RPCs from presentation/domain layers must go
/// through this service rather than constructing `Functions(client)`
/// directly, keeping the SDK behind a single core-layer seam.
class AppwriteFunctionsService {
  final Functions _functions;

  AppwriteFunctionsService(Client client) : _functions = Functions(client);

  /// Executes [functionId] with an optional JSON [body].
  ///
  /// Pass [usePost] as true for functions that require POST semantics
  /// (structured error payloads instead of HTTP-level failures).
  Future<FunctionExecutionResult> execute(
    String functionId, {
    Map<String, dynamic> body = const {},
    bool usePost = false,
  }) async {
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
final appwriteFunctionsServiceProvider = Provider<AppwriteFunctionsService>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return AppwriteFunctionsService(authService.client);
});
