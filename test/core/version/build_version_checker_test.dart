// ignore_for_file: deprecated_member_use, unnecessary_lambdas
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/version/build_version_status.dart';
import 'package:itun/core/version/build_version_checker.dart';
import 'package:itun/core/version/build_version_checker_html.dart' as html_impl;
import 'package:itun/core/version/build_version_checker_io.dart' as io_impl;

void main() {
  group('compareSha logic tests', () {
    test('match: identical SHAs', () {
      expect(compareSha('abc1234', 'abc1234'), const BuildVersionMatch());
    });

    test('stale: mismatched SHAs', () {
      expect(
        compareSha('abc1234', 'def5678'),
        const BuildVersionStale('def5678'),
      );
    });

    test('unknown client: unknown', () {
      expect(
        compareSha('unknown', 'abc1234'),
        const BuildVersionUnknown('local-dev'),
      );
    });

    test('unknown client: empty', () {
      expect(compareSha('', 'abc1234'), const BuildVersionUnknown('local-dev'));
    });

    test('unknown client: null', () {
      expect(
        compareSha(null, 'abc1234'),
        const BuildVersionUnknown('local-dev'),
      );
    });

    test('dirty client: tolerated', () {
      expect(
        compareSha('abc1234-dirty', 'abc1234'),
        const BuildVersionUnknown('local-dev'),
      );
    });

    test('null server: malformed', () {
      expect(
        compareSha('abc1234', null),
        const BuildVersionUnknown('malformed-response'),
      );
    });

    test('empty server: malformed', () {
      expect(
        compareSha('abc1234', ''),
        const BuildVersionUnknown('malformed-response'),
      );
    });
  });

  group('buildVersionStatusProvider platform stream tests', () {
    test(
      'io_impl: non-web platforms short-circuit to match immediately',
      () async {
        final container = ProviderContainer(
          overrides: [
            buildVersionStatusProvider.overrideWith(
              (ref) => io_impl.getBuildVersionStream(ref),
            ),
          ],
        );
        addTearDown(container.dispose);

        final status = await container.read(buildVersionStatusProvider.future);
        expect(status, const BuildVersionMatch());
      },
    );

    test('html_impl: successful fetch loops in MockClient environment', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['t'], isNotNull);
        return http.Response(
          json.encode({'sha': 'abc1234', 'builtAt': ''}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final container = ProviderContainer(
          overrides: [
            buildVersionStatusProvider.overrideWith(
              (ref) => html_impl.getBuildVersionStream(ref),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Skip the initial sync placeholder event, wait for the actual async fetch result
        final status = await container
            .read(buildVersionStatusProvider.stream)
            .skip(1)
            .first;
        expect(
          status,
          const BuildVersionUnknown('local-dev'),
        ); // since client is 'unknown' by default
      }, () => mockClient);
    });

    test(
      'html_impl: HTTP 500 error is caught and parsed as unknown fetch-failed',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            'Internal Server Error',
            500,
            headers: {'content-type': 'text/html'},
          );
        });

        await http.runWithClient(() async {
          final container = ProviderContainer(
            overrides: [
              buildVersionStatusProvider.overrideWith(
                (ref) => html_impl.getBuildVersionStream(ref),
              ),
            ],
          );
          addTearDown(container.dispose);

          final status = await container
              .read(buildVersionStatusProvider.stream)
              .skip(1)
              .first;
          expect(status, const BuildVersionUnknown('fetch-failed: 500'));
        }, () => mockClient);
      },
    );

    test(
      'html_impl: Malformed JSON parses unconditionally but handles FormatException safely',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '{invalid-json}',
            200,
            headers: {'content-type': 'text/html'},
          );
        });

        await http.runWithClient(() async {
          final container = ProviderContainer(
            overrides: [
              buildVersionStatusProvider.overrideWith(
                (ref) => html_impl.getBuildVersionStream(ref),
              ),
            ],
          );
          addTearDown(container.dispose);

          final status = await container
              .read(buildVersionStatusProvider.stream)
              .skip(1)
              .first;
          expect(status, const BuildVersionUnknown('parse-failed'));
        }, () => mockClient);
      },
    );
  });
}
