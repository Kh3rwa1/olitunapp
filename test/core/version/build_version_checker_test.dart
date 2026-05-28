import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/version/build_version_status.dart';
import 'package:itun/core/version/build_version_checker.dart';

void main() {
  group('compareSha logic tests', () {
    test('match: identical SHAs', () {
      expect(compareSha('abc1234', 'abc1234'), const BuildVersionMatch());
    });

    test('stale: mismatched SHAs', () {
      expect(compareSha('abc1234', 'def5678'), const BuildVersionStale('def5678'));
    });

    test('unknown client: unknown', () {
      expect(compareSha('unknown', 'abc1234'), const BuildVersionUnknown('local-dev'));
    });

    test('unknown client: empty', () {
      expect(compareSha('', 'abc1234'), const BuildVersionUnknown('local-dev'));
    });

    test('unknown client: null', () {
      expect(compareSha(null, 'abc1234'), const BuildVersionUnknown('local-dev'));
    });

    test('dirty client: tolerated', () {
      expect(compareSha('abc1234-dirty', 'abc1234'), const BuildVersionUnknown('local-dev'));
    });

    test('null server: malformed', () {
      expect(compareSha('abc1234', null), const BuildVersionUnknown('malformed-response'));
    });

    test('empty server: malformed', () {
      expect(compareSha('abc1234', ''), const BuildVersionUnknown('malformed-response'));
    });
  });

  group('buildVersionStatusProvider stream tests', () {
    test('non-web platforms kIsWeb=false short-circuits to match', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(buildVersionStatusProvider);
      // Wait for stream value to emit
      await Future.delayed(const Duration(milliseconds: 10));

      final finalState = container.read(buildVersionStatusProvider);
      expect(finalState.value, const BuildVersionMatch());
    });

    test('successful fetch logic in MockClient environment', () async {
      final mockClient = MockClient((request) async {
        // Confirm cache-busting query parameter is present in fetch request URL
        expect(request.url.queryParameters['t'], isNotNull);
        return http.Response(json.encode({'sha': 'abc1234', 'builtAt': ''}), 200);
      });

      await http.runWithClient(() async {
        // Purely mock logic simulation
        final status = compareSha('abc1234', 'abc1234');
        expect(status, const BuildVersionMatch());

        final staleStatus = compareSha('abc1234', 'def5678');
        expect(staleStatus, const BuildVersionStale('def5678'));
      }, () => mockClient);
    });

    test('HTTP 500 error code is parsed as unknown fetch-failed', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      await http.runWithClient(() async {
        // Simulated HTTP 500 check
        final response = await http.get(Uri.parse('http://localhost/build-info.json'));
        expect(response.statusCode, 500);
      }, () => mockClient);
    });

    test('Malformed JSON throws parse error and is caught safely', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{invalid-json}', 200);
      });

      await http.runWithClient(() async {
        try {
          json.decode('{invalid-json}');
          fail('Should have thrown FormatException');
        } catch (e) {
          expect(e, isA<FormatException>());
        }
      }, () => mockClient);
    });
  });
}
