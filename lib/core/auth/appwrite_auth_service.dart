import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
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
export 'worker_auth.dart' show WorkerAuth, WorkerAuthConfig, WorkerUser;

import 'account_deletion_handler.dart';
import 'session_persistence.dart';
import 'account_scope.dart';
import 'admin_functions_client.dart';
import 'edge_auth.dart';
import 'worker_auth.dart';
import '../api/appwrite_functions_service.dart';
import 'package:itun/core/ads/ad_service.dart';

/// The app's sign-in service.
///
/// Sessions are issued by the Cloudflare Worker ([WorkerAuth]): guest,
/// email code and Google. Appwrite Auth is no longer used to sign in (its
/// organization is read-only, so every Appwrite write fails); a device that
/// was signed in to Appwrite is moved to a Worker session once, keeping its
/// user id. The name and the Appwrite model return types are kept so the
/// rest of the app is unchanged.
class AppwriteAuthService with AdminFunctionsMixin {
  static const String _hasLocalSessionKey = 'olitun_has_local_session';

  /// Query key the Worker uses to hand a web Google sign-in back to the app.
  static const String webLoginCodeParam = 'olitun_code';

  // Singleton pattern — one SDK Client shared across the app
  AppwriteAuthService._internal() {
    _client = Client();
    final endpoint = AppwriteConfig.endpoint;
    final projectId = AppwriteConfig.projectId;
    _client.setEndpoint(
      endpoint.isNotEmpty ? endpoint : 'https://localhost/v1',
    );
    _client.setProject(projectId.isNotEmpty ? projectId : 'placeholder');

    if (const bool.fromEnvironment('ALLOW_SELF_SIGNED')) {
      _client.setSelfSigned();
    }

    _account = Account(_client);
    _worker = WorkerAuth.instance;
    _edgeFunctions = AppwriteFunctionsService(edgeAuth: EdgeAuth.instance);
    _browserAuthenticate = FlutterWebAuth2.authenticate;
    _accountDeletionRequest = edgeAccountDeletionRequest(
      edgeAuth: EdgeAuth.instance,
    );
  }

  static final AppwriteAuthService _instance = AppwriteAuthService._internal();
  factory AppwriteAuthService() => _instance;

  late final Client _client;
  late final Account _account;
  late final WorkerAuth _worker;
  late final AppwriteFunctionsService _edgeFunctions;
  late final AccountDeletionRequest _accountDeletionRequest;

  SharedPreferences? _prefsOverride;
  bool? _isWebOverride;
  Future<List<ConnectivityResult>> Function()? _connectivityOverride;

  @visibleForTesting
  AppwriteAuthService.forTesting({
    required Client client,
    required Account account,
    required WorkerAuth workerAuth,
    AppwriteFunctionsService? edgeFunctions,
    SharedPreferences? prefs,
    bool? isWebOverride,
    Future<List<ConnectivityResult>> Function()? connectivity,
    Future<String> Function({
      required String url,
      required String callbackUrlScheme,
    })?
    browserAuthenticate,
    AccountDeletionRequest? accountDeletionRequest,
  }) : _client = client,
       _account = account,
       _worker = workerAuth,
       _edgeFunctions =
           edgeFunctions ??
           AppwriteFunctionsService(
             edgeAuth: EdgeAuth.source(workerAuth.accessToken),
           ),
       _prefsOverride = prefs,
       _isWebOverride = isWebOverride,
       _connectivityOverride = connectivity,
       _browserAuthenticate =
           browserAuthenticate ?? FlutterWebAuth2.authenticate,
       _accountDeletionRequest =
           accountDeletionRequest ??
           edgeAccountDeletionRequest(
             edgeAuth: EdgeAuth.source(workerAuth.accessToken),
           );

  /// Browser entry-point for the mobile OAuth flow. A field (not a direct
  /// plugin call) so unit tests can inject a canned callback URL instead of
  /// opening a real browser — the platform channel has no VM implementation.
  late final Future<String> Function({
    required String url,
    required String callbackUrlScheme,
  })
  _browserAuthenticate;

  /// The Appwrite SDK objects, kept for the remaining Appwrite reads.
  Account get account => _account;
  Client get client => _client;

  /// The Worker session store behind this service.
  WorkerAuth get worker => _worker;

  Future<SharedPreferences> _getPrefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  bool get _isWeb => _isWebOverride ?? kIsWeb;

  void _requireCurrent(AccountScope scope) {
    if (!scope.isCurrent) throw AppwriteException('Account changed', 409);
  }

