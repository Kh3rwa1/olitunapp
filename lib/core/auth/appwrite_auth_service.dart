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
import 'package:itun/core/logging/redaction_helper.dart';
import '../config/appwrite_config.dart';
import '../storage/hive_service.dart';
import 'web_redirect.dart';

export 'account_deletion_handler.dart';
export 'oauth_helpers.dart';
export 'admin_functions_client.dart';
export 'session_validator.dart';

import 'account_deletion_handler.dart';
import 'oauth_helpers.dart';
import 'admin_functions_client.dart';
import 'session_validator.dart';

class AppwriteAuthService {
  static const String _webSessionSecretKey = 'olitun_appwrite_session_secret';
  static const String _webSessionTimestampKey = 'olitun_web_session_ts';
  static const String _hasLocalSessionKey = 'olitun_has_local_session';

  // Singleton pattern — one SDK Client shared across the app
  AppwriteAuthService._internal() {
    _client = Client();
    final endpoint = AppwriteConfig.endpoint;
    final projectId = AppwriteConfig.projectId;

    if (endpoint.isNotEmpty) {
      _client.setEndpoint(endpoint);
    } else {
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

  Future<SharedPreferences> _getPrefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  bool get _isWeb => _isWebOverride ?? kIsWeb;

  bool _isWebSessionValid(int? ts) =>
      // ignore: invalid_use_of_visible_for_testing_member
      isWebSessionValidTimestamp(ts, nowOverride: _nowProvider?.call());

  /// Ping Appwrite backend to verify setup
  Future<void> ping() async {
    try {
      await _client.ping();
      AppLogger.debug('Appwrite: Ping successful ✅');
    } catch (e) {
      AppLogger.debug('Appwrite: Ping failed ❌ ${RedactionHelper.sanitize(e.toString())}');
    }
  }

  /// Sign in anonymously (for guest/offline mode access to remote Appwrite collections)
  Future<models.Session> signInAnonymously() async {
    AppLogger.debug('Appwrite: Creating anonymous session');
    final session = await _account.createAnonymousSession();
    final prefs = await _getPrefs();
    await prefs.setBool(_hasLocalSessionKey, true);
    return session;
  }

  // ─── Email OTP ───

  /// Send OTP code to email. Returns userId needed for session creation.
  Future<models.Token> sendOtpCode(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    AppLogger.debug('Appwrite: Sending OTP code');
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
    AppLogger.debug('Appwrite: Verifying OTP token');
    return await _account.createSession(userId: userId, secret: secret);
  }

  // ─── Google OAuth ───

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
        'Appwrite OAuth error: ${RedactionHelper.sanitize(e.message ?? e.toString())}',
      );
      throw AppwriteException(
        // ignore: invalid_use_of_visible_for_testing_member
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
      AppLogger.debug('Appwrite: Failed to create session from token');
      return false;
    }
  }

  Future<void> _persistWebSession(String secret) async {
    if (secret.isEmpty) {
      await _clearLocalSessionState();
      throw AppwriteException('Cannot persist empty session secret.');
    }
    _client.setSession(secret);
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_webSessionSecretKey, secret);
      await prefs.setInt(
        _webSessionTimestampKey,
        (_nowProvider?.call() ?? DateTime.now()).millisecondsSinceEpoch,
      );
      await prefs.setBool(_hasLocalSessionKey, true);
    } catch (e) {
      await _clearLocalSessionState();
      throw AppwriteException('Failed to persist web session: ${RedactionHelper.sanitize(e.toString())}');
    }
  }

  Future<void> _restoreWebSession() async {
    if (!_isWeb) return;
    final prefs = await _getPrefs();
    final secret = prefs.getString(_webSessionSecretKey);
    final ts = prefs.getInt(_webSessionTimestampKey);

    if (secret == null ||
        secret.isEmpty ||
        ts == null ||
        !_isWebSessionValid(ts)) {
      AppLogger.debug(
        'Appwrite: Web session secret or timestamp invalid; failing closed and clearing',
      );
      await _clearLocalSessionState();
      return;
    }
    _client.setSession(secret);
  }

  void restoreWebSessionSync(SharedPreferences prefs) {
    if (!_isWeb) return;
    _client.setSession('');
    final secret = prefs.getString(_webSessionSecretKey);
    final ts = prefs.getInt(_webSessionTimestampKey);

    if (secret == null ||
        secret.isEmpty ||
        ts == null ||
        !_isWebSessionValid(ts)) {
      AppLogger.debug(
        'Appwrite: Web session secret or timestamp invalid in sync restore; failing closed and clearing',
      );
      unawaited(_clearLocalSessionState());
      return;
    }
    _client.setSession(secret);
    AppLogger.debug('Appwrite: Web session restored synchronously ✅');
  }

  Future<void> _clearLocalSessionState() async {
    _client.setSession('');
    try {
      final prefs = await _getPrefs();
      try {
        await prefs.setBool(_hasLocalSessionKey, false);
      } catch (e) {
        AppLogger.debug('Appwrite: Failed to clear local session flag: ${RedactionHelper.sanitize(e.toString())}');
      }
      try {
        await prefs.remove(_webSessionSecretKey);
      } catch (e) {
        AppLogger.debug('Appwrite: Failed to remove session secret: ${RedactionHelper.sanitize(e.toString())}');
      }
      try {
        await prefs.remove(_webSessionTimestampKey);
      } catch (e) {
        AppLogger.debug('Appwrite: Failed to remove session timestamp: ${RedactionHelper.sanitize(e.toString())}');
      }
    } catch (e) {
      AppLogger.debug('Appwrite: Preference storage error: ${RedactionHelper.sanitize(e.toString())}');
    } finally {
      _client.setSession('');
    }
  }

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
      await _account
          .getSession(sessionId: 'current')
          .timeout(const Duration(seconds: 3));
      AppLogger.debug('Appwrite: Session active ✅');
      await prefs.setBool(_hasLocalSessionKey, true);
      return true;
    } catch (e) {
      AppLogger.debug('Appwrite: isLoggedIn error: ${RedactionHelper.sanitize(e.toString())}');

      final hasLocal = prefs.getBool(_hasLocalSessionKey) ?? false;
      // ignore: invalid_use_of_visible_for_testing_member
      if (hasLocal && isTransientSessionValidationFailure(e)) {
        AppLogger.debug(
          'Appwrite: transient session validation failure; using cached session.',
        );
        return true;
      }

      if (e is AppwriteException && e.code == 401) {
        AppLogger.debug(
          'Appwrite: Session expired (401). Clearing local flag.',
        );
        await _clearLocalSessionState();
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
      AppLogger.debug('Appwrite: Sign out error: ${RedactionHelper.sanitize(e.toString())}');
    } finally {
      await _clearLocalSessionState();
    }
  }

  /// Permanently delete the user account from Appwrite and clear all local state.
  Future<void> deleteAccount() async {
    try {
      await _restoreWebSession();
      final execution = await _functions.createExecution(
        functionId: 'delete-account',
      );

      // ignore: invalid_use_of_visible_for_testing_member
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

      await _clearLocalSessionState();
    } on AppwriteException catch (e) {
      AppLogger.error('Appwrite: deleteAccount error: ${RedactionHelper.sanitize(e.message ?? e.toString())}');
      rethrow;
    } catch (e) {
      AppLogger.error('Appwrite: deleteAccount unexpected error: ${RedactionHelper.sanitize(e.toString())}');
      throw AppwriteException('Account deletion failed: ${RedactionHelper.sanitize(e.toString())}', 500);
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

    // ignore: invalid_use_of_visible_for_testing_member
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
