import 'dart:async';

import 'package:appwrite/appwrite.dart';

import 'account_scope.dart';
import 'appwrite_auth_service.dart';

/// Short-lived Appwrite JWTs for Cloudflare Worker requests.
///
/// The Worker derives the caller's identity only from this token (verified
/// against Appwrite), so every per-user edge call must attach [headers].
/// Tokens are cached because Appwrite rate-limits JWT creation; the cache is
/// dropped whenever the local account scope changes.
class EdgeAuth {
  EdgeAuth(Account account, {DateTime Function()? now})
    : this.lazy(() => account, now: now);

  /// Resolves the [Account] on first use so merely referencing [instance]
  /// does not construct the Appwrite client.
  EdgeAuth.lazy(this._account, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    AccountScope.changes.listen((_) => clear());
  }

  static final EdgeAuth instance = EdgeAuth.lazy(
    () => AppwriteAuthService().account,
  );

  /// Appwrite JWTs live 15 minutes; refresh well before expiry.
  static const Duration tokenLifetime = Duration(minutes: 10);

  final Account Function() _account;
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
      final created = await _account().createJWT();
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
