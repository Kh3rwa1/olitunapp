import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:itun/core/logging/app_logger.dart';
import '../config/appwrite_config.dart';
import '../storage/hive_service.dart';
import 'web_redirect.dart';

/// Evaluates whether a stored web session timestamp is valid (non-null, positive,
/// not older than maxDuration, and not implausibly in the future beyond 1 minute skew).
@visibleForTesting
bool isWebSessionValidTimestamp(
  int? ts, {
  Duration maxDuration = const Duration(hours: 24),
  DateTime? nowOverride,
}) {
  if (ts == null || ts <= 0) return false;
  final nowMs = (nowOverride ?? DateTime.now()).millisecondsSinceEpoch;
  // Allow up to 1 minute clock skew into the future, otherwise treat as invalid
  if (ts > nowMs + 60000) return false;
  final ageMs = nowMs - ts;
  if (ageMs > maxDuration.inMilliseconds) return false;
  return true;
}

enum AccountDeletionOutcomeKind {
  completed,
  authDeletedReconciliationPending,
  failed,
  malformed,
}

@visibleForTesting
class AccountDeletionResult {
  final AccountDeletionOutcomeKind kind;
  final bool isAuthDeleted;
  final bool isFullSuccess;
  final String? errorMessage;
  final int statusCode;

  const AccountDeletionResult({
    required this.kind,
    required this.isAuthDeleted,
    required this.isFullSuccess,
    this.errorMessage,
    required this.statusCode,
  });
}

@visibleForTesting
AccountDeletionResult parseAccountDeletionExecution({
  required String status,
  required int statusCode,
  required String responseBody,
}) {
  final trimmedBody = responseBody.trim();
  Map<String, dynamic>? responseData;
  bool isMalformed = false;
  if (trimmedBody.isNotEmpty) {
    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        responseData = decoded;
      } else {
        isMalformed = true;
      }
    } catch (_) {
      isMalformed = true;
    }
  } else {
    isMalformed = true;
  }

  final isAuthDeleted = responseData?['authDeleted'] == true;

  if (status.toLowerCase() == 'failed' ||
      statusCode < 200 ||
      statusCode >= 300 ||
      responseData == null ||
      responseData['ok'] != true ||
      isMalformed) {
    if (isAuthDeleted) {
      return AccountDeletionResult(
        kind: AccountDeletionOutcomeKind.authDeletedReconciliationPending,
        isAuthDeleted: true,
        isFullSuccess: false,
        errorMessage:
            'Account deleted; final cleanup reconciliation is pending.',
        statusCode: statusCode != 0 ? statusCode : 500,
      );
    }

    if (isMalformed) {
      return AccountDeletionResult(
        kind: AccountDeletionOutcomeKind.malformed,
        isAuthDeleted: false,
        isFullSuccess: false,
        errorMessage: 'Account deletion failed: malformed response from server',
        statusCode: statusCode != 0 ? statusCode : 500,
      );
    }

    final errCode =
        responseData?['code']?.toString() ??
        responseData?['message']?.toString() ??
        'Account deletion failed on server';

    return AccountDeletionResult(
      kind: AccountDeletionOutcomeKind.failed,
      isAuthDeleted: false,
      isFullSuccess: false,
      errorMessage: errCode,
      statusCode: statusCode != 0 ? statusCode : 500,
    );
  }

  return AccountDeletionResult(
    kind: AccountDeletionOutcomeKind.completed,
    isAuthDeleted: true,
    isFullSuccess: true,
    statusCode: statusCode != 0 ? statusCode : 200,
  );
}

@visibleForTesting
String googleOAuthUserMessage(String message) {
  final lowerMessage = message.toLowerCase();
  if (lowerMessage.contains('provider') &&
      (lowerMessage.contains('disabled') ||
          lowerMessage.contains('not enabled'))) {
    return 'Google sign-in is disabled in Appwrite. Enable the Google OAuth provider, then try again.';
  }

  return message;
}

enum WebOAuthCompletionKind { persistSession, createSession }

@visibleForTesting
class WebOAuthCompletion {
  final WebOAuthCompletionKind kind;
  final String secret;
  final String? userId;

  const WebOAuthCompletion._({
    required this.kind,
    required this.secret,
    this.userId,
  });

  const WebOAuthCompletion.persistSession(String secret)
    : this._(kind: WebOAuthCompletionKind.persistSession, secret: secret);

