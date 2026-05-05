import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/error/exceptions.dart';

void main() {
  group('Failure hierarchy', () {
    test('Failure is sealed — all subtypes are known', () {
      const failures = <Failure>[
        ServerFailure(message: 'server'),
        CacheFailure(message: 'cache'),
        NetworkFailure(),
        AuthFailure(message: 'auth'),
        ValidationFailure(message: 'validation'),
      ];

      for (final f in failures) {
        expect(f, isA<Failure>());
        expect(f.message, isNotEmpty);
      }
    });

    test('ServerFailure preserves code', () {
      const f = ServerFailure(message: 'bad', code: 404);
      expect(f.code, 404);
      expect(f.message, 'bad');
    });

    test('NetworkFailure has default message', () {
      const f = NetworkFailure();
      expect(f.message, 'No internet connection');
      expect(f.code, isNull);
    });

    test('ValidationFailure carries field errors', () {
      const f = ValidationFailure(
        message: 'invalid',
        fieldErrors: {'email': 'required', 'password': 'too short'},
      );
      expect(f.fieldErrors.length, 2);
      expect(f.fieldErrors['email'], 'required');
    });

    test('pattern matching covers all subtypes', () {
      const failure = CacheFailure(message: 'disk full') as Failure;

      final label = switch (failure) {
        ServerFailure() => 'server',
        CacheFailure() => 'cache',
        NetworkFailure() => 'network',
        AuthFailure() => 'auth',
        ValidationFailure() => 'validation',
      };

      expect(label, 'cache');
    });
  });

  group('Exception hierarchy', () {
    test('ServerException carries message and code', () {
      final e = ServerException(message: 'timeout', code: 408);
      expect(e.message, 'timeout');
      expect(e.code, 408);
      expect(e, isA<Exception>());
    });

    test('CacheException carries message', () {
      final e = CacheException(message: 'corrupted');
      expect(e.message, 'corrupted');
    });

    test('AuthException carries message', () {
      final e = AuthException(message: 'expired');
      expect(e.message, 'expired');
    });

    test('NetworkException carries message', () {
      final e = NetworkException(message: 'offline');
      expect(e.message, 'offline');
    });
  });
}
