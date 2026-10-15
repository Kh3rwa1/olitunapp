import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_dashboard_api.dart';
import 'package:itun/core/api/admin_edge_client.dart';
import 'package:itun/core/api/admin_purchases_api.dart';
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/features/admin/domain/admin_failure.dart';
import 'package:mocktail/mocktail.dart';

class _Account extends Mock implements Account {}

EdgeAuth _edgeAuth() {
  final account = _Account();
  var n = 0;
  when(
    account.createJWT,
  ).thenAnswer((_) async => models.Jwt(jwt: 'admin-jwt-${++n}'));
  return EdgeAuth(account);
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  group('AdminEdgeClient', () {
    test('sends the admin JWT and retries a 401 once with a new one', () async {
      final auth = <String?>[];
      final statuses = [401, 200];
      final client = AdminEdgeClient(
        edgeAuth: _edgeAuth(),
        httpClient: MockClient((request) async {
          auth.add(request.headers['Authorization']);
          return _json({'ok': true}, statuses.removeAt(0));
        }),
      );

      final body = await client.getOk(AdminEdgeClient.adminUri('purchases'));

      expect(body['ok'], isTrue);
      expect(auth, ['Bearer admin-jwt-1', 'Bearer admin-jwt-2']);
    });

    test('getOk throws the Worker status and message', () async {
      final client = AdminEdgeClient(
        edgeAuth: _edgeAuth(),
        httpClient: MockClient(
          (_) async =>
              _json({'ok': false, 'message': 'Admin access required'}, 403),
        ),
      );

      await expectLater(
        client.getOk(AdminEdgeClient.adminUri('purchases')),
        throwsA(
          isA<EdgeApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Admin access required'),
        ),
      );
    });

    test('send returns non-2xx responses without throwing', () async {
      final client = AdminEdgeClient(
        edgeAuth: _edgeAuth(),
        httpClient: MockClient(
          (request) async =>
              _json({'success': false, 'echo': jsonDecode(request.body)}, 409),
        ),
      );

      final res = await client.send(
        'POST',
        AdminEdgeClient.adminUri('maintenance'),
        body: {'action': 'x'},
      );

      expect(res.statusCode, 409);
      expect(res.body!['echo'], {'action': 'x'});
    });

    test('transport failure is an EdgeApiException without status', () async {
      final client = AdminEdgeClient(
        edgeAuth: _edgeAuth(),
        httpClient: MockClient((_) async => throw Exception('offline')),
      );

      await expectLater(
        client.getOk(AdminEdgeClient.adminUri('purchases')),
        throwsA(
          isA<EdgeApiException>().having((e) => e.statusCode, 'status', null),
        ),
      );
    });
  });

  group('AdminFailure from Worker errors', () {
    test('maps statuses like Appwrite codes', () {
      expect(
        AdminFailure.fromException(
          const EdgeApiException('x', statusCode: 403),
        ),
        isA<AdminPermissionFailure>(),
      );
      expect(
        AdminFailure.fromException(
          const EdgeApiException('x', statusCode: 404),
        ),
        isA<AdminNotFoundFailure>(),
      );
      expect(
        AdminFailure.fromException(const EdgeApiException('offline')),
        isA<AdminNetworkFailure>(),
      );
    });
  });

  group('AdminPurchasesApi', () {
    test('lists one page with filters and the server cursor', () async {
      late Uri requested;
      final api = AdminPurchasesApi(
        AdminEdgeClient(
          edgeAuth: _edgeAuth(),
          httpClient: MockClient((request) async {
            requested = request.url;
            return _json({
              'ok': true,
              'purchases': [
                {'id': 'p1', 'status': 'verified', 'paidAmount': 199},
              ],
              'hasMore': true,
              'nextCursor': '2026-10-15T01:00:00.000Z|p1',
            });
          }),
        ),
      );

      final page = await api.list(
        filter: 'razorpay',
        search: 'cat',
        cursor: 'c0',
      );

      expect(
        requested.toString().startsWith(
          '${CloudflareConfig.baseUrl}/api/v1/admin/purchases?',
        ),
        isTrue,
      );
      expect(requested.queryParameters, {
        'filter': 'razorpay',
        'limit': '50',
        'search': 'cat',
        'cursor': 'c0',
      });
      expect(page.items.single['id'], 'p1');
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, '2026-10-15T01:00:00.000Z|p1');
    });

    test('export uses the export route and omits empty params', () async {
      late Uri requested;
      final api = AdminPurchasesApi(
        AdminEdgeClient(
          edgeAuth: _edgeAuth(),
          httpClient: MockClient((request) async {
            requested = request.url;
            return _json({'ok': true, 'purchases': [], 'hasMore': false});
          }),
        ),
      );

      final page = await api.list(filter: 'all', limit: 500, export: true);

      expect(requested.path, '/api/v1/admin/purchases/export');
      expect(requested.queryParameters, {'filter': 'all', 'limit': '500'});
      expect(page.nextCursor, isNull);
    });
  });

  group('AdminDashboardApi', () {
    AdminDashboardApi apiFor(Map<String, Object> routes) => AdminDashboardApi(
      AdminEdgeClient(
        edgeAuth: _edgeAuth(),
        httpClient: MockClient((request) async {
          final body = routes[request.url.path];
          return body == null ? _json({'ok': false}, 404) : _json(body);
        }),
      ),
    );

    test('recent activity is grouped by table', () async {
      final api = apiFor({
        '/api/v1/admin/dashboard/activity': {
          'ok': true,
          'collections': {
            'words': [
              {'id': 'w1', r'$createdAt': '2026-10-15T00:00:00Z'},
            ],
            'lessons': [],
          },
        },
      });

      final activity = await api.recentActivity();

      expect(activity['words']!.single['id'], 'w1');
      expect(activity['lessons'], isEmpty);
    });

    test('analytics passes the date range and reads truncation', () async {
      late Uri requested;
      final api = AdminDashboardApi(
        AdminEdgeClient(
          edgeAuth: _edgeAuth(),
          httpClient: MockClient((request) async {
            requested = request.url;
            return _json({
              'ok': true,
              'rollups': [
                {'dateKey': '2026-10-15', 'eventName': 'x', 'totalEvents': 2},
              ],
              'events': [
                {'dateKey': '2026-10-15', 'userId': 'u1'},
              ],
              'eventsTruncated': true,
            });
          }),
        ),
      );

      final data = await api.analytics(
        startKey: '2026-10-01',
        endKey: '2026-10-15',
      );

      expect(requested.path, '/api/v1/admin/analytics/snapshot');
      expect(requested.queryParameters, {
        'start': '2026-10-01',
        'end': '2026-10-15',
      });
      expect(data.rollups.single['totalEvents'], 2);
      expect(data.events.single['userId'], 'u1');
      expect(data.eventsTruncated, isTrue);
    });

    test('gamification metrics and schema health', () async {
      final api = apiFor({
        '/api/v1/admin/gamification/metrics': {
          'ok': true,
          'metrics': {'lessonsCompleted': 4, 'bad': 'x'},
        },
        '/api/v1/admin/health/schema': {
          'ok': true,
          'tables': {'user_badges': true, 'refund_claims': false},
        },
      });

      expect(await api.gamificationMetrics(), {'lessonsCompleted': 4});
      expect(await api.schemaHealth(), {
        'user_badges': true,
        'refund_claims': false,
      });
    });

    test('a 403 surfaces as an EdgeApiException', () async {
      final api = AdminDashboardApi(
        AdminEdgeClient(
          edgeAuth: _edgeAuth(),
          httpClient: MockClient((_) async => _json({'ok': false}, 403)),
        ),
      );

      await expectLater(
        api.gamificationMetrics(),
        throwsA(isA<EdgeApiException>()),
      );
    });
  });
}
