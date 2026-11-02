import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart' show AppwriteException;
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/appwrite_config.dart';
import '../config/cloudflare_config.dart';
import '../logging/app_logger.dart';
import '../logging/redaction_helper.dart';
import 'account_scope.dart';
import 'legacy_appwrite_session.dart' as legacy;

/// Sign-in served by the Cloudflare Worker (`/api/v1/auth/*`).
///
/// Appwrite Auth became unusable when the Appwrite organization went
/// read-only: every session create, email token and JWT mint returns 402.
/// The Worker now issues the sessions; errors still surface as
/// [AppwriteException] (HTTP status as `code`, Worker error id as `type`) so
/// the existing error handling and messages keep working.

/// The signed-in user as the Worker reports it.
@immutable
class WorkerUser {
  const WorkerUser({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerified,
    required this.isGuest,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final bool emailVerified;
  final bool isGuest;
  final String createdAt;
  final String updatedAt;

  factory WorkerUser.fromJson(Map<String, dynamic> json) => WorkerUser(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    name: json['name'] as String? ?? '',
    emailVerified: json['emailVerified'] as bool? ?? false,
    isGuest: json['isGuest'] as bool? ?? false,
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'emailVerified': emailVerified,
    'isGuest': isGuest,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  /// The same user as an Appwrite [models.User], for callers written
  /// against the Appwrite SDK.
  models.User toAppwriteUser() => models.User.fromMap({
    '\$id': id,
    '\$createdAt': createdAt,
    '\$updatedAt': updatedAt,
    'name': name,
    'registration': createdAt,
    'status': true,
    'labels': isGuest ? ['guest'] : <String>[],
    'passwordUpdate': '',
    'email': email,
    'phone': '',
    'emailVerification': emailVerified,
    'phoneVerification': false,
    'mfa': false,
    'prefs': <String, dynamic>{},
    'targets': <dynamic>[],
    'accessedAt': updatedAt,
  });
}

/// Tokens for one signed-in device.
@immutable
class WorkerSession {
  const WorkerSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final WorkerUser user;

  factory WorkerSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final access = json['accessToken'] as String? ?? '';
    final refresh = json['refreshToken'] as String? ?? '';
    if (access.isEmpty || refresh.isEmpty || user is! Map) {
      throw AppwriteException('Sign-in failed: malformed session.', 500);
    }
    return WorkerSession(
      accessToken: access,
      accessTokenExpiresAt:
          DateTime.tryParse(json['accessTokenExpiresAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      refreshToken: refresh,
      user: WorkerUser.fromJson(Map<String, dynamic>.from(user)),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'user': user.toJson(),
  };

  WorkerSession copyWith({WorkerUser? user}) => WorkerSession(
    accessToken: accessToken,
    accessTokenExpiresAt: accessTokenExpiresAt,
    refreshToken: refreshToken,
    user: user ?? this.user,
  );
}

/// Which sign-in methods the Worker can serve right now.
@immutable
class WorkerAuthConfig {
  const WorkerAuthConfig({
    required this.guest,
    required this.email,
    required this.google,
  });

  /// Optimistic default while the config has not loaded (or is unreachable).
  static const fallback = WorkerAuthConfig(
    guest: true,
    email: true,
    google: true,
  );

  final bool guest;
  final bool email;
  final bool google;
}

/// HTTP client for the Worker's `/api/v1/auth` routes.
class WorkerAuthApi {
  WorkerAuthApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _base = (baseUrl ?? CloudflareConfig.baseUrl).replaceAll(
        RegExp(r'/+$'),
        '',
      );

  final http.Client _client;
  final String _base;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _uri(String path) => Uri.parse('$_base/api/v1/auth$path');

  /// Where the browser starts Google sign-in.
  Uri googleStartUrl({required bool web, String? returnUrl}) {
    final query = <String, String>{'platform': web ? 'web' : 'android'};
    if (web && returnUrl != null) query['return'] = returnUrl;
    return _uri('/google/start').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    String? accessToken,
    Duration timeout = _timeout,
  }) async {
    final request = http.Request(method, _uri(path));
    request.headers['Accept'] = 'application/json';
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
    } on TimeoutException {
      throw AppwriteException('Request timed out', 0, 'network_failure');
    } catch (e) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }

    Map<String, dynamic> data = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Non-JSON (e.g. a proxy error page): handled by the status below.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['message'] as String?;
      throw AppwriteException(
        message ?? 'Request failed (${response.statusCode})',
        response.statusCode,
        data['error'] as String? ?? 'worker_error',
      );
    }
    return data;
  }

  Future<WorkerAuthConfig> config() async {
    final data = await _send(
      'GET',
      '/config',
      timeout: const Duration(seconds: 6),
    );
    return WorkerAuthConfig(
      guest: data['guest'] == true,
      email: data['email'] == true,
      google: data['google'] == true,
    );
  }

  Future<Map<String, dynamic>> guest() => _send('POST', '/guest', body: {});

  Future<void> startEmail(String email) async {
    await _send('POST', '/email/start', body: {'email': email});
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) =>
      _send('POST', '/email/verify', body: {'email': email, 'code': code});

  Future<Map<String, dynamic>> exchange(String code) =>
      _send('POST', '/exchange', body: {'code': code});

  Future<Map<String, dynamic>> migrateAppwrite(String session) =>
      _send('POST', '/appwrite/migrate', body: {'session': session});

  Future<Map<String, dynamic>> refresh(String refreshToken) =>
      _send('POST', '/refresh', body: {'refreshToken': refreshToken});

  Future<void> logout(String refreshToken) async {
    await _send(
      'POST',
      '/logout',
      body: {'refreshToken': refreshToken},
      timeout: const Duration(seconds: 5),
    );
  }

  Future<Map<String, dynamic>> me(String accessToken) => _send(
    'GET',
    '/me',
    accessToken: accessToken,
    timeout: const Duration(seconds: 6),
  );

  Future<Map<String, dynamic>> updateName(String accessToken, String name) =>
      _send('PATCH', '/me', accessToken: accessToken, body: {'name': name});

  Future<Map<String, dynamic>> getPrefs(String accessToken) async {
    final data = await _send('GET', '/prefs', accessToken: accessToken);
    final prefs = data['prefs'];
    return prefs is Map ? Map<String, dynamic>.from(prefs) : {};
  }

  Future<void> putPrefs(String accessToken, Map<String, dynamic> prefs) async {
    await _send(
      'PUT',
      '/prefs',
      accessToken: accessToken,
      body: {'prefs': prefs},
    );
  }
}

typedef LegacySessionReader = Future<String?> Function();
typedef LegacySessionClearer = Future<void> Function();

/// The device's Worker session: persisted, refreshed, and migrated once
/// from a surviving Appwrite session.
class WorkerAuth {
  WorkerAuth({
    WorkerAuthApi? api,
    Future<SharedPreferences> Function()? prefs,
    DateTime Function()? now,
    LegacySessionReader? readLegacySession,
    LegacySessionClearer? clearLegacySession,
    bool? isWeb,
  }) : _api = api ?? WorkerAuthApi(),
       _prefs = prefs ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now,
       _readLegacy =
           readLegacySession ??
           (() => legacy.readLegacyAppwriteSession(
             endpoint: AppwriteConfig.endpoint,
             projectId: AppwriteConfig.projectId,
           )),
       _clearLegacy =
           clearLegacySession ??
           (() => legacy.clearLegacyAppwriteSession(
             endpoint: AppwriteConfig.endpoint,
           )),
       _isWeb = isWeb ?? kIsWeb;

