from pathlib import Path


def patch(path, old, new, count=1):
    p = Path(path)
    s = p.read_text()
    assert s.count(old) == count, (path, old, s.count(old))
    p.write_text(s.replace(old, new))


p = 'lib/core/auth/account_scope.dart'
patch(p, '''        guest,
        guest,
      );''', '''        guest,
        guest,
        data['state'] == 'unresolved',
      );''')
patch(p, '  static Future<AccountScope> beginSignIn(SharedPreferences prefs) =>', '''  // Keep legacy ownership unknown even after its credential flag is cleared.
  // Unlike an active sign-in, this state may be identified by server validation.
  static Future<void> preserveLegacyOwner(SharedPreferences prefs) async {
    if (prefs.getString(storageKey) == null &&
        prefs.getBool('olitun_has_local_session') == true) {
      await _write(prefs, 'unresolved', null);
    }
  }

  static Future<AccountScope> beginSignIn(SharedPreferences prefs) =>''')
p = 'lib/core/auth/session_persistence.dart'
patch(p, '''      await clearLocalSessionState(
        client: client,
        prefs: prefs,
        forgetAccount: false,
      );''', '''      await AccountScope.preserveLegacyOwner(prefs);
      await clearLocalSessionState(
        client: client,
        prefs: prefs,
        forgetAccount: false,
      );''')
p = Path('lib/core/auth/appwrite_auth_service.dart')
s = p.read_text()
a, b = s.index('  bool _isWebSessionValid('), s.index('  void _requireCurrent(')
s = s[:a] + s[b:]
a, b = s.index('  Future<void> _restoreWebSession()'), s.index('  Future<void> _clearLocalSessionState(')
s = s[:a] + '''  Future<void> _restoreWebSession() async =>
      _restoreWebSessionFor(await _getPrefs());

  Future<void> _restoreWebSessionFor(SharedPreferences prefs) {
    final scope = AccountScope.capture(prefs);
    if (!scope.isCurrent) return Future<void>.value();
    return AccountScope.dispatch(() async {
      if (!scope.isCurrent) return;
      await SessionPersistence.restoreWebSession(
        client: _client, prefs: prefs, isWeb: _isWeb,
        nowProvider: _nowProvider,
      );
    });
  }

  void restoreWebSessionSync(SharedPreferences prefs) {
    if (!_isWeb) return;
    // Startup remains non-blocking, but credential mutation shares the same
    // queue as logins and progress requests instead of clearing a newer login.
    unawaited(_restoreWebSessionFor(prefs).catchError((Object error) {
      AppLogger.debug('Appwrite: Session restoration failed: ${RedactionHelper.sanitize(error.toString())}');
    }));
  }

''' + s[b:]
p.write_text(s)
p = 'test/core/auth/account_scope_session_test.dart'
patch(p, '''      expect(await service.isLoggedIn(), isFalse);
      expect(AccountScope.capture(prefs).isGuest, isTrue);''', '''      expect(await service.isLoggedIn(), isFalse);
      expect(AccountScope.capture(prefs).userId, 'a');
      expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isFalse);''')
p = Path('test/features/profile/progress_merge_concurrency_test.dart')
p.write_text(p.read_text().replace('when(() => auth.getUserPrefs())', 'when(auth.getUserPrefs)'))
print('Legacy expiry stays unknown; web restoration is fenced against sign-in.')