  Future<void> _requireOnline() async {
    final results =
        await (_connectivityOverride?.call() ??
            Connectivity().checkConnectivity());
    if (results.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
  }

  /// Runs a Worker sign-in call and makes its session this device's account.
  Future<WorkerSession> _signIn(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    final prefs = await _getPrefs();
    final scope = await AccountScope.beginSignIn(prefs);
    return AccountScope.dispatch(() async {
      _requireCurrent(scope);
      final response = await call();
      _requireCurrent(scope);
      final previous = await _worker.cached();
      final session = await _worker.adopt(response);
      if (previous != null && previous.refreshToken != session.refreshToken) {
        // A guest session being replaced: end it on the Worker too.
        unawaited(
          _worker.api.logout(previous.refreshToken).catchError((Object _) {}),
        );
      }
      final owner = await scope.identify(session.user.id);
      _requireCurrent(owner);
      await prefs.setBool(_hasLocalSessionKey, true);
      await prefs.setBool(WorkerAuth.legacyMigratedKey, true);
      return session;
    });
  }

  /// Email + password sign-in no longer exists (Appwrite only).
  Future<WorkerSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw AppwriteException(
      'Password sign-in is no longer available. Please sign in with an email code or Google.',
      400,
      'password_signin_removed',
    );
  }

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

  /// Which sign-in methods the Worker serves right now.
  Future<WorkerAuthConfig> signInOptions() => _worker.config();

  /// Guest session (progress syncs to a Worker account with no email).
  Future<WorkerSession> signInAnonymously() {
    AppLogger.debug('Auth: Creating guest session');
    return _signIn(_worker.api.guest);
  }

  // ─── Email code ───

  /// Emails a sign-in code. Returns the token id that [verifyOtp] takes as
  /// `userId` (the normalized email address).
  Future<String> sendOtpCode(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    AppLogger.debug('Auth: Sending email code');
    await _worker.api.startEmail(trimmedEmail);
    return trimmedEmail;
  }

  /// Verifies the emailed code ([userId] is the value [sendOtpCode]
  /// returned) and signs in.
  Future<WorkerSession> verifyOtp({
    required String userId,
    required String secret,
  }) {
    AppLogger.debug('Auth: Verifying email code');
    return _signIn(() => _worker.api.verifyEmail(userId, secret.trim()));
  }

  // ─── Google ───

  /// Ends any current session before Google sign-in; true when nobody is
  /// signed in afterwards.
  Future<bool> clearSessionsForOAuth() async {
    await _worker.clear();
    return true;
  }

  Future<void> signInWithGoogle() async {
    AppLogger.debug('Auth: Starting Google sign-in');
    if (_isWeb) {
      final url = _worker.api.googleStartUrl(
        web: true,
        returnUrl: '${Uri.base.origin}/',
      );
      redirectToUrl(url.toString());
      return;
    }

    AdService.instance.skipNextAppOpen();
    String result;
    try {
      result = await _browserAuthenticate(
        url: _worker.api.googleStartUrl(web: false).toString(),
        callbackUrlScheme: 'appwrite-callback-${AppwriteConfig.projectId}',
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw AppwriteException(
          'Google sign-in was cancelled.',
          0,
          'cancelled',
        );
      }
      rethrow;
    }
    final code = parseWorkerOAuthCallback(result);
    await _signIn(() => _worker.api.exchange(code));
  }

  /// Finishes a web Google sign-in from the `olitun_code` redirect param.
  Future<bool> exchangeLoginCode(String code) async {
    try {
      await _signIn(() => _worker.api.exchange(code));
      return true;
    } catch (e) {
      AppLogger.warning(
        'Auth: Google sign-in exchange failed: ${RedactionHelper.sanitize(e.toString())}',
      );
      return false;
    }
  }

  Future<void> _clearLocalSessionState({bool preserveAccount = false}) async {
    final prefs = await _getPrefs();
    await _worker.clear(revoke: false);
    await SessionPersistence.clearLocalSessionState(
      client: _client,
      prefs: prefs,
      forgetAccount: !preserveAccount,
    );
  }

  // ─── Session Management ───

  /// Whether this device has a session. Local and fast: the session is
  /// re-validated by the Worker whenever its access token is refreshed.
  Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    final scope = AccountScope.capture(prefs);
    if (scope.isExplicitlySignedOut) return false;

