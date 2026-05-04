import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/error/failures.dart';

void main() {
  group('Failure types', () {
    test('ServerFailure carries message and code', () {
      const failure = ServerFailure(message: 'Internal error', code: 500);
      expect(failure.message, 'Internal error');
      expect(failure.code, 500);
    });

    test('NetworkFailure has default message', () {
      const failure = NetworkFailure();
      expect(failure.message, 'No internet connection');
      expect(failure.code, isNull);
    });

    test('CacheFailure carries message', () {
      const failure = CacheFailure(message: 'Not found');
      expect(failure.message, 'Not found');
    });

    test('AuthFailure carries message', () {
      const failure = AuthFailure(message: 'Unauthorized');
      expect(failure.message, 'Unauthorized');
    });

    test('ValidationFailure carries fieldErrors', () {
      const failure = ValidationFailure(
        message: 'Invalid input',
        fieldErrors: {'email': 'Required', 'password': 'Too short'},
      );
      expect(failure.fieldErrors.length, 2);
      expect(failure.fieldErrors['email'], 'Required');
    });

    test('ValidationFailure defaults to empty fieldErrors', () {
      const failure = ValidationFailure(message: 'Bad request');
      expect(failure.fieldErrors, isEmpty);
    });

    test('all failure types are subtypes of Failure', () {
      const failures = <Failure>[
        ServerFailure(message: 'err'),
        CacheFailure(message: 'err'),
        NetworkFailure(),
        AuthFailure(message: 'err'),
        ValidationFailure(message: 'err'),
      ];
      expect(failures.length, 5);
    });
  });
}
