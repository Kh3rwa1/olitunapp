import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/appwrite_db_service.dart';
import 'admin_analytics_models.dart';

enum AdminAnalyticsRangePreset { seven, thirty, ninety, custom }

enum AdminAnalyticsDensity { comfortable, compact }

class AdminAnalyticsDateRange {
  const AdminAnalyticsDateRange({
    required this.preset,
    this.customStart,
    this.customEnd,
  });

  const AdminAnalyticsDateRange.last30()
    : preset = AdminAnalyticsRangePreset.thirty,
      customStart = null,
      customEnd = null;

  const AdminAnalyticsDateRange.custom({
    required DateTime start,
    required DateTime end,
  }) : preset = AdminAnalyticsRangePreset.custom,
       customStart = start,
       customEnd = end;

  final AdminAnalyticsRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  int get days => switch (preset) {
    AdminAnalyticsRangePreset.seven => 7,
    AdminAnalyticsRangePreset.thirty => 30,
    AdminAnalyticsRangePreset.ninety => 90,
    AdminAnalyticsRangePreset.custom => 30,
  };

  DateTime startFor(DateTime now) {
    if (preset == AdminAnalyticsRangePreset.custom && customStart != null) {
      return adminAnalyticsDateOnly(customStart!);
    }
    final end = endFor(now);
    return end.subtract(Duration(days: days - 1));
  }

  DateTime endFor(DateTime now) {
    if (preset == AdminAnalyticsRangePreset.custom && customEnd != null) {
      return adminAnalyticsDateOnly(customEnd!);
    }
    return adminAnalyticsDateOnly(now);
  }

  String label(DateTime now) {
    if (preset == AdminAnalyticsRangePreset.custom &&
        customStart != null &&
        customEnd != null) {
      return '${formatShortDate(startFor(now))} - ${formatShortDate(endFor(now))}';
    }
    return switch (preset) {
      AdminAnalyticsRangePreset.seven => 'Last 7 days',
      AdminAnalyticsRangePreset.thirty => 'Last 30 days',
      AdminAnalyticsRangePreset.ninety => 'Last 90 days',
      AdminAnalyticsRangePreset.custom => 'Custom range',
    };
  }
}

final adminAnalyticsRangeProvider = StateProvider<AdminAnalyticsDateRange>(
  (_) => const AdminAnalyticsDateRange.last30(),
);

final adminAnalyticsDensityProvider = StateProvider<AdminAnalyticsDensity>(
  (_) => AdminAnalyticsDensity.comfortable,
);

final adminAnalyticsSnapshotProvider =
    FutureProvider.autoDispose<AdminAnalyticsSnapshot>((ref) async {
      final db = ref.read(appwriteDbServiceProvider);
      final range = ref.watch(adminAnalyticsRangeProvider);
      final now = DateTime.now().toUtc();
      final start = range.startFor(now);
      final end = range.endFor(now);
      final startKey = formatDateKey(start);
      final endKey = formatDateKey(end);

      final rollups = await db.listDocuments(
        'learning_analytics_daily_rollups',
        queries: [
          Query.greaterThanEqual('dateKey', startKey),
          Query.lessThanEqual('dateKey', endKey),
          Query.orderDesc('dateKey'),
          Query.limit(500),
        ],
        paginate: false,
      );

      var events = <Map<String, dynamic>>[];
      try {
        events = await db.listDocuments(
          'learning_analytics_events',
          queries: [
            Query.greaterThanEqual('dateKey', startKey),
            Query.lessThanEqual('dateKey', endKey),
            Query.orderDesc('dateKey'),
            Query.limit(1000),
          ],
          paginate: false,
        );
      } catch (_) {
        // Rollups still power the product dashboard when raw event reads are
        // restricted. DAU/retention gracefully drop to zero instead of failing
        // the whole admin page.
      }

      return AdminAnalyticsSnapshot.fromRows(
        rollups: rollups,
        events: events,
        now: now,
        startDate: start,
        endDate: end,
      );
    });

/// Truncates a timestamp to a UTC date (midnight).
DateTime adminAnalyticsDateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