  const WebOAuthCompletion.createSession({
    required String userId,
    required String secret,
  }) : this._(
         kind: WebOAuthCompletionKind.createSession,
         userId: userId,
         secret: secret,
       );
}

@visibleForTesting
WebOAuthCompletion parseWebOAuthCompletion(String result) {
  final uri = Uri.parse(result);
  if (uri.queryParameters.containsKey('failure')) {
    final error = uri.queryParameters['error'] ?? '';
    final message = uri.queryParameters['message'] ?? '';
    throw AppwriteException(
      'Google sign in failed${error.isNotEmpty ? ' ($error)' : ''}: ${message.isNotEmpty ? message : 'Session was cancelled or failed.'}',
    );
  }

  final key = uri.queryParameters['key'];
  final secret = uri.queryParameters['secret'];
  final userId = uri.queryParameters['userId'];

  if (secret == null || secret.isEmpty) {
    throw AppwriteException('Invalid OAuth2 response. Missing session secret.');
  }

  if (key != null && key.startsWith('a_session_')) {
    return WebOAuthCompletion.persistSession(secret);
  }

  if (userId != null && userId.isNotEmpty) {
    return WebOAuthCompletion.createSession(userId: userId, secret: secret);
  }

  throw AppwriteException('Invalid OAuth2 response. Missing session key.');
}

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

@visibleForTesting
bool isTransientSessionValidationFailure(Object error) {
  if (error is TimeoutException) return true;
  if (error is AppwriteException) {
    return error.code == 0 ||
        error.type == 'network_failure' ||
        error.type == 'general_unknown';
  }

  final message = error.toString();
  return message.contains('SocketException') ||
      message.contains('TimeoutException');
}

class AppwriteAuthService {
  static const String _webSessionSecretKey = 'olitun_appwrite_session_secret';

  // Singleton pattern — one SDK Client shared across the app
  AppwriteAuthService._internal() {
    _client = Client();
    final endpoint = AppwriteConfig.endpoint;
    final projectId = AppwriteConfig.projectId;

    if (endpoint.isNotEmpty) {
      _client.setEndpoint(endpoint);
    } else {
      // Use a safe placeholder to avoid synchronous AppwriteException during testing or guest mode
      _client.setEndpoint('https://localhost/v1');
    }

    if (projectId.isNotEmpty) {
      _client.setProject(projectId);
    } else {
      _client.setProject('placeholder');
    }

    if (const bool.fromEnvironment('ALLOW_SELF_SIGNED')) {
      _client.setSelfSigned();
    }

    _account = Account(_client);
    _functions = Functions(_client);
  }

  static final AppwriteAuthService _instance = AppwriteAuthService._internal();
  factory AppwriteAuthService() => _instance;

  late final Client _client;
  late final Account _account;
  late final Functions _functions;

  SharedPreferences? _prefsOverride;
  DateTime Function()? _nowProvider;
  bool? _isWebOverride;

  @visibleForTesting
  AppwriteAuthService.forTesting({
    required Client client,
    required Account account,
    required Functions functions,
    SharedPreferences? prefs,
    DateTime Function()? nowProvider,
    bool? isWebOverride,
  }) : _client = client,
       _account = account,
       _functions = functions,
       _prefsOverride = prefs,
       _nowProvider = nowProvider,
       _isWebOverride = isWebOverride;

  Account get account => _account;
  Client get client => _client;

  /// Ping Appwrite backend to verify setup
  Future<void> ping() async {
    try {
      await _client.ping();
      AppLogger.debug('Appwrite: Ping successful ✅');
    } catch (e) {
      AppLogger.debug('Appwrite: Ping failed ❌ $e');
    }
  }

