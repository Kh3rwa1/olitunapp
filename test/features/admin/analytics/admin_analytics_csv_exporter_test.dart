import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/analytics/admin_analytics_csv_exporter.dart'
    as exporter;
import 'package:itun/features/admin/presentation/analytics/admin_analytics_csv_exporter_stub.dart'
    as clipboard_exporter;
import 'package:itun/features/admin/presentation/analytics/admin_analytics_models.dart';

const _expectedHeader =
    'dateKey,eventName,totalEvents,uniqueUsers,platformBreakdown,sourceBreakdown';

AdminAnalyticsSnapshot snapshotWith(List<Map<String, dynamic>> rollups) {
  return AdminAnalyticsSnapshot.fromRows(
    now: DateTime.utc(2026, 5, 22),
    startDate: DateTime.utc(2026, 5, 2),
    endDate: DateTime.utc(2026, 5, 8),
    rollups: rollups,
    events: const [],
  );
}

void main() {
  test(
    'empty input exports metadata and the header row with no data rows',
    () {
      final csv = snapshotWith(const []).toRollupsCsv();
      final lines =
          csv.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

      expect(lines.first, startsWith('# Generated At,'));
      expect(lines, contains('# Date Scope,2026-05-02 to 2026-05-08'));
      expect(lines, contains('# Data Status,unavailable'));
      expect(lines, contains('# Total Rollup Rows,0'));
      expect(lines.last, _expectedHeader);
    },
  );

  test(
    'rollup rows are exported in source order under the six fixed columns',
    () {
      final csv = snapshotWith(const [
        {
          'dateKey': '2026-05-02',
          'eventName': 'quiz_completed',
          'totalEvents': 3,
          'uniqueUsers': 2,
          'platformBreakdown': '{"android":3}',
          'sourceBreakdown': '{"quiz_screen":3}',
        },
        {
          'dateKey': '2026-05-01',
          'eventName': 'lesson_completed',
          'totalEvents': 5,
          'uniqueUsers': 4,
          'platformBreakdown': '{"ios":5}',
          'sourceBreakdown': '{"lesson_detail":5}',
        },
      ]).toRollupsCsv();

      final lines =
          csv.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      final headerIndex = lines.indexOf(_expectedHeader);

      expect(headerIndex, greaterThan(0));
      expect(lines, contains('# Data Status,complete'));
      expect(lines, contains('# Total Rollup Rows,2'));
      expect(lines, hasLength(headerIndex + 3));
      expect(
        lines[headerIndex + 1],
        '2026-05-02,quiz_completed,3,2,"{""android"":3}","{""quiz_screen"":3}"',
      );
      expect(
        lines[headerIndex + 2],
        startsWith('2026-05-01,lesson_completed,5,4,'),
      );
    },
  );

  test(
    'commas, quotes, newlines, and Ol Chiki unicode survive the round trip',
    () {
      final csv = snapshotWith(const [
        {
          'dateKey': '2026-05-03',
          'eventName': 'lesson,"ᱥᱟᱹᱨᱤ"\nnext',
          'totalEvents': 1,
          'uniqueUsers': 1,
        },
      ]).toRollupsCsv();

      expect(
        csv,
        contains('"lesson,""ᱥᱟᱹᱨᱤ""\nnext"'),
      );
      expect(csv, contains('ᱥᱟᱹᱨᱤ'));
    },
  );

  test(
    'the non-IO fallback export copies the csv to the clipboard and labels it as copied',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      String? clipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await clipboard_exporter.exportAnalyticsCsv(
        filename: 'olitun-learning-analytics.csv',
        csv: 'dateKey,eventName\n2026-05-22,lesson_completed',
      );

      expect(clipboardText, 'dateKey,eventName\n2026-05-22,lesson_completed');
      expect(clipboard_exporter.analyticsCsvExportLabel, 'copied');
      expect(exporter.analyticsCsvExportLabel, 'opened in share sheet');
    },
  );
}