  static final WorkerAuth instance = WorkerAuth();

  static const String storageKey = 'olitun_worker_session_v1';

  /// Set by the Appwrite-era app whenever it held a session; a device with
  /// this flag but no Worker session still has an Appwrite session to move.
  static const String legacySessionFlagKey = 'olitun_has_local_session';
  static const String legacyMigratedKey = 'olitun_appwrite_migrated_v1';

  /// Refresh the access token this long before it expires.
  static const Duration refreshMargin = Duration(minutes: 2);

  final WorkerAuthApi _api;
  final Future<SharedPreferences> Function() _prefs;
  final DateTime Function() _now;
  final LegacySessionReader _readLegacy;
  final LegacySessionClearer _clearLegacy;
  final bool _isWeb;

  WorkerSession? _session;
  bool _loaded = false;
  Future<String?>? _refreshing;
  Future<WorkerSession?>? _migrating;
  WorkerAuthConfig? _config;

  WorkerAuthApi get api => _api;

  Future<WorkerSession?> _load() async {
    if (_loaded) return _session;
    final prefs = await _prefs();
    final raw = prefs.getString(storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _session = WorkerSession.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (e) {
        AppLogger.debug('WorkerAuth: dropping unreadable session ($e)');
        await prefs.remove(storageKey);
      }
    }
    _loaded = true;
    return _session;
  }

  Future<void> _persist(WorkerSession? session) async {
    final prefs = await _prefs();
    _session = session;
    _loaded = true;
    if (session == null) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setString(storageKey, jsonEncode(session.toJson()));
    }
  }

  /// Stores the session from a Worker sign-in response.
  Future<WorkerSession> adopt(Map<String, dynamic> response) async {
    final session = WorkerSession.fromJson(response);
    await _persist(session);
    return session;
  }

  /// The stored session, migrating a surviving Appwrite session first when
  /// this device has one. Null when signed out.
  Future<WorkerSession?> current() async {
    final session = await _load();
    if (session != null) return session;
    return migrateLegacySession();
  }

  /// The stored session without any network work.
  Future<WorkerSession?> cached() => _load();