  /// Sign in anonymously (for guest/offline mode access to remote Appwrite collections)
  Future<models.Session> signInAnonymously() async {
    AppLogger.debug('Appwrite: Creating anonymous session');
    final session = await _account.createAnonymousSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasLocalSessionKey, true);
    return session;
  }

  // ─── Email OTP ───

  /// Send OTP code to email. Returns userId needed for session creation.
  Future<models.Token> sendOtpCode(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    AppLogger.debug('Appwrite: Sending OTP to $trimmedEmail');
    return await _account.createEmailToken(
      userId: ID.unique(),
      email: trimmedEmail,
    );
  }

  /// Verify OTP and create session
  Future<models.Session> verifyOtp({
    required String userId,
    required String secret,
  }) async {
    AppLogger.debug('Appwrite: Verifying OTP for user $userId');
    return await _account.createSession(userId: userId, secret: secret);
  }

  // ─── Google OAuth ───

  /// Sign in with Google OAuth2
  /// Uses the Appwrite SDK's built-in OAuth2 session flow on all platforms.
  /// On mobile: opens a browser, then deep-links back via appwrite-callback-{projectId}.
  /// On web: opens a popup, returns through /auth.html, then stores the session.
  Future<void> signInWithGoogle() async {
    AppLogger.debug('Appwrite: Starting Google OAuth');

    try {
      if (kIsWeb) {
        final origin = Uri.base.origin;
        final oauthUrl =
            '${AppwriteConfig.endpoint}/account/sessions/oauth2/google'
            '?project=${AppwriteConfig.projectId}'
            '&success=${Uri.encodeComponent("$origin/splash")}'
            '&failure=${Uri.encodeComponent("$origin/welcome")}'
            '&scopes[]=${Uri.encodeComponent("email")}'
            '&scopes[]=${Uri.encodeComponent("profile")}';
        redirectToUrl(oauthUrl);
      } else {
        final successLink =
            'appwrite-callback-${AppwriteConfig.projectId}://success';
        final failureLink =
            'appwrite-callback-${AppwriteConfig.projectId}://failure';
        await _account.createOAuth2Token(
          provider: OAuthProvider.google,
          success: successLink,
          failure: failureLink,
          scopes: ['email', 'profile'],
        );
      }
    } on AppwriteException catch (e) {
      AppLogger.debug(
        'Appwrite OAuth RAW ERROR: message="${e.message}" code=${e.code} type="${e.type}"',
      );
      throw AppwriteException(
        googleOAuthUserMessage(e.message ?? e.toString()),
        e.code,
        e.type,
      );
    }
  }

  /// Exchange OAuth token for session (called from splash screen after redirect)
  Future<bool> exchangeOAuthToken(String userId, String secret) async {
    try {
      if (userId.startsWith('a_session_')) {
        await _persistWebSession(secret);
      } else {
        await _account.createSession(userId: userId, secret: secret);
        if (kIsWeb) {
          await _persistWebSession(secret);
        }
      }
      AppLogger.debug('Appwrite: OAuth session created ✅');
      return true;
    } catch (e) {
      AppLogger.debug('Appwrite: Failed to create session from token: $e');
      return false;
    }
  }

  static const String _webSessionTimestampKey = 'olitun_web_session_ts';

  Future<SharedPreferences> _getPrefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  bool get _isWeb => _isWebOverride ?? kIsWeb;

  bool _isWebSessionValid(int? ts) =>
      isWebSessionValidTimestamp(ts, nowOverride: _nowProvider?.call());

  Future<void> _persistWebSession(String secret) async {
    _client.setSession(secret);
    final prefs = await _getPrefs();
    await prefs.setString(_webSessionSecretKey, secret);
    await prefs.setInt(
      _webSessionTimestampKey,
      (_nowProvider?.call() ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  Future<void> _restoreWebSession() async {
    if (!_isWeb) return;
    final prefs = await _getPrefs();
    final secret = prefs.getString(_webSessionSecretKey);
    final ts = prefs.getInt(_webSessionTimestampKey);

    if (secret != null && secret.isNotEmpty) {
      if (!_isWebSessionValid(ts)) {
        AppLogger.debug(
          'Appwrite: Web session timestamp missing/expired/invalid; failing closed and clearing',
        );
        await _clearWebSession();
        return;
      }
      _client.setSession(secret);
    }
  }

  void restoreWebSessionSync(SharedPreferences prefs) {
    if (!_isWeb) return;
    final secret = prefs.getString(_webSessionSecretKey);
    final ts = prefs.getInt(_webSessionTimestampKey);

    if (secret != null && secret.isNotEmpty) {
      if (!_isWebSessionValid(ts)) {
        AppLogger.debug(
          'Appwrite: Web session timestamp missing/expired/invalid in sync restore; failing closed and clearing',
        );
        unawaited(_clearWebSession());
        return;
      }
      _client.setSession(secret);
      AppLogger.debug('Appwrite: Web session restored synchronously ✅');
    }
  }

  Future<void> _clearWebSession() async {
    _client.setSession('');
    if (!_isWeb) return;
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_webSessionSecretKey);
      await prefs.remove(_webSessionTimestampKey);
    } catch (e) {
      AppLogger.debug('Appwrite: Failed to clear web session keys: $e');
    }
  }

  Future<void> _clearLocalSessionState() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_hasLocalSessionKey, false);
    await _clearWebSession();
  }

  static const String _hasLocalSessionKey = 'olitun_has_local_session';

  // ─── Session Management ───

  /// Check if user has an active session
  Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();

    if (_isWeb) {
      await _restoreWebSession();
    }

    final hasLocal = prefs.getBool(_hasLocalSessionKey) ?? false;
    if (!hasLocal) {
      return false;
    }

    try {
      final session = await _account
          .getSession(sessionId: 'current')
          .timeout(const Duration(seconds: 3));
      AppLogger.debug('Appwrite: Session active for user ${session.userId} ✅');
      await prefs.setBool(_hasLocalSessionKey, true);
      return true;
    } catch (e) {
      AppLogger.debug('Appwrite: isLoggedIn error: $e');

      // Only trust local state for clear network/timeout failures. Other
      // Appwrite errors must fail closed so strange backend states do not keep
      // an invalid session alive.
      final hasLocal = prefs.getBool(_hasLocalSessionKey) ?? false;
      if (hasLocal && isTransientSessionValidationFailure(e)) {
        AppLogger.debug(
          'Appwrite: transient session validation failure; using cached session.',
        );
        return true;
      }

      // If it's a 401 (Unauthorized), the session is definitely gone.
      if (e is AppwriteException && e.code == 401) {
        AppLogger.debug(
          'Appwrite: Session expired (401). Clearing local flag.',
        );
        await prefs.setBool(_hasLocalSessionKey, false);
      }

      return false;
    }
  }

  /// Get current user profile
  Future<models.User> getMe() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
    await _restoreWebSession();
    return await _account.get().timeout(const Duration(seconds: 3));
  }

  /// Update user display name
  Future<models.User> updateName(String name) async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
    return await _account
        .updateName(name: name)
        .timeout(const Duration(seconds: 3));
  }

  /// Update user preferences (for progress sync)
  Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
    await _account
        .updatePrefs(prefs: prefs)
        .timeout(const Duration(seconds: 3));
  }

  /// Get user preferences
  Future<models.Preferences> getPrefs() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
    return await _account.getPrefs().timeout(const Duration(seconds: 3));
  }

  /// Sign out — delete current session
  Future<void> signOut() async {
    try {
      await _restoreWebSession();
      await _account
          .deleteSession(sessionId: 'current')
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLogger.debug('Appwrite: Sign out error: $e');
    } finally {
      await _clearLocalSessionState();
    }
  }

  /// Permanently delete the user account from Appwrite and clear all local state.
  ///
  /// Calls the 'delete-account' Cloud Function to hard-delete the user record,
  /// making it possible to sign in again with the same email or OAuth provider without
  /// hitting a "user already exists" / session conflict.
  Future<void> deleteAccount() async {
    try {
      await _restoreWebSession();
      // Hard-delete the account using our Cloud Function
      final execution = await _functions.createExecution(
        functionId: 'delete-account',
      );

      final result = parseAccountDeletionExecution(
        status: execution.status.toString(),
        statusCode: execution.responseStatusCode,
        responseBody: execution.responseBody,
      );

      if (!result.isFullSuccess) {
        if (result.isAuthDeleted) {
          await _clearLocalSessionState();
          throw AppwriteException(
            result.errorMessage ??
                'Account deleted; final cleanup reconciliation is pending.',
            result.statusCode,
          );
        }

        throw AppwriteException(
          result.errorMessage ?? 'Account deletion failed on server',
          result.statusCode,
        );
      }

      // Server confirmed full deletion success; clear local session state
      await _clearLocalSessionState();
    } on AppwriteException catch (e) {
      AppLogger.error('Appwrite: deleteAccount error: $e');
      rethrow;
    } catch (e) {
      AppLogger.error('Appwrite: deleteAccount unexpected error: $e');
      throw AppwriteException('Account deletion failed: ${e.toString()}', 500);
    }
  }

  Future<Map<String, dynamic>> executeAdminMaintenance({
    required String action,
    required String confirmation,
  }) async {
    await _restoreWebSession();
    final execution = await _functions.createExecution(
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
    await _restoreWebSession();
    final execution = await _functions.createExecution(
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

final appwriteAuthServiceProvider = Provider<AppwriteAuthService>((ref) {
  final service = AppwriteAuthService();
  if (kIsWeb) {
    final prefs = ref.watch(sharedPreferencesProvider);
    service.restoreWebSessionSync(prefs);
  }
  return service;
});
