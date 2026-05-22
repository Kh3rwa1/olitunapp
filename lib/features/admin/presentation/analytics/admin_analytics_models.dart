import 'dart:convert';

class AdminAnalyticsSnapshot {
  const AdminAnalyticsSnapshot({
    required this.dau,
    required this.wau,
    required this.mau,
    required this.dailyActiveUsers,
    required this.eventTotals,
    required this.sourceTotals,
    required this.platformTotals,
    required this.eventSourceTotals,
    required this.retentionCohorts,
    required this.rollupsForExport,
    required this.rollupRows,
    required this.eventRows,
    required this.startDate,
    required this.endDate,
  });

  factory AdminAnalyticsSnapshot.fromRows({
    required List<Map<String, dynamic>> rollups,
    required List<Map<String, dynamic>> events,
    DateTime? now,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final today = _dateOnly(now ?? DateTime.now().toUtc());
    final resolvedEnd = _dateOnly(endDate ?? today);
    final resolvedStart = _dateOnly(
      startDate ?? resolvedEnd.subtract(const Duration(days: 29)),
    );
    final eventTotals = <String, int>{};
    final sourceTotals = <String, int>{};
    final platformTotals = <String, int>{};
    final eventSourceTotals = <String, int>{};
    final dailyUsers = <DateTime, Set<String>>{};
    final rollupDailyUsers = <DateTime, int>{};
    final exportRows = <AnalyticsRollupRow>[];

    for (final rollup in rollups) {
      final date = _parseDate(rollup['dateKey']);
      final eventName = _text(rollup['eventName'], fallback: 'unknown_event');
      final totalEvents = _integer(rollup['totalEvents']);
      final uniqueUsers = _integer(rollup['uniqueUsers']);
      eventTotals[eventName] = (eventTotals[eventName] ?? 0) + totalEvents;
      if (date != null) {
        final existing = rollupDailyUsers[date] ?? 0;
        if (uniqueUsers > existing) rollupDailyUsers[date] = uniqueUsers;
      }

      final sourceBreakdown = parseBreakdown(rollup['sourceBreakdown']);
      final platformBreakdown = parseBreakdown(rollup['platformBreakdown']);
      exportRows.add(
        AnalyticsRollupRow(
          dateKey: date == null
              ? _text(rollup['dateKey'], fallback: '')
              : formatDateKey(date),
          eventName: eventName,
          totalEvents: totalEvents,
          uniqueUsers: uniqueUsers,
          sourceBreakdown: sourceBreakdown,
          platformBreakdown: platformBreakdown,
        ),
      );

      for (final entry in sourceBreakdown.entries) {
        sourceTotals[entry.key] = (sourceTotals[entry.key] ?? 0) + entry.value;
        final key = '$eventName / ${entry.key}';
        eventSourceTotals[key] = (eventSourceTotals[key] ?? 0) + entry.value;
      }

      for (final entry in platformBreakdown.entries) {
        platformTotals[entry.key] =
            (platformTotals[entry.key] ?? 0) + entry.value;
      }
    }

    for (final event in events) {
      final date = _parseDate(event['dateKey']);
      final actorId = _actorId(event);
      if (date != null && actorId != null) {
        dailyUsers.putIfAbsent(date, () => <String>{}).add(actorId);
      }

      if (rollups.isEmpty) {
        final eventName = _text(event['eventName'], fallback: 'unknown_event');
        eventTotals[eventName] = (eventTotals[eventName] ?? 0) + 1;

        final source = _text(event['source'], fallback: 'app');
        sourceTotals[source] = (sourceTotals[source] ?? 0) + 1;
        final key = '$eventName / $source';
        eventSourceTotals[key] = (eventSourceTotals[key] ?? 0) + 1;

        final platform = _text(event['platform'], fallback: 'unknown');
        platformTotals[platform] = (platformTotals[platform] ?? 0) + 1;
      }
    }

    final dataDates = [...dailyUsers.keys, ...rollupDailyUsers.keys];
    final anchorDate = dataDates.isEmpty ? today : _latestDate(dataDates);
    final hasRawUsers = dailyUsers.isNotEmpty;
    final dailyActiveCounts = hasRawUsers
        ? dailyUsers.map((key, value) => MapEntry(key, value.length))
        : rollupDailyUsers;
    final dau = hasRawUsers
        ? _usersSince(dailyUsers, anchorDate, Duration.zero).length
        : _countSince(dailyActiveCounts, anchorDate, Duration.zero);
    final wau = hasRawUsers
        ? _usersSince(dailyUsers, anchorDate, const Duration(days: 6)).length
        : _countSince(dailyActiveCounts, anchorDate, const Duration(days: 6));
    final mau = hasRawUsers
        ? _usersSince(dailyUsers, anchorDate, const Duration(days: 29)).length
        : _countSince(dailyActiveCounts, anchorDate, const Duration(days: 29));

    return AdminAnalyticsSnapshot(
      dau: dau,
      wau: wau,
      mau: mau,
      dailyActiveUsers: dailyActiveCounts,
      eventTotals: sortCounts(eventTotals),
      sourceTotals: sortCounts(sourceTotals),
      platformTotals: sortCounts(platformTotals),
      eventSourceTotals: sortCounts(eventSourceTotals),
      retentionCohorts: buildRetentionCohorts(events, now: today),
      rollupsForExport: exportRows,
      rollupRows: rollups.length,
      eventRows: events.length,
      startDate: resolvedStart,
      endDate: resolvedEnd,
    );
  }

  final int dau;
  final int wau;
  final int mau;
  final Map<DateTime, int> dailyActiveUsers;
  final Map<String, int> eventTotals;
  final Map<String, int> sourceTotals;
  final Map<String, int> platformTotals;
  final Map<String, int> eventSourceTotals;
  final List<RetentionCohort> retentionCohorts;
  final List<AnalyticsRollupRow> rollupsForExport;
  final int rollupRows;
  final int eventRows;
  final DateTime startDate;
  final DateTime endDate;

  bool get hasAnyData => rollupRows > 0 || eventRows > 0;

  int get rangeDays => endDate.difference(startDate).inDays + 1;

  String get semanticsSummary =>
      'Learning analytics dashboard. DAU $dau, WAU $wau, MAU $mau. '
      '${eventTotals.length} event types and ${platformTotals.length} platforms.';

  String toRollupsCsv() {
    final lines = <List<Object?>>[
      [
        'dateKey',
        'eventName',
        'totalEvents',
        'uniqueUsers',
        'platformBreakdown',
        'sourceBreakdown',
      ],
      for (final row in rollupsForExport)
        [
          row.dateKey,
          row.eventName,
          row.totalEvents,
          row.uniqueUsers,
          jsonEncode(row.platformBreakdown),
          jsonEncode(row.sourceBreakdown),
        ],
    ];
    return lines.map((line) => line.map(csvEscape).join(',')).join('\n');
  }
}

class AnalyticsRollupRow {
  const AnalyticsRollupRow({
    required this.dateKey,
    required this.eventName,
    required this.totalEvents,
    required this.uniqueUsers,
    required this.platformBreakdown,
    required this.sourceBreakdown,
  });