    WorkerSession? session;
    try {
      session = await _worker.current();
    } on AppwriteException catch (e) {
      // An Appwrite-era session could not be moved yet (offline / Worker
      // unavailable). Keep the user signed in; it is retried on next use.
      AppLogger.debug(
        'Auth: session migration deferred: ${RedactionHelper.sanitize(e.message ?? '')}',
      );
      return scope.isCurrent && (prefs.getBool(_hasLocalSessionKey) ?? false);
    }
    if (session == null) return false;
    if (!scope.isCurrent) return false;
    try {
      final owner = await scope.identify(session.user.id);
      _requireCurrent(owner);
    } catch (_) {
      return false;
    }
    await prefs.setBool(_hasLocalSessionKey, true);
    return true;
  }

  /// Current user profile; the cached copy when the Worker is unreachable.
  Future<models.User> getMe() async {
    final prefs = await _getPrefs();
    final scope = AccountScope.capture(prefs);
    if (scope.isExplicitlySignedOut) {
      throw AppwriteException('Signed out', 401);
    }
    final session = await _worker.current();
    if (session == null) throw AppwriteException('Signed out', 401);
    _requireCurrent(scope);

    final token = await _worker.accessToken();
    if (token == null) {
      if ((await _worker.cached()) == null) {
        throw AppwriteException('Signed out', 401);
      }
      return session.user.toAppwriteUser();
    }
    try {
      final data = await _worker.api.me(token);
      final user = WorkerUser.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
      await _worker.updateUser(user);
      await scope.identify(user.id);
      return user.toAppwriteUser();
    } on AppwriteException catch (e) {
      if (e.code == 401 && scope.isCurrent) {
        await _clearLocalSessionState(preserveAccount: true);
        rethrow;
      }
      if (e.code == 0) return session.user.toAppwriteUser();
      rethrow;
    }
  }

  /// Whether the signed-in user is an Olitun admin (checked by the Worker).
  Future<bool> isCurrentUserAdmin() async {
    final token = await _worker.accessToken();
    if (token == null) return false;
    final data = await _worker.api.me(token);
    return data['isAdmin'] == true;
  }

  Future<String> _requireToken() async {
    final token = await _worker.accessToken();
    if (token == null) throw AppwriteException('Signed out', 401);
    return token;
  }

  /// Update user display name
  Future<models.User> updateName(String name) async {
    await _requireOnline();
    final data = await _worker.api.updateName(await _requireToken(), name);
    final user = WorkerUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    await _worker.updateUser(user);
    return user.toAppwriteUser();
  }

  /// Update user preferences (for progress sync)
  Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    await _requireOnline();
    await AccountScope.dispatch(() async {
      final token = await _requireToken();
      await _worker.api.putPrefs(token, prefs);
    });
    AccountScope.checkOperation();
  }

  /// Get user preferences
  Future<models.Preferences> getPrefs() async {
    await _requireOnline();
    final result = await AccountScope.dispatch(() async {
      final token = await _requireToken();
      return _worker.api.getPrefs(token);
    });
    AccountScope.checkOperation();
    return models.Preferences(data: result);
  }

  /// Sign out — end the session on the Worker and locally.
  Future<void> signOut() async {
    final prefs = await _getPrefs();
    // Local sign-out is unconditional, including offline. The tombstone
    // prevents a surviving credential from silently restoring the account.
    final scope = await AccountScope.signOut(prefs);
    await AccountScope.dispatch(() async {
      if (!scope.isCurrent) return;
      try {
        await _worker.clear();
      } catch (e) {
        AppLogger.debug(
          'Auth: Sign out error: ${RedactionHelper.sanitize(e.toString())}',
        );
      } finally {
        if (scope.isCurrent) {
          await _clearLocalSessionState(preserveAccount: true);
        }
      }
    });
  }

  /// Permanently delete the account (data + login) through the Cloudflare
  /// Worker and clear all local state.
  Future<void> deleteAccount() => executeAccountDeletion(
    requestDeletion: _accountDeletionRequest,
    restoreWebSession: restoreWebSession,
    clearLocalSessionState: _clearLocalSessionState,
  );

  @override
  AppwriteFunctionsService get edgeFunctions => _edgeFunctions;

  /// Worker sessions need no web restore step; this only drops the
  /// Appwrite-era web session secret. Kept for [AdminFunctionsMixin].
  @override
  Future<void> restoreWebSession() async {
    await SessionPersistence.purgeLegacySessionSecret(await _getPrefs());
  }
}

/// The one-time login code from the Worker's Google callback
/// (`<scheme>://auth?olitun_code=…`), or the Worker's error as an
/// [AppwriteException].
String parseWorkerOAuthCallback(String result) {
  final uri = Uri.parse(result);
  final error = uri.queryParameters['error'];
  if (error != null && error.isNotEmpty) {
    throw AppwriteException(googleSignInErrorMessage(error), 400, error);
  }
  final code = uri.queryParameters[AppwriteAuthService.webLoginCodeParam];
  if (code == null || code.isEmpty) {
    throw AppwriteException(
      'Google sign-in failed: no login code was returned.',
      400,
      'oauth_missing_code',
    );
  }
  return code;
}

/// User-facing text for a Worker Google sign-in error id.
String googleSignInErrorMessage(String error) {
  switch (error) {
    case 'GOOGLE_CANCELLED':
      return 'Google sign-in was cancelled.';
    case 'GOOGLE_UNAVAILABLE':
      return 'Google sign-in is not available right now. Please use an email code.';
    case 'AUTH_NOT_CONFIGURED':
      return 'Sign-in is being set up. Please try again soon.';
    case 'ACCOUNT_DELETED':
      return 'This account was deleted.';
    case 'OAUTH_STATE_INVALID':
      return 'Google sign-in took too long. Please try again.';
    default:
      return 'Google sign-in failed. Please try again.';
  }
}

final appwriteAuthServiceProvider = Provider<AppwriteAuthService>((ref) {
  final service = AppwriteAuthService();
  if (kIsWeb) {
    // Touch shared preferences so web startup ordering stays unchanged.
    ref.watch(sharedPreferencesProvider);
  }
  return service;
});
