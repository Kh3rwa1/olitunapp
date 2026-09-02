import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/api/appwrite_db_service.dart';
import '../../../../../core/api/appwrite_query_builders.dart';
import '../../widgets/admin_page_header.dart';
import '../widgets/gamification_widgets.dart';

class GamificationAnalyticsView extends ConsumerWidget {
  final int reload;

  const GamificationAnalyticsView({super.key, required this.reload});

  Future<Map<String, int>> _loadAnalyticsMetrics(WidgetRef ref) async {
    final db = ref.read(appwriteDbServiceProvider);
    Future<int> count(String collectionId, {List<String>? queries}) async {
      try {
        final rows = await db.listDocuments(
          collectionId,
          queries: [DbQuery.limit(500), ...?queries],
          paginate: false,
        );
        return rows.length;
      } catch (_) {
        return 0;
      }
    }

    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final values = await Future.wait<int>([
      count(
        'learning_analytics_events',
        queries: [DbQuery.greaterThan('occurredAt', today)],
      ),
      count(
        'learning_analytics_events',
        queries: [DbQuery.equal('eventName', 'lesson_completed')],
      ),
      count(
        'learning_analytics_events',
        queries: [DbQuery.equal('eventName', 'quiz_attempted')],
      ),
      count(
        'learning_analytics_events',
        queries: [DbQuery.equal('eventName', 'streak_milestone')],
      ),
      count('learning_analytics_daily_rollups'),
      count('user_badges', queries: [DbQuery.equal('isUnlocked', true)]),
      count('mistake_review_sessions'),
      count('user_mistakes', queries: [DbQuery.equal('isMastered', false)]),
      count(
        'bakhed_listening_progress',
        queries: [DbQuery.equal('completed80Percent', true)],
      ),
      count('bakhed_lyrics'),
      count('bakhed_vocabulary'),
      count(
        'bakhed_cultural_notes',
        queries: [DbQuery.equal('isPublished', true)],
      ),
    ]);
    return {
      'Learning events today': values[0],
      'Lessons completed': values[1],
      'Quiz attempts': values[2],
      'Streak milestones': values[3],
      'Daily analytics rollups': values[4],
      'Unlocked badges': values[5],
      'Mistake reviews completed': values[6],
      'Mistakes needing practice': values[7],
      'Bakhed 80% completions': values[8],
      'Bakhed lyric lines': values[9],
      'Bakhed vocabulary words': values[10],
      'Published cultural notes': values[11],
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 860;
    return Padding(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPageHeader(
            title: 'Learning Health Analytics',
            subtitle:
                'Real product signals across circles, rewards, mistakes, Bakhed, and content quality.',
            eyebrow: 'PRODUCT OPS',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<Map<String, int>>(
              future: _loadAnalyticsMetrics(ref),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: SelectableText(
                      'Could not load analytics: ${snapshot.error}',
                    ),
                  );
                }
                final metrics = snapshot.data ?? const <String, int>{};
                return GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 4 : 2,
                    childAspectRatio: isWide ? 1.8 : 1.35,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  children: [
                    for (final entry in metrics.entries)
                      OpsMetricCard(label: entry.key, value: entry.value),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
