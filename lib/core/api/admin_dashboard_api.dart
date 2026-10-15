import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_edge_client.dart';
import 'edge_json_client.dart';

/// Learning analytics for a date range, computed by the Worker from D1.
class AdminAnalyticsData {
  const AdminAnalyticsData({
    required this.rollups,
    required this.events,
    required this.eventsTruncated,
  });

  /// One row per (dateKey, eventName) with totals and source/platform
  /// breakdowns.
  final List<Map<String, dynamic>> rollups;

  /// Distinct (dateKey, userId | sessionId) actor-days.
  final List<Map<String, dynamic>> events;

  /// True when the actor-day list hit the Worker's cap.
  final bool eventsTruncated;
}

/// Read-only admin dashboard data from the Worker (D1).
class AdminDashboardApi {
  AdminDashboardApi(this._client);

  final AdminEdgeClient _client;

  static List<Map<String, dynamic>> _maps(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : <Map<String, dynamic>>[];

  /// Most recently changed rows per content table (`lessons`, `categories`,
  /// `words`, `letters`, `numbers`, `banners`), with `$createdAt` /
  /// `$updatedAt` and the display fields only.
  Future<Map<String, List<Map<String, dynamic>>>> recentActivity() async {
    final uri = AdminEdgeClient.adminUri('dashboard/activity');
    final body = await _client.getOk(uri);
    final collections = body['collections'];
    if (collections is! Map) {
      throw EdgeApiException('Missing "collections" from ${uri.path}');
    }
    return {
      for (final entry in collections.entries)
        entry.key.toString(): _maps(entry.value),
    };
  }

  Future<AdminAnalyticsData> analytics({
    required String startKey,
    required String endKey,
  }) async {
    final body = await _client.getOk(
      AdminEdgeClient.adminUri('analytics/snapshot', {
        'start': startKey,
        'end': endKey,
      }),
    );
    return AdminAnalyticsData(
      rollups: _maps(body['rollups']),
      events: _maps(body['events']),
      eventsTruncated: body['eventsTruncated'] == true,
    );
  }

  /// Counters for the gamification ops view, keyed by metric id.
  Future<Map<String, int>> gamificationMetrics() async {
    final body = await _client.getOk(
      AdminEdgeClient.adminUri('gamification/metrics'),
    );
    final metrics = body['metrics'];
    if (metrics is! Map) return const {};
    return {
      for (final entry in metrics.entries)
        if (entry.value is num)
          entry.key.toString(): (entry.value as num).toInt(),
    };
  }

  /// Whether each backing D1 table exists.
  Future<Map<String, bool>> schemaHealth() async {
    final body = await _client.getOk(AdminEdgeClient.adminUri('health/schema'));
    final tables = body['tables'];
    if (tables is! Map) return const {};
    return {
      for (final entry in tables.entries)
        entry.key.toString(): entry.value == true,
    };
  }
}

final adminDashboardApiProvider = Provider<AdminDashboardApi>(
  (ref) => AdminDashboardApi(ref.watch(adminEdgeClientProvider)),
);
