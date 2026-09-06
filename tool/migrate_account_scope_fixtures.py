from pathlib import Path


def patch(path, old, new, count=1):
    p = Path(path)
    source = p.read_text()
    assert source.count(old) == count, (path, old, source.count(old))
    p.write_text(source.replace(old, new))

p = 'test/features/profile/progress_merge_concurrency_test.dart'
patch(p, "import 'dart:convert';", "import 'dart:convert';\nimport 'package:itun/core/auth/account_scope.dart';")
patch(p, '    prefs = await SharedPreferences.getInstance();', "    prefs = await SharedPreferences.getInstance();\n    await (await AccountScope.beginSignIn(prefs)).identify('test_user');")
# The server preferences field stays user_progress_data: it is scoped by the
# authenticated account. Only LOCAL ownership needs an explicit test identity.
source = Path(p).read_text()
for name in ['prefsA', 'prefsB']:
    old = f'final {name} = await SharedPreferences.getInstance();'
    assert old in source
    source = source.replace(old, old + f"\n        await (await AccountScope.beginSignIn({name})).identify('test_user');")
Path(p).write_text(source)
patch(p, '        // 1. User Alice logs in and saves stats', "        await (await AccountScope.beginSignIn(prefs)).identify(userAlice.id);\n        // 1. User Alice logs in and saves stats")
patch(p, '        // 2. User Bob logs in on the same device', "        await (await AccountScope.beginSignIn(prefs)).identify(userBob.id);\n        // 2. User Bob logs in on the same device")
patch(p, "    test('Guest user uses isolated user_stats_guest storage', () async {", "    test('Guest user uses isolated user_stats_guest storage', () async {\n      await AccountScope.signOut(prefs);")

p = 'test/core/auth/appwrite_auth_service_test.dart'
# Existing successful session fixtures must now include the SDK's required
# account identity. Keep their cleanup/failure expectations unchanged.
patch(p, 'class MockSession extends Mock implements models.Session {}', """class MockSession extends Mock implements models.Session {
  MockSession() {
    when(() => userId).thenReturn('test_user_id');
  }
}""")
patch(p, 'class MockSharedPreferences extends Mock implements SharedPreferences {}', """class MockSharedPreferences extends Mock implements SharedPreferences {
  MockSharedPreferences() {
    when(() => setString(any(), any())).thenAnswer((_) async => true);
  }
}""")
p = 'lib/features/profile/presentation/providers/user_stats_provider.dart'
patch(p, '      if (_disposed || !scope.isCurrent || _stateScope?.isCurrent != true) return;', '      if (_disposed || !scope.isCurrent || _stateScope?.isCurrent != true) {\n        return;\n      }')
print('Bound test owners explicitly without changing CRDT assertions.')
