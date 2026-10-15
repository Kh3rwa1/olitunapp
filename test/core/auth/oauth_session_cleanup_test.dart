import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/oauth_session_cleanup.dart';
import 'package:mocktail/mocktail.dart';

class _Account extends Mock implements Account {}

class _User extends Mock implements models.User {}

models.User _user(String email) {
  final u = _User();
  when(() => u.email).thenReturn(email);
  return u;
}

AppwriteException _signedOut() => AppwriteException(
  'missing scope (account)',
  401,
  'general_unauthorized_scope',
);

void main() {
  late _Account account;

  setUp(() {
    account = _Account();
    when(() => account.deleteSessions()).thenAnswer((_) async {});
    when(
      () => account.deleteSession(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async {});
  });

  void signedInAs(List<Object> sequence) {
    final answers = List<Object>.of(sequence);
    when(() => account.get()).thenAnswer((_) async {
      final next = answers.length > 1 ? answers.removeAt(0) : answers.first;
      if (next is AppwriteException) throw next;
      return next as models.User;
    });
  }

  test('nobody signed in: nothing is deleted', () async {
    signedInAs([_signedOut()]);

    expect(await clearSessionsBeforeOAuth(account), isTrue);
    verifyNever(() => account.deleteSessions());
    verifyNever(
      () => account.deleteSession(sessionId: any(named: 'sessionId')),
    );
  });

  test('leftover guest session: all guest sessions are removed', () async {
    signedInAs([_user(''), _signedOut()]);

    expect(await clearSessionsBeforeOAuth(account), isTrue);
    verify(() => account.deleteSessions()).called(1);
  });

  test('real account: only this device is signed out', () async {
    signedInAs([_user('learner@example.com'), _signedOut()]);

    expect(await clearSessionsBeforeOAuth(account), isTrue);
    verify(() => account.deleteSession(sessionId: 'current')).called(1);
    verifyNever(() => account.deleteSessions());
  });

  test('a failing web-session restore never skips the deletion', () async {
    signedInAs([_user(''), _signedOut()]);

    final cleared = await clearSessionsBeforeOAuth(
      account,
      restoreWebSession: () async => throw StateError('restore failed'),
    );

    expect(cleared, isTrue);
    verify(() => account.deleteSessions()).called(1);
  });

  test('a guest session that survives the first delete is retried', () async {
    signedInAs([_user(''), _user(''), _signedOut()]);

    expect(await clearSessionsBeforeOAuth(account), isTrue);
    verify(() => account.deleteSessions()).called(2);
  });

  test('reports false when a real session cannot be removed', () async {
    when(
      () => account.deleteSession(sessionId: any(named: 'sessionId')),
    ).thenThrow(AppwriteException('server error', 500));
    signedInAs([_user('learner@example.com')]);

    expect(await clearSessionsBeforeOAuth(account), isFalse);
    verifyNever(() => account.deleteSessions());
  });
}
