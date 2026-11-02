import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:itun/core/auth/worker_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the Worker's `/api/v1/auth` routes.
class FakeAuthWorker {
  FakeAuthWorker() {
    api = WorkerAuthApi(
      client: http_testing.MockClient(_handle),
      baseUrl: 'https://worker.test',
    );
  }

  late final WorkerAuthApi api;
  final List<http.Request> calls = [];
  final Map<String, FutureOr<http.Response> Function(http.Request)> _routes =
      {};

  /// Answers `METHOD /path` (path after /api/v1/auth) with [handler].
  void on(
    String method,
    String path,
    FutureOr<http.Response> Function(http.Request request) handler,
  ) {
    _routes['$method $path'] = handler;
  }

  /// Makes every request fail like a dropped connection.
  bool offline = false;

  List<http.Request> callsTo(String path) =>
      calls.where((r) => r.url.path == '/api/v1/auth$path').toList();

  Future<http.Response> _handle(http.Request request) async {
    if (offline) throw http.ClientException('offline');
    calls.add(request);
    final path = request.url.path.replaceFirst('/api/v1/auth', '');
    final handler = _routes['${request.method} $path'];
    if (handler == null) {
      return json({'ok': false, 'error': 'NOT_FOUND'}, 404);
    }
    return await handler(request);
  }

  static http.Response json(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  /// A Worker session response for [userId].
  static Map<String, dynamic> session(
    String userId, {
    String email = '',
    String name = '',
    bool guest = false,
    String access = 'access-1',
    String refresh = 'sid.refresh',
    DateTime? expiresAt,
  }) => {
    'ok': true,
    'accessToken': access,
    'accessTokenExpiresAt':
        (expiresAt ?? DateTime.now().add(const Duration(hours: 1)))
            .toUtc()
            .toIso8601String(),
    'refreshToken': refresh,
    'user': {
      'id': userId,
      'email': email,
      'name': name,
      'emailVerified': email.isNotEmpty,
      'isGuest': guest,
      'createdAt': '2026-11-01T00:00:00.000Z',
      'updatedAt': '2026-11-01T00:00:00.000Z',
    },
  };

  /// A [WorkerAuth] wired to this fake and [prefs].
  WorkerAuth auth(
    SharedPreferences prefs, {
    String? legacySecret,
    DateTime Function()? now,
    bool isWeb = false,
    void Function()? onLegacyCleared,
  }) => WorkerAuth(
    api: api,
    prefs: () async => prefs,
    now: now,
    readLegacySession: () async => legacySecret,
    clearLegacySession: () async => onLegacyCleared?.call(),
    isWeb: isWeb,
  );
}
