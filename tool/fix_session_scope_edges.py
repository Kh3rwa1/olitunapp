from pathlib import Path


def patch(path, old, new, count=1):
    p = Path(path)
    s = p.read_text()
    assert s.count(old) == count, (path, old, s.count(old))
    p.write_text(s.replace(old, new))


p = 'lib/core/auth/appwrite_auth_service.dart'
patch(p, '  Future<void> _clearLocalSessionState() async {', '  Future<void> _clearLocalSessionState({bool preserveAccount = false}) async {')
patch(p, '''    await SessionPersistence.clearLocalSessionState(
      client: _client,
      prefs: prefs,
    );''', '''    await SessionPersistence.clearLocalSessionState(
      client: _client,
      prefs: prefs,
      forgetAccount: !preserveAccount,
    );''')
patch(p, 'unawaited(_clearLocalSessionState());', 'unawaited(_clearLocalSessionState(preserveAccount: true));')
s = Path(p).read_text()
for start, end in [
    ('  Future<bool> isLoggedIn()', '  /// Get current user profile'),
    ('  Future<models.User> getMe()', '  /// Update user display name'),
    ('  Future<void> signOut()', '  /// Permanently delete'),
]:
    a, b = s.index(start), s.index(end)
    part = s[a:b]
    part = part.replace('_clearLocalSessionState()', '_clearLocalSessionState(preserveAccount: true)')
    s = s[:a] + part + s[b:]
Path(p).write_text(s)

p = 'test/core/auth/appwrite_auth_service_test.dart'
patch(p, "import 'dart:async';", "import 'dart:async';\nimport 'package:itun/core/auth/account_scope.dart';")
patch(p, 'void main() {', '''void _bindScopeStorage(MockSharedPreferences prefs) {
  String? record;
  when(() => prefs.setString(AccountScope.storageKey, any())).thenAnswer((call) async {
    record = call.positionalArguments[1] as String;
    return true;
  });
  when(() => prefs.getString(AccountScope.storageKey)).thenAnswer((_) => record);
}

void main() {''')
patch(p, 'when(() => mockPrefs.getString(any())).thenReturn(null);', 'when(() => mockPrefs.getString(any())).thenReturn(null);\n      _bindScopeStorage(mockPrefs);', count=2)

p = 'test/features/profile/progress_merge_concurrency_test.dart'
patch(p, '    auth = _MockAuthRepository();', '''    auth = _MockAuthRepository();
    when(() => auth.getUserPrefs()).thenAnswer((_) async => const Right(<String, dynamic>{}));
    when(() => auth.updateUserPrefs(any())).thenAnswer((_) async => const Right(null));''')
print('Preserved account identity across credential expiry; completed stateful fixtures.')
