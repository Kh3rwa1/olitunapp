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
export 'session_persistence.dart';

import 'account_deletion_handler.dart';
import 'oauth_helpers.dart';
import 'admin_functions_client.dart';
import 'session_validator.dart';
import 'session_persistence.dart';

class AppwriteAuthService {
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
      AppLogger.debug(
        'Appwrite: Ping failed ❌ ${RedactionHelper.sanitize(e.toString())}',
      );
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
<<<<<<< HEAD
    final prefs = await _getPrefs();
    await SessionPersistence.persistWebSession(
      client: _client,
      prefs: prefs,
      secret: secret,
      nowProvider: _nowProvider,
=======
    _client.setSession(secret);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webSessionSecretKey, secret);
    await prefs.setInt(
      _webSessionTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
>>>>>>> origin/hardening/release-candidate-10-of-10
    );
  }

  Future<void> _restoreWebSession() async {
<<<<<<< HEAD
    final prefs = await _getPrefs();
    await SessionPersistence.restoreWebSession(
      client: _client,
      prefs: prefs,
      isWeb: _isWeb,
      nowProvider: _nowProvider,
    );
=======
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final secret = prefs.getString(_webSessionSecretKey);
    final ts = prefs.getInt(_webSessionTimestampKey);

    if (secret != null && secret.isNotEmpty) {
      if (ts == null) {
        AppLogger.debug(
          'Appwrite: Web session missing timestamp; failing closed and clearing',
        );
        await _clearWebSession();
        return;
      }
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
      if (age > _maxWebSessionDuration) {
        AppLogger.debug(
          'Appwrite: Web session expired after ${_maxWebSessionDuration.inHours}h; clearing',
        );
        await _clearWebSession();
        return;
      }
      _client.setSession(secret);
    }
>>>>>>> origin/hardening/release-candidate-10-of-10
  }

  void restoreWebSessionSync(SharedPreferences prefs) {
    if (!_isWeb) return;
    _client.setSession('');
    final ts = prefs.getInt(SessionPersistence.webSessionTimestampKey);
    final hasSession =
        prefs.getBool(SessionPersistence.hasLocalSessionKey) ?? false;

<<<<<<< HEAD
    if (!hasSession || ts == null || !_isWebSessionValid(ts)) {
      AppLogger.debug(
        'Appwrite: Web session timestamp invalid in sync restore; failing closed and clearing',
      );
      unawaited(_clearLocalSessionState());
      return;
    }
    AppLogger.debug('Appwrite: Web session validated synchronously ✅');
=======
    if (secret != null && secret.isNotEmpty) {
      if (ts == null ||
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) >
              _maxWebSessionDuration) {
        prefs.remove(_webSessionSecretKey);
        prefs.remove(_webSessionTimestampKey);
        try {
          _client.setSession('');
        } catch (_) {}
        return;
      }
      _client.setSession(secret);
      AppLogger.debug('Appwrite: Web session restored synchronously ✅');
    }
  }

  Future<void> _clearWebSession() async {
    if (!kIsWeb) return;
    try {
      _client.setSession('');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_webSessionSecretKey);
    await prefs.remove(_webSessionTimestampKey);
>>>>>>> origin/hardening/release-candidate-10-of-10
  }

  Future<void> _clearLocalSessionState() async {
    final prefs = await _getPrefs();
    await SessionPersistence.clearLocalSessionState(
      client: _client,
      prefs: prefs,
    );
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
      AppLogger.debug(
        'Appwrite: isLoggedIn error: ${RedactionHelper.sanitize(e.toString())}',
      );

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
      AppLogger.debug(
        'Appwrite: Sign out error: ${RedactionHelper.sanitize(e.toString())}',
      );
    } finally {
      await _clearLocalSessionState();
    }
  }

  /// Permanently delete the user account from Appwrite and clear all local state.
  Future<void> deleteAccount() async {
    try {
      await _restoreWebSession();
<<<<<<< HEAD
=======
      // Hard-delete the account using our Cloud Function
>>>>>>> origin/hardening/release-candidate-10-of-10
      final execution = await _functions.createExecution(
        functionId: 'delete-account',
      );

<<<<<<< HEAD
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

=======
      final trimmedBody = execution.responseBody.trim();
      Map<String, dynamic>? responseData;
      if (trimmedBody.isNotEmpty) {
        try {
          responseData = jsonDecode(trimmedBody) as Map<String, dynamic>;
        } catch (_) {}
      }

      final isAuthDeleted = responseData?['authDeleted'] == true;

      // If execution status failed, status code is non-2xx, or server returned ok != true
      if (execution.status.toString().toLowerCase() == 'failed' ||
          execution.responseStatusCode < 200 ||
          execution.responseStatusCode >= 300 ||
          responseData == null ||
          responseData['ok'] != true) {
        // If server confirmed Auth user was deleted before state update error:
        if (isAuthDeleted) {
          await _clearLocalSessionState();
          throw AppwriteException(
            'Account deleted; final cleanup reconciliation is pending.',
            execution.responseStatusCode != 0
                ? execution.responseStatusCode
                : 500,
          );
        }

        final errCode =
            responseData?['code']?.toString() ??
            responseData?['message']?.toString() ??
            'Account deletion failed on server';

        throw AppwriteException(
          errCode,
          execution.responseStatusCode != 0
              ? execution.responseStatusCode
              : 500,
        );
      }

      // Server confirmed full deletion success; clear local session state
>>>>>>> origin/hardening/release-candidate-10-of-10
      await _clearLocalSessionState();
    } on AppwriteException catch (e) {
      AppLogger.error(
        'Appwrite: deleteAccount error: ${RedactionHelper.sanitize(e.message ?? e.toString())}',
      );
      rethrow;
    } catch (e) {
<<<<<<< HEAD
      AppLogger.error(
        'Appwrite: deleteAccount unexpected error: ${RedactionHelper.sanitize(e.toString())}',
      );
      throw AppwriteException(
        'Account deletion failed: ${RedactionHelper.sanitize(e.toString())}',
        500,
      );
=======
      AppLogger.error('Appwrite: deleteAccount unexpected error: $e');
      throw AppwriteException('Account deletion failed: ${e.toString()}', 500);
>>>>>>> origin/hardening/release-candidate-10-of-10
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
