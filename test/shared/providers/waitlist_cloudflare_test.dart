import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/waitlist_provider.dart';
import 'package:mocktail/mocktail.dart';

class _Account extends Mock implements Account {}

class _Jwt extends Mock implements models.Jwt {}

EdgeAuth _edgeAuth({String? jwt}) {
  final account = _Account();
  if (jwt == null) {
    when(account.createJWT).thenThrow(AppwriteException('guest'));
  } else {
    final token = _Jwt();
    when(() => token.jwt).thenReturn(jwt);
    when(account.createJWT).thenAnswer((_) async => token);
  }
  return EdgeAuth(account);
}

WaitlistModel _entry() => WaitlistModel(
  id: '',
  fullName: 'Sona Murmu',
  phoneNumber: '+91 98765 43210',
  ceremonyType: 'karam',
  city: 'Ranchi',
  state: 'Jharkhand',
  submittedAt: '',
  status: 'new',
);

void main() {
  group('WaitlistApi', () {
    test('join posts to the Worker and parses the entry', () async {
      late http.Request sent;
      final api = WaitlistApi(
        edgeAuth: _edgeAuth(jwt: 'jwt-1'),
        httpClient: MockClient((req) async {
          sent = req;
          return http.Response(
            jsonEncode({
              'ok': true,
              'duplicate': false,
              'entry': {
                'id': 'w1',
                'userId': 'u1',
                'fullName': 'Sona Murmu',
                'phoneNumber': '+91 98765 43210',
                'ceremonyType': 'karam',
                'city': 'Ranchi',
                'state': 'Jharkhand',
                'submittedAt': '2026-10-15T00:00:00.000Z',
                'status': 'new',
              },
            }),
            200,
          );
        }),
      );

      final created = await api.join(_entry());

      expect(sent.url.toString(), CloudflareConfig.waitlistEndpoint);
      expect(sent.headers['Authorization'], 'Bearer jwt-1');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body, isNot(contains('userId')));
      expect(body['ceremonyType'], 'karam');
      expect(created.id, 'w1');
      expect(created.status, 'new');
    });

    test('guests can join without a JWT', () async {
      http.Request? sent;
      final api = WaitlistApi(
        edgeAuth: _edgeAuth(),
        httpClient: MockClient((req) async {
          sent = req;
          return http.Response(
            jsonEncode({
              'ok': true,
              'entry': {'id': 'w2', 'fullName': 'Guest'},
            }),
            200,
          );
        }),
      );
      await api.join(_entry());
      expect(sent!.headers.containsKey('Authorization'), isFalse);
    });

    test('validation and rate-limit messages reach the user', () async {
      final api = WaitlistApi(
        edgeAuth: _edgeAuth(),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'ok': false,
              'message': 'Too many waitlist requests. Please try again later.',
            }),
            429,
          ),
        ),
      );
      await expectLater(
        api.join(_entry()),
        throwsA(
          isA<WaitlistSubmissionException>().having(
            (e) => e.message,
            'message',
            contains('Too many'),
          ),
        ),
      );
    });

    test('network failure is reported as unreachable', () async {
      final api = WaitlistApi(
        edgeAuth: _edgeAuth(),
        httpClient: MockClient((_) async => throw http.ClientException('x')),
      );
      await expectLater(
        api.join(_entry()),
        throwsA(isA<WaitlistSubmissionException>()),
      );
    });

    test('mine reads the caller\'s entries from the Worker', () async {
      late http.Request sent;
      final api = WaitlistApi(
        edgeAuth: _edgeAuth(jwt: 'jwt-1'),
        httpClient: MockClient((req) async {
          sent = req;
          return http.Response(
            jsonEncode({
              'ok': true,
              'entries': [
                {'id': 'w1', 'fullName': 'Sona Murmu', 'status': 'new'},
                {'id': 'w0', 'fullName': 'Sona Murmu', 'status': 'contacted'},
              ],
            }),
            200,
          );
        }),
      );

      final entries = await api.mine();

      expect(sent.method, 'GET');
      expect(sent.url.toString(), CloudflareConfig.waitlistMineEndpoint);
      expect(sent.headers['Authorization'], 'Bearer jwt-1');
      expect(entries.map((e) => e.id), ['w1', 'w0']);
    });

    test('mine fails on a non-200 answer', () async {
      final api = WaitlistApi(
        edgeAuth: _edgeAuth(jwt: 'jwt-1'),
        httpClient: MockClient((_) async => http.Response('{"ok":false}', 401)),
      );
      await expectLater(api.mine(), throwsA(isA<http.ClientException>()));
    });
  });
}
