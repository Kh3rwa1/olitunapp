import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/cloudflare_config.dart';
import 'edge_json_client.dart';

/// One row of the Worker content change feed.
class ContentChange {
  const ContentChange({
    required this.seq,
    required this.table,
    required this.rowId,
    required this.op,
  });

  final int seq;

  /// D1 table name (`words`, `lessons`, `categories`, ...).
  final String table;

  /// Changed row id; `*` for bulk changes (restore, wipe).
  final String rowId;
  final String op;

  bool get isBulk => rowId.isEmpty || rowId == '*';

  static ContentChange? fromJson(Map<String, dynamic> json) {
    final seq = json['seq'];
    final table = json['table_name'];
    if (seq is! num || table is! String || table.isEmpty) return null;
    return ContentChange(
      seq: seq.toInt(),
      table: table,
      rowId: json['row_id']?.toString() ?? '*',
      op: json['op']?.toString() ?? '',
    );
  }
}

/// Changes after a sequence number plus the feed's latest sequence.
class ContentChangePage {
  const ContentChangePage({required this.changes, required this.latest});

  final List<ContentChange> changes;
  final int latest;
}

/// Source of content changes (`GET /api/v1/content/changes?since=<seq>`).
abstract interface class ContentChangeSource {
  Future<ContentChangePage> fetch(int since);
}

/// [ContentChangeSource] backed by the Cloudflare Worker.
class EdgeContentChangeSource implements ContentChangeSource {
  EdgeContentChangeSource(this._http);

  static const String endpoint =
      '${CloudflareConfig.baseUrl}/api/v1/content/changes';

  final http.Client _http;

  @override
  Future<ContentChangePage> fetch(int since) async {
    final uri = Uri.parse(
      endpoint,
    ).replace(queryParameters: {'since': '$since'});
    final body = await EdgeJsonClient.getJson(_http, uri);
    final rows = body['changes'];
    final latest = body['latest'];
    if (rows is! List || latest is! num) {
      throw const EdgeApiException('Unexpected change feed response');
    }
    final changes = rows
        .whereType<Map>()
        .map((row) => ContentChange.fromJson(Map<String, dynamic>.from(row)))
        .whereType<ContentChange>()
        .toList(growable: false);
    return ContentChangePage(changes: changes, latest: latest.toInt());
  }
}

/// Persists the last applied change sequence across app restarts.
abstract interface class ContentChangeCursorStore {
  Future<int?> read();
  Future<void> write(int seq);
}

class SharedPrefsContentChangeCursorStore implements ContentChangeCursorStore {
  static const String key = 'content_change_feed_seq';

  @override
  Future<int?> read() async =>
      (await SharedPreferences.getInstance()).getInt(key);

  @override
  Future<void> write(int seq) async =>
      (await SharedPreferences.getInstance()).setInt(key, seq);
}

final contentChangeSourceProvider = Provider<ContentChangeSource>(
  (ref) => EdgeContentChangeSource(ref.watch(edgeHttpClientProvider)),
);

final contentChangeCursorStoreProvider = Provider<ContentChangeCursorStore>(
  (ref) => SharedPrefsContentChangeCursorStore(),
);
