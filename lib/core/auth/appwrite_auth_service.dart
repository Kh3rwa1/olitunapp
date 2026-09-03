import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
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
    _browserAuthenticate = FlutterWebAuth2.authenticate;
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
    Future<String> Function({
      required String url,
      required String callbackUrlScheme,
    })? browserAuthenticate,
  }) : _client = client,
       _account = account,
       _functions = functions,
       _prefsOverride = prefs,
       _nowProvider = nowProvider,
       _isWebOverride = isWebOverride,
       _browserAuthenticate =
           browserAuthenticate ?? FlutterWebAuth2.authenticate;

  /// Browser entry-point for the mobile OAuth flow. A field (not a direct
  /// plugin call) so unit tests can inject a canned callback URL instead of
  /// opening a real browser — the platform channel has no VM implementation.
  late final Future<String> Function({
    required String url,
    required String callbackUrlScheme,
  }) _browserAuthenticate;

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
    final session = await _account.createSession(
      userId: userId,
      secret: secret,
    );
    final prefs = await _getPrefs();
    await prefs.setBool(_hasLocalSessionKey, true);
    return session;
  }

  // ─── Google OAuth ───

  Future<void> signInWithGoogle() async {
    AppLogger.debug('Appwrite: Starting Google OAuth');

    try {
      if (kIsWeb) {
        final origin = Uri.base.origin;
        final oauthUrl =
            '${AppwriteConfig.endpoint}/account/tokens/oauth2/google'
            '?project=${AppwriteConfig.projectId}'
            '&success=${Uri.encodeComponent("$origin/splash")}'
            '&failure=${Uri.encodeComponent("$origin/welcome")}'
            '&scopes[]=${Uri.encodeComponent("email")}'
            '&scopes[]=${Uri.encodeComponent("profile")}';
        redirectToUrl(oauthUrl);
      } else {
        // Mobile: drive flutter_web_auth_2 directly instead of the SDK's
        // createOAuth2Token. The SDK's internal callback parser requires
        // `key` + `secret`, but the token endpoint returns `userId` +
        // `secret` — so every successful Google consent ended in
        // "Invalid OAuth2 Response. Key and Secret not available." and no
        // session was ever created. Parsing with the app's own
        // parseWebOAuthCompletion (same contract as the web flow) and then
        // exchanging via exchangeOAuthToken yields a real server session.
        final oauthUrl = buildMobileGoogleOAuthUrl(
          endpoint: AppwriteConfig.endpoint,
          projectId: AppwriteConfig.projectId,
        );
        final result = await _browserAuthenticate(
          url: oauthUrl.toString(),
          callbackUrlScheme:
              'appwrite-callback-${AppwriteConfig.projectId}',
        );
        final completion = parseWebOAuthCompletion(result);
        final exchanged =
            completion.kind == WebOAuthCompletionKind.persistSession
            ? await _persistWebSession(completion.secret).then((_) => true)
            : await exchangeOAuthToken(
                completion.userId!,
                completion.secret,
              );
        if (!exchanged) {
          throw AppwriteException(
            'Google sign-in failed: session could not be created.',
          );
        }
        final prefs = await _getPrefs();
        await prefs.setBool(_hasLocalSessionKey, true);
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
        final session = await _account.createSession(
          userId: userId,
          secret: secret,
        );
        if (_isWeb) {
          await _persistWebSession(session.secret);
        }
      }
      AppLogger.debug('Appwrite: OAuth session created ✅');
      return true;
    } catch (e) {
      AppLogger.debug(
        'Appwrite: Failed to create session from token: ${RedactionHelper.sanitize(e.toString())}',
      );
      return false;
    }
  }

  Future<void> _persistWebSession(String secret) async {
    final prefs = await _getPrefs();
    await SessionPersistence.persistWebSession(
      client: _client,
      prefs: prefs,
      secret: secret,
      nowProvider: _nowProvider,
      isWebOverride: _isWeb,
    );
  }

  Future<void> _restoreWebSession() async {
    final prefs = await _getPrefs();
    await SessionPersistence.restoreWebSession(
      client: _client,
      prefs: prefs,
      isWeb: _isWeb,
      nowProvider: _nowProvider,
    );
  }

  void restoreWebSessionSync(SharedPreferences prefs) {
    if (!_isWeb) return;
    _client.setSession('');
    final ts = prefs.getInt(SessionPersistence.webSessionTimestampKey);
    final hasSession =
        prefs.getBool(SessionPersistence.hasLocalSessionKey) ?? false;

    if (!hasSession || ts == null || !_isWebSessionValid(ts)) {
      AppLogger.debug(
        'Appwrite: Web session timestamp invalid in sync restore; failing closed and clearing',
      );
      unawaited(_clearLocalSessionState());
      return;
    }
    AppLogger.debug('Appwrite: Web session validated synchronously ✅');
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
    if (!hasLocal && !_isWeb) {
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
      AppLogger.error(
        'Appwrite: deleteAccount error: ${RedactionHelper.sanitize(e.message ?? e.toString())}',
      );
      rethrow;
    } catch (e) {
      AppLogger.error(
        'Appwrite: deleteAccount unexpected error: ${RedactionHelper.sanitize(e.toString())}',
      );
      throw AppwriteException(
        'Account deletion failed: ${RedactionHelper.sanitize(e.toString())}',
        500,
      );
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
