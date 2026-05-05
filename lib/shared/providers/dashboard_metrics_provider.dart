import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/theme/app_colors.dart';

/// A single recent activity entry rendered in the admin dashboard
/// "Recent changes" panel. Built from real `$createdAt`/`$updatedAt`
/// timestamps on Appwrite documents.
class ActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final bool isUpdate;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.timestamp,
    required this.isUpdate,
  });
}

/// Aggregated engagement / CMS metrics powering the admin dashboard.
///
/// The dashboard does not (yet) have access to per-user analytics, so we
/// surface the next best signal: real CMS authoring activity. The chart
/// shows lessons vs vocabulary added per day for the last 7 days, and the
/// week-over-week delta compares total content created this week against
/// the previous week.
class DashboardMetrics {
  /// Most-recent CMS changes across all collections, sorted newest first.
  final List<ActivityItem> recentActivity;

  /// 7-day series of lessons created (oldest → newest, length 7).
  final List<int> lessonsSeries;

  /// 7-day series of vocabulary (words) created (oldest → newest, length 7).
  final List<int> vocabularySeries;

  /// Day labels for the chart axis (oldest → newest, length 7).
  final List<String> dayLabels;

  /// Week-over-week change in total CMS items created (this week vs last
  /// week). `null` when there's not enough signal in either week to make
  /// the comparison meaningful — in which case the dashboard hides the pill.
  final double? weekOverWeekDelta;

  const DashboardMetrics({
    required this.recentActivity,
    required this.lessonsSeries,
    required this.vocabularySeries,
    required this.dayLabels,
    required this.weekOverWeekDelta,
  });

  bool get hasAnyActivity =>
      recentActivity.isNotEmpty ||
      lessonsSeries.any((v) => v > 0) ||
      vocabularySeries.any((v) => v > 0);
}

/// Per-collection config used to fetch and label recent rows.
class _CollectionSpec {
  final String id;
  final String singular;
  final String Function(Map<String, dynamic> row) subtitle;
  final IconData icon;
  final Color color;

