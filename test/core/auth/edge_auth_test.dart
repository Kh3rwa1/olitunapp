import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockAccount extends Mock implements Account {}

void main() {
  late MockAccount account;
  late DateTime now;
  late EdgeAuth edgeAuth;
  var issued = 0;

  setUp(() {
    account = MockAccount();
    now = DateTime(2026, 10, 15, 12);
    issued = 0;
    when(
      () => account.createJWT(),
    ).thenAnswer((_) async => models.Jwt(jwt: 'jwt-${++issued}'));
    edgeAuth = EdgeAuth(account, now: () => now);
  });

  test('attaches the session JWT as a bearer token', () async {
    expect(await edgeAuth.headers(), {'Authorization': 'Bearer jwt-1'});
  });

  test('reuses the cached JWT until it nears expiry', () async {
    await edgeAuth.token();
    now = now.add(const Duration(minutes: 9));
    expect(await edgeAuth.token(), 'jwt-1');
    verify(() => account.createJWT()).called(1);

    now = now.add(const Duration(minutes: 2));
    expect(await edgeAuth.token(), 'jwt-2');
  });

  test('concurrent callers share one JWT request', () async {
    final tokens = await Future.wait([
      edgeAuth.token(),
      edgeAuth.token(),
      edgeAuth.token(),
    ]);
    expect(tokens, everyElement('jwt-1'));
    verify(() => account.createJWT()).called(1);
  });

  test('clear forces a fresh JWT', () async {
    await edgeAuth.token();
    edgeAuth.clear();
    expect(await edgeAuth.token(), 'jwt-2');
  });

  test('sends no Authorization header when there is no session', () async {
    when(
      () => account.createJWT(),
    ).thenThrow(AppwriteException('missing scope', 401));
    expect(await edgeAuth.headers(), isEmpty);
  });
}
