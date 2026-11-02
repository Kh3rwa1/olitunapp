import 'dart:async';

import 'package:appwrite/appwrite.dart';

import 'account_scope.dart';
import 'worker_auth.dart';

/// Bearer tokens for Cloudflare Worker requests.
///
/// The Worker derives the caller's identity only from this token, so every
/// per-user edge call must attach [headers]. The app-wide [instance] uses
/// Worker sign-in sessions ([WorkerAuth]); the [Account] constructor keeps
/// the older Appwrite-JWT source (Appwrite JWTs are cached because Appwrite
/// rate-limits their creation, and dropped when the account scope changes).
class EdgeAuth {
  EdgeAuth(Account account, {DateTime Function()? now})
    : this.lazy(() => account, now: now);

  /// Appwrite-JWT source that resolves the [Account] on first use.
  EdgeAuth.lazy(Account Function() account, {DateTime Function()? now})
    : _account = account,
      _source = null,
      _now = now ?? DateTime.now {
    AccountScope.changes.listen((_) => clear());
  }

  /// Tokens from [source] (already cached and refreshed by its owner).
  EdgeAuth.source(Future<String?> Function() source)
    : _account = null,
      _source = source,
      _now = DateTime.now;

  /// Worker sign-in sessions; see [WorkerAuth.accessToken].
  static final EdgeAuth instance = EdgeAuth.source(
    WorkerAuth.instance.accessToken,
  );

  /// Appwrite JWTs live 15 minutes; refresh well before expiry.
  static const Duration tokenLifetime = Duration(minutes: 10);

  final Account Function()? _account;
  final Future<String?> Function()? _source;
  final DateTime Function() _now;

  String? _jwt;
  DateTime? _expiresAt;
  Future<String?>? _inFlight;
  int _generation = 0;

  /// `Authorization` header for the current session, or empty when there is
  /// no session (the Worker then answers 401 for protected routes).
  Future<Map<String, String>> headers() async {
    final jwt = await token();
    return jwt == null ? const {} : {'Authorization': 'Bearer $jwt'};
  }

  Future<String?> token() {
    final source = _source;
    if (source != null) {
      return source().catchError((Object _) => null);
    }
    final jwt = _jwt;
    final expiresAt = _expiresAt;
    if (jwt != null && expiresAt != null && _now().isBefore(expiresAt)) {
      return Future.value(jwt);
    }
    return _inFlight ??= _create().whenComplete(() => _inFlight = null);
  }

  Future<String?> _create() async {
    final generation = _generation;
    try {
      final created = await _account!().createJWT();
      if (generation != _generation || created.jwt.isEmpty) return null;
      _jwt = created.jwt;
      _expiresAt = _now().add(tokenLifetime);
      return _jwt;
    } catch (_) {
      // No session (signed out, offline): callers send no Authorization.
      return null;
    }
  }

  /// Forgets the cached token, e.g. after sign-out or an account switch.
  void clear() {
    _generation++;
    _jwt = null;
    _expiresAt = null;
    _inFlight = null;
  }
}
