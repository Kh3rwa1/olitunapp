import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/edge_json_client.dart';

void main() {
  final uri = Uri.parse('https://edge.test/api/v1/things');

  test('getList returns the list under the key, dropping non-maps', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'ok': true,
          'things': [
            {'id': 'a'},
            'junk',
            {'id': 'b'},
          ],
        }),
        200,
      ),
    );

    final items = await EdgeJsonClient.getList(client, uri, 'things');
    expect(items.map((e) => e['id']), ['a', 'b']);
  });

  test('getList accepts an empty list', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'ok': true, 'things': []}), 200),
    );

    expect(await EdgeJsonClient.getList(client, uri, 'things'), isEmpty);
  });

  test('getList decodes UTF-8 JSON bodies', () async {
    final client = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'ok': true,
            'things': [
              {'olChiki': 'ᱚ'},
            ],
          }),
        ),
        200,
        headers: const {'content-type': 'application/json'},
      ),
    );

    final items = await EdgeJsonClient.getList(client, uri, 'things');
    expect(items.single['olChiki'], 'ᱚ');
  });

  test('getList throws when the key is missing', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'ok': true}), 200),
    );

    expect(
      EdgeJsonClient.getList(client, uri, 'things'),
      throwsA(isA<EdgeApiException>()),
    );
  });

  test('getJson throws with the status code on non-200', () async {
    final client = MockClient((_) async => http.Response('nope', 503));

    expect(
      EdgeJsonClient.getJson(client, uri),
      throwsA(
        isA<EdgeApiException>().having((e) => e.statusCode, 'status', 503),
      ),
    );
  });

  test('getJson throws when ok is not true or JSON is malformed', () async {
    final notOk = MockClient(
      (_) async => http.Response(jsonEncode({'ok': false}), 200),
    );
    final malformed = MockClient((_) async => http.Response('<html>', 200));

    expect(
      EdgeJsonClient.getJson(notOk, uri),
      throwsA(isA<EdgeApiException>()),
    );
    expect(
      EdgeJsonClient.getJson(malformed, uri),
      throwsA(isA<EdgeApiException>()),
    );
  });

  test('getJson wraps transport errors', () async {
    final client = MockClient((_) async => throw Exception('offline'));

    expect(
      EdgeJsonClient.getJson(client, uri),
      throwsA(isA<EdgeApiException>()),
    );
  });

  test('getJson sends the Accept header plus extra headers', () async {
    late Map<String, String> sent;
    final client = MockClient((request) async {
      sent = request.headers;
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    await EdgeJsonClient.getJson(
      client,
      uri,
      headers: const {'Authorization': 'Bearer t'},
    );
    expect(sent['Accept'], 'application/json');
    expect(sent['Authorization'], 'Bearer t');
  });
}
