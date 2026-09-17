// Standalone live e2e for the deployed aiStudio function — plain dart:io,
// no Flutter test binding (which blocks real HTTP).
//
//   dart run tool/ai_studio_live_e2e.dart
//
// Prints cookie NAMES and the short-lived JWT (15-min expiry, throwaway
// test account) for debugging; never prints the session secret or password.
import 'dart:convert';
import 'dart:io';

const endpoint = 'https://sgp.cloud.appwrite.io/v1';
const projectId = '699495910038e39622c5';
const email = 'studio-e2e-tester@olitun-test.dev';
const password = 'E2eTestPass!2026x';

Future<(int, String, HttpClientResponse)> _call(
  String method,
  String path, {
  Map<String, String> headers = const {},
  Map<String, dynamic>? json,
}) async {
  final client = HttpClient();
  final request = await client.openUrl(method, Uri.parse('$endpoint$path'));
  request.headers.set('X-Appwrite-Project', projectId);
  headers.forEach(request.headers.set);
  if (json != null) {
    request.headers.set('Content-Type', 'application/json; charset=utf-8');
    request.add(utf8.encode(jsonEncode(json)));
  }
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  return (response.statusCode, body, response);
}

Future<void> main() async {
  // 1) Login — capture the real set-cookie headers.
  final (loginStatus, loginBody, loginResponse) = await _call(
    'POST',
    '/account/sessions/email',
    json: {'email': email, 'password': password},
  );
  stdout.writeln('login status: $loginStatus');
  if (loginStatus != 201) {
    stdout.writeln(loginBody.substring(0, loginBody.length.clamp(0, 300)));
    exit(1);
  }
  final setCookies = loginResponse.headers['set-cookie'] ?? const [];
  final cookieHeader = setCookies.map((c) => c.split(';').first).join('; ');
  for (final c in setCookies) {
    stdout.writeln('set-cookie name: ${c.split(';').first.split('=').first}');
  }
  final stale = File('/tmp/olitun-cookie');
  if (stale.existsSync()) {
    final staleCookie = stale.readAsStringSync();
    stdout.writeln(
      'stale manual cookie name: ${staleCookie.split('=').first} '
      '(correct prefix is a_session_699495910038e39622c5)',
    );
  }

  // 2) JWT via POST /account/jwts with the real cookie.
  final (jwtStatus, jwtBody, _) = await _call(
    'POST',
    '/account/jwts',
    headers: {'Cookie': cookieHeader},
    json: {},
  );
  stdout.writeln('jwt status: $jwtStatus');
  if (jwtStatus != 201) {
    stdout.writeln(jwtBody.substring(0, jwtBody.length.clamp(0, 300)));
    exit(1);
  }
  final jwt = (jsonDecode(jwtBody) as Map)['jwt'] as String;
  stdout.writeln('jwt length: ${jwt.length}');

  // 3) Execute the deployed function exactly as the app transport does.
  final (execStatus, execBody, _) = await _call(
    'POST',
    '/functions/aiStudio/executions',
    headers: {'Cookie': cookieHeader, 'Authorization': 'Bearer $jwt'},
    json: {
      'body': jsonEncode({
        'action': 'translate',
        'text': 'नमस्ते, आप कैसे हैं?',
        'language': 'hi-IN',
      }),
      'async': false,
    },
  );
  stdout.writeln('execution http: $execStatus');
  if (execStatus != 201) {
    stdout.writeln(execBody.substring(0, execBody.length.clamp(0, 300)));
    exit(1);
  }
  final exec = jsonDecode(execBody) as Map;
  stdout.writeln('execution status: ${exec['status']}');
  stdout.writeln('response http: ${exec['responseStatusCode']}');
  final inner = jsonDecode(exec['responseBody'] as String) as Map;
  if (inner['success'] == true) {
    final data = inner['data'] as Map;
    final text = data['text'] as String;
    final hasOlChiki = text.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F);
    stdout.writeln('language: ${data['language']} | cached: ${data['cached']}');
    stdout.writeln('santali text: $text');
    stdout.writeln('ol-chiki script detected: $hasOlChiki');
    exit(hasOlChiki ? 0 : 1);
  } else {
    stdout.writeln('error: ${inner['error']} | ${inner['message']}');
    exit(1);
  }
}
