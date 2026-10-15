import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/features/admin/presentation/seeding/seeders/seed_existence.dart';

void main() {
  late List<Uri> requested;

  SeedExistenceChecker checker(Map<String, Object> bodies, {int status = 200}) {
    requested = [];
    return SeedExistenceChecker(
      MockClient((request) async {
        requested.add(request.url);
        final body = bodies[request.url.path];
        return http.Response(jsonEncode(body ?? {'ok': false}), status);
      }),
      now: () => DateTime.utc(2026, 10, 15),
    );
  }

  test('lesson ids come from the Worker lessons route', () async {
    final ids = await checker({
      '/api/v1/lessons': {
        'ok': true,
        'lessons': [
          {'id': 'lesson_a'},
          {r'$id': 'lesson_b'},
          {'title': 'no id'},
        ],
      },
    }).lessonIds();

    expect(ids, {'lesson_a', 'lesson_b'});
    expect(requested.single.path, '/api/v1/lessons');
    // Cache-busting so a just-written row is never hidden.
    expect(requested.single.queryParameters.containsKey('fresh'), isTrue);
  });

  test('letters and numbers existence', () async {
    final c = checker({
      '/api/v1/letters': {
        'ok': true,
        'letters': [
          {'id': 'l_la'},
        ],
      },
      '/api/v1/numbers': {'ok': true, 'numbers': []},
    });

    expect(await c.hasLetters(), isTrue);
    expect(await c.hasNumbers(), isFalse);
  });

  test('a failing Worker read throws instead of reporting "empty"', () async {
    // Treating an outage as "no rows" would make the seeder duplicate data.
    await expectLater(
      checker({}, status: 503).hasLetters(),
      throwsA(isA<EdgeApiException>()),
    );
  });
}
