import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:itun/features/auth/data/models/user_model.dart';
import 'package:itun/features/auth/data/repositories/auth_repository_impl.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

void main() {
  late _MockRemote remote;
  late _MockNetwork network;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    network = _MockNetwork();
    repo = AuthRepositoryImpl(remoteDataSource: remote, networkInfo: network);
  });

  const user = UserModel(
    id: 'u1',
    email: 'a@b.co',
    name: 'A',
    isEmailVerified: true,
  );

  group('signInWithEmail', () {
    test('returns NetworkFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result =
          await repo.signInWithEmail(email: 'a@b.co', password: 'pwpwpwpw');

      expect(result, isA<Left<Failure, dynamic>>());
      result.match(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
      verifyNever(() => remote.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('returns Right(UserEntity) on success', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => user);

      final result =
          await repo.signInWithEmail(email: 'a@b.co', password: 'pwpwpwpw');

      expect(result.isRight(), true);
      result.match(
        (_) => fail('expected Right'),
        (e) {
          expect(e.id, 'u1');
          expect(e.email, 'a@b.co');
        },
      );
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(ServerException(message: 'bad creds', code: 401));

      final result =
          await repo.signInWithEmail(email: 'a@b.co', password: 'pwpwpwpw');

      result.match(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, 'bad creds');
          expect(f.code, 401);
        },
        (_) => fail('expected Left'),
      );
    });
  });

  group('signOut', () {
    test('returns NetworkFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      final result = await repo.signOut();
      result.match(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns Right(null) on success', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.signOut()).thenAnswer((_) async {});
      final result = await repo.signOut();
      expect(result.isRight(), true);
    });
  });

  group('getCurrentUser', () {
    test('returns Right(null) when remote returns null (no session)', () async {
      when(() => remote.getCurrentUser()).thenAnswer((_) async => null);
      final result = await repo.getCurrentUser();
      result.match(
        (_) => fail('expected Right'),
        (u) => expect(u, isNull),
      );
    });
  });
}