  const _CollectionSpec({
    required this.id,
    required this.singular,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

String _firstNonEmpty(List<String?> candidates, String fallback) {
  for (final c in candidates) {
    if (c != null && c.trim().isNotEmpty) return c.trim();
  }
  return fallback;
}

final List<_CollectionSpec> _activitySpecs = [
  _CollectionSpec(
    id: 'lessons',
    singular: 'Lesson',
    icon: Icons.school_rounded,
    color: AppColors.duoBlue,
    subtitle: (r) => _firstNonEmpty([
      r['titleLatin'] as String?,
      r['titleOlChiki'] as String?,
    ], 'Untitled lesson'),
  ),
  _CollectionSpec(
    id: 'categories',
    singular: 'Category',
    icon: Icons.category_rounded,
    color: AppColors.duoGreen,
    subtitle: (r) => _firstNonEmpty([
      r['titleLatin'] as String?,
      r['titleOlChiki'] as String?,
    ], 'Untitled category'),
  ),
  _CollectionSpec(
    id: 'words',
    singular: 'Word',
    icon: Icons.menu_book_rounded,
    color: AppColors.duoYellow,
    subtitle: (r) => _firstNonEmpty([
      r['wordLatin'] as String?,
      r['wordOlChiki'] as String?,
      r['meaning'] as String?,
    ], 'Untitled word'),
  ),
  _CollectionSpec(
    id: 'letters',
    singular: 'Letter',
    icon: Icons.text_fields_rounded,
    color: AppColors.duoOrange,
    subtitle: (r) => _firstNonEmpty([
      r['transliterationLatin'] as String?,
      r['charOlChiki'] as String?,
    ], 'Untitled letter'),
  ),
  _CollectionSpec(
    id: 'numbers',
    singular: 'Number',
    icon: Icons.format_list_numbered_rounded,
    color: AppColors.accentCyan,
    subtitle: (r) {
      final value = r['value'];
      final name = r['nameLatin'] as String?;
      if (value != null && name != null && name.isNotEmpty) {
        return '$value · $name';
      }
      return _firstNonEmpty([name, r['numeral'] as String?], 'Untitled number');
    },
  ),
  _CollectionSpec(
    id: 'banners',
    singular: 'Banner',
    icon: Icons.featured_play_list_rounded,
    color: AppColors.duoPurple,
    subtitle: (r) => _firstNonEmpty([
      r['title'] as String?,
      r['subtitle'] as String?,
    ], 'Untitled banner'),
  ),
];

DateTime? _parseDate(dynamic v) {
  if (v is String && v.isNotEmpty) {
    return DateTime.tryParse(v)?.toLocal();
  }
  return null;
}

/// Fetches the dashboard metrics from Appwrite. Auto-refreshes whenever the
/// provider is invalidated (e.g. via the dashboard's "Refresh" button or
/// after a seeding operation).
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final db = ref.watch(appwriteDbServiceProvider);

  // Pull the most recent rows from each collection in parallel. We cap the
  // per-collection result so the call stays cheap even when collections grow.
  final results = await Future.wait(
    _activitySpecs.map((spec) async {
      try {
        final rows = await db.listDocuments(
          spec.id,
          queries: [Query.orderDesc(r'$updatedAt'), Query.limit(50)],
        );
        return MapEntry(spec, rows);
      } catch (_) {
        return MapEntry(spec, const <Map<String, dynamic>>[]);
      }
    }),
  );

  // ── Recent activity feed ────────────────────────────────────────────────
  final activity = <ActivityItem>[];
  for (final entry in results) {
    final spec = entry.key;
    for (final row in entry.value) {
      final created = _parseDate(row[r'$createdAt']);
      final updated = _parseDate(row[r'$updatedAt']);
      final ts = updated ?? created;
      if (ts == null) continue;

      // Treat anything updated more than ~30s after creation as an "update".
      final isUpdate =
          created != null &&
          updated != null &&
          updated.difference(created).inSeconds > 30;

      activity.add(
        ActivityItem(
          title: isUpdate
              ? '${spec.singular} updated'
              : 'New ${spec.singular.toLowerCase()} added',
          subtitle: spec.subtitle(row),
          icon: spec.icon,
          color: spec.color,
          timestamp: ts,
          isUpdate: isUpdate,
        ),
      );
    }
  }
  activity.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final recent = activity.take(6).toList();

  // ── 7-day series ───────────────────────────────────────────────────────
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = List<DateTime>.generate(
    7,
    (i) => today.subtract(Duration(days: 6 - i)),
  );
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final dayLabels = days.map((d) => dayNames[d.weekday - 1]).toList();

  List<int> bucketCreated(String collectionId) {
    final rows = results
        .firstWhere(
          (e) => e.key.id == collectionId,
          orElse: () => MapEntry(_activitySpecs.first, const []),
        )
        .value;
    final buckets = List<int>.filled(7, 0);
    for (final row in rows) {
      final created = _parseDate(row[r'$createdAt']);
      if (created == null) continue;
      final day = DateTime(created.year, created.month, created.day);
      for (var i = 0; i < days.length; i++) {
        if (day == days[i]) {
          buckets[i] += 1;
          break;
        }
      }
    }
    return buckets;
  }

  final lessonsSeries = bucketCreated('lessons');
  final vocabularySeries = bucketCreated('words');

  // ── Week-over-week delta ───────────────────────────────────────────────
  final thisWeekStart = today.subtract(const Duration(days: 6));
  final lastWeekStart = today.subtract(const Duration(days: 13));
  final lastWeekEnd = today.subtract(const Duration(days: 7));

  var thisWeek = 0;
  var lastWeek = 0;
  for (final entry in results) {
    for (final row in entry.value) {
      final created = _parseDate(row[r'$createdAt']);
      if (created == null) continue;
      final day = DateTime(created.year, created.month, created.day);
      if (!day.isBefore(thisWeekStart) && !day.isAfter(today)) {
        thisWeek += 1;
      } else if (!day.isBefore(lastWeekStart) && !day.isAfter(lastWeekEnd)) {
        lastWeek += 1;
      }
    }
  }

  // Only surface a delta when both weeks have signal — otherwise the pill
  // is hidden so we never show a synthetic comparison.
  final double? delta = lastWeek > 0
      ? (thisWeek - lastWeek) / lastWeek * 100.0
      : null;

  return DashboardMetrics(
    recentActivity: recent,
    lessonsSeries: lessonsSeries,
    vocabularySeries: vocabularySeries,
    dayLabels: dayLabels,
    weekOverWeekDelta: delta,
  );
});
