import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/admin_dashboard_api.dart';
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
      final api = ref.read(adminDashboardApiProvider);
      final range = ref.watch(adminAnalyticsRangeProvider);
      final now = DateTime.now().toUtc();
      final start = range.startFor(now);
      final end = range.endFor(now);
      final startKey = formatDateKey(start);
      final endKey = formatDateKey(end);

      // The Worker computes per-day/per-event rollups (with source and
      // platform breakdowns) and distinct actor-days from D1 events.
      final data = await api.analytics(startKey: startKey, endKey: endKey);
      final rollups = data.rollups;
      final events = data.events;

      return AdminAnalyticsSnapshot.fromRows(
        rollups: rollups,
        events: events,
        now: now,
        startDate: start,
        endDate: end,
        isSampled: data.eventsTruncated,
        eventsComplete: !data.eventsTruncated,
      );
    });

/// Truncates [value] to a UTC calendar date.
DateTime adminAnalyticsDateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
