import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Local ownership metadata, not an authentication credential. Never infer an
/// owner from connectivity or import unowned/guest progress into an account.
class AccountScope {
  static const storageKey = 'olitun_account_scope_v1';
  static final Object _zoneKey = Object();
  static final _changes = StreamController<SharedPreferences>.broadcast();
  static Stream<SharedPreferences> get changes => _changes.stream;

  final SharedPreferences _prefs;
  final String? _record;
  final String? userId;
  final bool isGuest;
  final bool isExplicitlySignedOut;
  final bool _mayIdentify;

  AccountScope._(
    this._prefs,
    this._record,
    this.userId,
    this.isGuest,
    this.isExplicitlySignedOut, [
    this._mayIdentify = false,
  ]);

  factory AccountScope.capture(SharedPreferences prefs) {
    final record = prefs.getString(storageKey);
    if (record == null) {
      // Upgrade policy: a legacy session with no owner must be resolved online.
      // A fresh installation/legacy signed-out installation remains a guest.
      final hasSession = prefs.getBool('olitun_has_local_session') ?? false;
      return AccountScope._(prefs, null, null, !hasSession, false);
    }
    try {
      final data = jsonDecode(record) as Map<String, dynamic>;
      final id = data['state'] == 'account' ? data['userId'] as String? : null;
      final guest = data['state'] == 'guest';
      return AccountScope._(
        prefs,
        record,
        id == null || id.isEmpty ? null : id,
        guest,
        guest,
        data['state'] == 'unresolved',
      );
    } catch (_) {
      // Corrupt identity metadata is unknown, never guest.
      return AccountScope._(prefs, record, null, false, false);
    }
  }

  bool get isKnown => isGuest || userId != null;
  String get _suffix => isGuest
      ? 'guest'
      : userId == 'guest'
      ? 'account:guest'
      : '$userId';
  String get statsKey => 'user_stats_$_suffix';
  String get syncKey => 'is_stats_synced_$_suffix';

  bool get isCurrent {
    // Only the login operation that created an unresolved incarnation can
    // identify it. Concurrent session validation must not adopt the old cookie.
    if (_record != null && !isKnown && !_mayIdentify) return false;
    final current = AccountScope.capture(_prefs);
    return current._record == _record &&
        current.userId == userId &&
        current.isGuest == isGuest;
  }

  void check() {
    if (!isCurrent || !isKnown) {
      throw StateError(
        'Account changed or offline account identity is unknown',
      );
    }
  }

  /// The captured owner travels through the existing repository API. The SDK
  /// boundary checks it *after* connectivity awaits, immediately before dispatch.
  T run<T>(T Function() operation) =>
      runZoned(operation, zoneValues: {_zoneKey: this});

  static void checkOperation() {
    (Zone.current[_zoneKey] as AccountScope?)?.check();
  }

  static Future<AccountScope> _write(
    SharedPreferences prefs,
    String state,
    String? userId,
  ) async {
    // Random incarnation prevents ABA even when preferences were cleared.
    final record = jsonEncode({
      'state': state,
      'userId': userId,
      'revision': List.generate(16, (_) => Random.secure().nextInt(256)),
    });
    final scope = AccountScope._(
      prefs,
      record,
      userId,
      state == 'guest',
      state == 'guest',
      true,
    );
    if (!await prefs.setString(storageKey, record)) {
      throw StateError('Could not persist account scope');
    }
    if (scope.isCurrent) _changes.add(prefs);
    return scope;
  }

  static Future<void> _sdkQueue = Future<void>.value();

  /// Serialize session mutations with scoped SDK requests. A login cannot
  /// change credentials while an earlier preference request is dispatching.
  static Future<T> dispatch<T>(Future<T> Function() action) {
    final pending = _sdkQueue.then((_) {
      checkOperation();
      return action();
    });
    _sdkQueue = pending.then((_) {}, onError: (Object _) {});
    return pending;
  }

  // Keep legacy ownership unknown even after its credential flag is cleared.
  // Unlike an active sign-in, this state may be identified by server validation.
  static Future<void> preserveLegacyOwner(SharedPreferences prefs) async {
    if (prefs.getString(storageKey) == null &&
        prefs.getBool('olitun_has_local_session') == true) {
      await _write(prefs, 'unresolved', null);
    }
  }

  static Future<AccountScope> beginSignIn(SharedPreferences prefs) =>
      _write(prefs, 'unknown', null);

  static Future<AccountScope> signOut(SharedPreferences prefs) =>
      _write(prefs, 'guest', null);

  Future<AccountScope> identify(String id) async {
    if (!isCurrent || id.isEmpty) throw StateError('Account changed');
    if (userId == id) return this;
    return _write(_prefs, 'account', id);
  }
}
