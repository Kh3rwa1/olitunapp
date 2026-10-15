import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_content_client.dart';

/// In-memory stand-in for the Worker admin routes
/// (`/api/v1/admin/content/:table/:id`, `/api/v1/admin/settings/:key`).
///
/// Records every request so tests can assert method, URL, JWT and body, and
/// can be switched to fail every request with [failStatus] or
/// [transportError].
class FakeAdminWorker {
  static const String jwt = 'test-admin-jwt';

  final Map<String, Map<String, Map<String, dynamic>>> rows = {};
  final Map<String, String> settings = {};
  final List<http.Request> requests = [];

  int? failStatus;
  String failMessage = 'Worker failure';

  /// When set, every request fails in transport (e.g. a SocketException).
  Object? transportError;

  late final MockClient client = MockClient((request) async {
    requests.add(request);
    final error = transportError;
    if (error != null) throw error;
    return _handle(request);
  });

  AdminContentClient get adminClient =>
      AdminContentClient(client, authHeaders: () async => _authHeader);

  static const Map<String, String> _authHeader = {
    'Authorization': 'Bearer $jwt',
  };

  List<http.Request> requestsWith(String method) =>
      requests.where((r) => r.method == method).toList();

  Map<String, dynamic> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, dynamic>;

  http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: const {'content-type': 'application/json'},
  );

  http.Response _handle(http.Request request) {
    if (request.headers['Authorization'] != 'Bearer $jwt') {
      return _json({'ok': false, 'message': 'Unauthenticated'}, 401);
    }
    final status = failStatus;
    if (status != null) {
      return _json({'ok': false, 'message': failMessage}, status);
    }

    final segments = request.url.pathSegments;
    // api, v1, admin, <content|settings>, ...
    if (segments.length < 4 || segments[2] != 'admin') {
      return _json({'ok': false}, 404);
    }
    return segments[3] == 'settings'
        ? _settings(request, segments.length > 4 ? segments[4] : null)
        : _content(
            request,
            segments[4],
            segments.length > 5 ? segments[5] : null,
          );
  }

  http.Response _content(http.Request request, String table, String? id) {
    final tableRows = rows.putIfAbsent(table, () => {});
    if (id == null) {
      return _json({'ok': true, 'items': tableRows.values.toList()});
    }
    switch (request.method) {
      case 'GET':
        final row = tableRows[id];
        return row == null
            ? _json({'ok': false, 'message': 'Row not found'}, 404)
            : _json({'ok': true, 'item': row});
      case 'PUT':
        final doc = {...?tableRows[id], ...bodyOf(request), 'id': id};
        tableRows[id] = doc;
        return _json({'ok': true, 'item': doc});
      case 'DELETE':
        return tableRows.remove(id) == null
            ? _json({'ok': false, 'message': 'Row not found'}, 404)
            : _json({'ok': true, 'deleted': true});
    }
    return _json({'ok': false}, 405);
  }

  http.Response _settings(http.Request request, String? key) {
    if (key == null) {
      return _json({
        'ok': true,
        'documents': [
          for (final e in settings.entries)
            {'id': e.key, 'settingKey': e.key, 'settingValue': e.value},
        ],
      });
    }
    switch (request.method) {
      case 'PUT':
        settings[key] = bodyOf(request)['settingValue'] as String;
        return _json({'ok': true, 'key': key});
      case 'DELETE':
        return settings.remove(key) == null
            ? _json({'ok': false, 'message': 'Setting not found'}, 404)
            : _json({'ok': true, 'deleted': true});
    }
    return _json({'ok': false}, 405);
  }
}