  final String dateKey;
  final String eventName;
  final int totalEvents;
  final int uniqueUsers;
  final Map<String, int> platformBreakdown;
  final Map<String, int> sourceBreakdown;
}

class RetentionCohort {
  const RetentionCohort({
    required this.weekStart,
    required this.size,
    required this.weekRetention,
  });

  final DateTime weekStart;
  final int size;
  final List<double> weekRetention;
}

Map<String, int> parseBreakdown(Object? raw) {
  if (raw == null) return {};
  Object? decoded = raw;
  if (raw is String) {
    if (raw.trim().isEmpty) return {};
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return {};
    }
  }
  if (decoded is! Map) return {};

  final result = <String, int>{};
  for (final entry in decoded.entries) {
    final key = _text(entry.key, fallback: '').trim();
    if (key.isEmpty) continue;
    result[key] = _integer(entry.value);
  }
  result.removeWhere((_, value) => value <= 0);
  return sortCounts(result);
}

Map<String, int> sortCounts(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount == 0 ? a.key.compareTo(b.key) : byCount;
    });
  return Map<String, int>.fromEntries(entries);
}

List<RetentionCohort> buildRetentionCohorts(
  List<Map<String, dynamic>> events, {
  DateTime? now,
  int weeks = 6,
}) {
  final seenByActor = <String, Set<DateTime>>{};
  for (final event in events) {
    final actorId = _actorId(event);
    final date = _parseDate(event['dateKey']);
    if (actorId == null || date == null) continue;
    seenByActor.putIfAbsent(actorId, () => <DateTime>{}).add(_weekStart(date));
  }

  final cohorts = <DateTime, Set<String>>{};
  for (final entry in seenByActor.entries) {
    if (entry.value.isEmpty) continue;
    final firstWeek = entry.value.reduce((a, b) => a.isBefore(b) ? a : b);
    cohorts.putIfAbsent(firstWeek, () => <String>{}).add(entry.key);
  }

  final currentWeek = _weekStart(now ?? DateTime.now().toUtc());
  final rows = <RetentionCohort>[];
  for (final cohortWeek in cohorts.keys) {
    if (cohortWeek.isAfter(currentWeek)) continue;
    final members = cohorts[cohortWeek]!;
    final retention = <double>[];
    for (var offset = 0; offset < weeks; offset += 1) {
      final targetWeek = cohortWeek.add(Duration(days: 7 * offset));
      if (targetWeek.isAfter(currentWeek)) {
        retention.add(0);
        continue;
      }
      final retained = members.where((actor) {
        return seenByActor[actor]?.contains(targetWeek) ?? false;
      }).length;
      retention.add(members.isEmpty ? 0 : retained / members.length);
    }
    rows.add(
      RetentionCohort(
        weekStart: cohortWeek,
        size: members.length,
        weekRetention: retention,
      ),
    );
  }

  rows.sort((a, b) => b.weekStart.compareTo(a.weekStart));
  return rows.take(8).toList();
}

