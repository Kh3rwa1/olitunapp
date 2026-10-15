import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/api/admin_dashboard_api.dart';
import '../../widgets/admin_page_header.dart';
import '../widgets/gamification_widgets.dart';

/// Labels for the Worker's gamification metric ids, in display order.
const gamificationMetricLabels = <String, String>{
  'learningEventsToday': 'Learning events today',
  'lessonsCompleted': 'Lessons completed',
  'quizAttempts': 'Quiz attempts',
  'streakMilestones': 'Streak milestones',
  'dailyRollups': 'Daily analytics rollups',
  'unlockedBadges': 'Unlocked badges',
  'mistakeReviewsCompleted': 'Mistake reviews completed',
  'mistakesNeedingPractice': 'Mistakes needing practice',
  'bakhedCompletions': 'Bakhed 80% completions',
  'bakhedLyricLines': 'Bakhed lyric lines',
  'bakhedVocabularyWords': 'Bakhed vocabulary words',
  'publishedCulturalNotes': 'Published cultural notes',
};

/// Maps Worker metric ids to labelled counts (missing ids count as 0).
Map<String, int> labelGamificationMetrics(Map<String, int> metrics) => {
  for (final entry in gamificationMetricLabels.entries)
    entry.value: metrics[entry.key] ?? 0,
};

class GamificationAnalyticsView extends ConsumerWidget {
  final int reload;

  const GamificationAnalyticsView({super.key, required this.reload});

  // Counts come from D1 through the Worker; a failure shows the error state
  // instead of a grid of misleading zeros.
  Future<Map<String, int>> _loadAnalyticsMetrics(WidgetRef ref) async =>
      labelGamificationMetrics(
        await ref.read(adminDashboardApiProvider).gamificationMetrics(),
      );

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