  /// Whether this device still holds an Appwrite session to migrate.
  Future<bool> hasPendingLegacySession() async {
    if (_isWeb) return false;
    final prefs = await _prefs();
    if (prefs.getBool(legacyMigratedKey) ?? false) return false;
    return prefs.getBool(legacySessionFlagKey) ?? false;
  }

  /// Hands a surviving Appwrite session to the Worker once. The Worker keeps
  /// the Appwrite user id, so local progress keyed by it stays this user's.
  Future<WorkerSession?> migrateLegacySession() {
    return _migrating ??= _migrate().whenComplete(() => _migrating = null);
  }

  Future<WorkerSession?> _migrate() async {
    if (!await hasPendingLegacySession()) return null;
    final prefs = await _prefs();
    String? secret;
    try {
      secret = await _readLegacy();
    } catch (e) {
      AppLogger.debug('WorkerAuth: could not read Appwrite cookie ($e)');
    }
    if (secret == null || secret.isEmpty) {
      // Nothing to move: the old session is gone.
      await _forgetLegacySession(prefs);
      return null;
    }
    try {
      final session = await adopt(await _api.migrateAppwrite(secret));
      await prefs.setBool(legacyMigratedKey, true);
      await _clearLegacy().catchError((Object _) {});
      AppLogger.debug('WorkerAuth: moved Appwrite session to Worker sign-in');
      return session;
    } on AppwriteException catch (e) {
      final rejected = e.code == 401 || e.code == 403 || e.code == 400;
      if (rejected) {
        // The Appwrite session is dead or the account was deleted: sign out.
        await _forgetLegacySession(prefs);
        await _clearLegacy().catchError((Object _) {});
        return null;
      }
      // Offline or Worker unavailable: retry on the next call.
      AppLogger.debug(
        'WorkerAuth: migration deferred: ${RedactionHelper.sanitize(e.message ?? '')}',
      );
      rethrow;
    }
  }

  /// Marks the Appwrite-era session as gone. An owner that was never
  /// identified stays unknown (never guest), so unowned legacy progress is
  /// not imported into a guest profile.
  Future<void> _forgetLegacySession(SharedPreferences prefs) async {
    await AccountScope.preserveLegacyOwner(prefs);
    await prefs.setBool(legacyMigratedKey, true);
    await prefs.setBool(legacySessionFlagKey, false);
  }

  /// A valid access token, refreshed when close to expiry. Null when signed
  /// out, or when offline with an expired token.
  Future<String?> accessToken() async {
    WorkerSession? session;
    try {
      session = await current();
    } catch (_) {
      return null;
    }
    if (session == null) return null;
    if (_now().isBefore(session.accessTokenExpiresAt.subtract(refreshMargin))) {
      return session.accessToken;
    }
    return _refreshing ??= _refresh(
      session,
    ).whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh(WorkerSession session) async {
    try {
      final next = WorkerSession.fromJson(
        await _api.refresh(session.refreshToken),
      );
      if (!_isCurrent(session)) {
        // Signed out or switched accounts while this was in flight: never
        // bring the old session back, and end the one the Worker just
        // extended.
        _revoke(next.refreshToken);
        return _session?.accessToken;
      }
      await _persist(next);
      return next.accessToken;
    } on AppwriteException catch (e) {
      if (!_isCurrent(session)) return _session?.accessToken;
      if (e.code == 401 || e.code == 403) {
        // Revoked, expired or deleted: this device is signed out.
        await _persist(null);
        return null;
      }
      final stillValid = _now().isBefore(session.accessTokenExpiresAt);
      return stillValid ? session.accessToken : null;
    }
  }

  /// Whether [session] is still this device's session. Compared by refresh
  /// token, which a profile update ([updateUser]) leaves unchanged.
  bool _isCurrent(WorkerSession session) =>
      _session?.refreshToken == session.refreshToken;

  void _revoke(String refreshToken) {
    unawaited(
      _api.logout(refreshToken).catchError((Object e) {
        AppLogger.debug('WorkerAuth: logout call failed ($e)');
      }),
    );
  }

  /// Replaces the cached user (after a profile update or /me).
  Future<void> updateUser(WorkerUser user) async {
    final session = await _load();
    if (session == null || session.user.id != user.id) return;
    await _persist(session.copyWith(user: user));
  }

  /// Signs this device out locally; [revoke] also ends the session on the
  /// Worker (best effort).
  Future<void> clear({bool revoke = true}) async {
    final session = await _load();
    await _persist(null);
    if (revoke && session != null) _revoke(session.refreshToken);
  }

  /// Sign-in methods the Worker supports; cached for the process.
  Future<WorkerAuthConfig> config() async {
    final cached = _config;
    if (cached != null) return cached;
    try {
      return _config = await _api.config();
    } catch (_) {
      return WorkerAuthConfig.fallback;
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _session = null;
    _loaded = false;
    _refreshing = null;
    _migrating = null;
    _config = null;
  }
}
