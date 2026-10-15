import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/api/edge_json_client.dart';
import '../../../../../core/config/cloudflare_config.dart';

/// Existence checks for the content seeders, read from the Worker's learner
/// list routes (D1) instead of Appwrite. Each read carries a unique query
/// parameter so a cached response can never hide rows the seeder just wrote.
class SeedExistenceChecker {
  SeedExistenceChecker(this._http, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final http.Client _http;
  final DateTime Function() _now;

  Future<List<Map<String, dynamic>>> _rows(String endpoint, String key) {
    final uri = Uri.parse(
      endpoint,
    ).replace(queryParameters: {'fresh': '${_now().microsecondsSinceEpoch}'});
    return EdgeJsonClient.getList(_http, uri, key);
  }

  static Set<String> _ids(List<Map<String, dynamic>> rows) => {
    for (final row in rows)
      if ((row['id'] ?? row[r'$id']) case final String id when id.isNotEmpty)
        id,
  };

  /// Ids of every lesson in D1.
  Future<Set<String>> lessonIds() async =>
      _ids(await _rows(CloudflareConfig.lessonsEndpoint, 'lessons'));

  Future<bool> hasLetters() async =>
      (await _rows(CloudflareConfig.lettersEndpoint, 'letters')).isNotEmpty;

  Future<bool> hasNumbers() async =>
      (await _rows(CloudflareConfig.numbersEndpoint, 'numbers')).isNotEmpty;
}

final seedExistenceCheckerProvider = Provider<SeedExistenceChecker>(
  (ref) => SeedExistenceChecker(ref.watch(edgeHttpClientProvider)),
);