String formatDateKey(DateTime date) {
  final d = _dateOnly(date);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

String formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String csvEscape(Object? value) {
  final text = value?.toString() ?? '';
  final needsQuotes =
      text.contains(',') || text.contains('"') || text.contains('\n');
  final escaped = text.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

DateTime _latestDate(List<DateTime> dates) {
  return dates.reduce((a, b) => a.isAfter(b) ? a : b);
}

int _countSince(
  Map<DateTime, int> dailyCounts,
  DateTime today,
  Duration window,
) {
  final start = today.subtract(window);
  var count = 0;
  for (final entry in dailyCounts.entries) {
    if (entry.key.isBefore(start) || entry.key.isAfter(today)) continue;
    count += entry.value;
  }
  return count;
}

Set<String> _usersSince(
  Map<DateTime, Set<String>> dailyUsers,
  DateTime today,
  Duration window,
) {
  final start = today.subtract(window);
  final users = <String>{};
  for (final entry in dailyUsers.entries) {
    if (entry.key.isBefore(start) || entry.key.isAfter(today)) continue;
    users.addAll(entry.value);
  }
  return users;
}

String? _actorId(Map<String, dynamic> event) {
  final userId = _text(event['userId'], fallback: '').trim();
  if (userId.isNotEmpty) return 'u:$userId';
  final sessionId = _text(event['sessionId'], fallback: '').trim();
  if (sessionId.isNotEmpty) return 's:$sessionId';
  return null;
}

DateTime? _parseDate(Object? value) {
  final text = _text(value, fallback: '').trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
  final parsed = DateTime.tryParse('${text}T00:00:00Z');
  return parsed == null ? null : _dateOnly(parsed);
}

DateTime _dateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

DateTime _weekStart(DateTime value) {
  final date = _dateOnly(value);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

String _text(Object? value, {required String fallback}) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) return fallback;
  return text;
}

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
