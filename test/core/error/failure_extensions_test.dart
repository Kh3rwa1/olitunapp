import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/error/failure_extensions.dart';
import 'package:itun/core/error/failures.dart';

void main() {
  group('FailureToUiMessage.toUiMessage', () {
    test('empty message maps to the generic retry copy', () {
      expect(
        const ServerFailure(message: '').toUiMessage(),
        'Something went wrong. Please try again.',
      );
    });

    test('socket exceptions map to the offline copy', () {
      expect(
        const NetworkFailure(
          message: 'SocketException: Connection closed',
        ).toUiMessage(),
        'No internet connection. Check your network and retry.',
      );
      expect(
        const NetworkFailure(message: 'No internet available').toUiMessage(),
        'No internet connection. Check your network and retry.',
      );
    });

    test('401/Unauthorized maps to the re-auth copy', () {
      expect(
        const AuthFailure(message: '401 Unauthorized').toUiMessage(),
        'Please sign in again to continue.',
      );
    });

    test('404 maps to the not-found copy', () {
      expect(
        const ServerFailure(message: '404 not found').toUiMessage(),
        'This content was not found.',
      );
    });

    test('TracingRequired maps to the tracing copy', () {
      expect(
        const ValidationFailure(
          message: 'TracingRequired for letter',
        ).toUiMessage(),
        'Tracing data is required for letters and numbers.',
      );
    });

    test('any other message is passed through verbatim', () {
      expect(
        const ServerFailure(message: 'Quiz unavailable').toUiMessage(),
        'Quiz unavailable',
      );
    });

    test('overlong messages are truncated to 140 chars with an ellipsis', () {
      final long = 'x' * 200;
      final ui = ServerFailure(message: long).toUiMessage();
      expect(ui.length, 141); // 140 chars + ellipsis
      expect(ui.endsWith('…'), isTrue);
    });

    test('messages at the 140-char boundary are not truncated', () {
      final boundary = 'y' * 140;
      expect(ServerFailure(message: boundary).toUiMessage(), boundary);
    });
  });
}
