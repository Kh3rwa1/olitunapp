import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/dashboard_kpi_widgets.dart';

class DashboardBentoGrid extends ConsumerWidget {
  final bool isDark;
  final bool isWide;
  const DashboardBentoGrid({
    super.key,
    required this.isDark,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final lettersAsync = ref.watch(lettersProvider);
    final lessonsAsync = ref.watch(lessonNotifierProvider);
    final wordsAsync = ref.watch(wordsProvider);
    final numbersAsync = ref.watch(numbersProvider);
    final quizzesAsync = ref.watch(quizzesProvider);

    int countOf(AsyncValue v) => v.when(
      data: (l) => (l as List).length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    final totalContent =
        countOf(categoriesAsync) +
        countOf(lettersAsync) +
        countOf(lessonsAsync) +
        countOf(wordsAsync) +
        countOf(numbersAsync) +
        countOf(quizzesAsync);

    final supporting = [
      _Kpi(
        label: 'Categories',
        value: _txt(categoriesAsync),
        icon: Icons.category_rounded,
        accent: AppColors.duoGreen,
      ),
      _Kpi(
        label: 'Lessons',
        value: _txt(lessonsAsync),
        icon: Icons.school_rounded,
        accent: AppColors.duoBlue,
      ),
      _Kpi(
        label: 'Vocabulary',
        value: _txt(wordsAsync),
        icon: Icons.menu_book_rounded,
        accent: AppColors.duoYellow,
      ),
      _Kpi(
        label: 'Quizzes',
        value: _txt(quizzesAsync),
        icon: Icons.quiz_rounded,
        accent: AppColors.duoPurple,
      ),
      _Kpi(
        label: 'Letters',
        value: _txt(lettersAsync),
        icon: Icons.text_fields_rounded,
        accent: AppColors.duoOrange,
      ),
      _Kpi(
        label: 'Numerals',
        value: _txt(numbersAsync),
        icon: Icons.format_list_numbered_rounded,
        accent: AppColors.accentCyan,
      ),
    ];

    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final delta = metricsAsync.valueOrNull?.weekOverWeekDelta;

    if (isWide) {
      return Column(
        children: [
          DashboardHeroMetric(
            isDark: isDark,
            total: totalContent,
            isLoading: categoriesAsync.isLoading || lessonsAsync.isLoading,
            weekDelta: delta,
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.55,
            children: supporting
                .map(
                  (k) => DashboardKpiCard(
                    label: k.label,
                    value: k.value,
                    icon: k.icon,
                    accent: k.accent,
                    isDark: isDark,
                  ),
                )
                .toList(),
          ),
        ],
      );
    }
    return Column(
      children: [
        DashboardHeroMetric(
          isDark: isDark,
          total: totalContent,
          isLoading: categoriesAsync.isLoading || lessonsAsync.isLoading,
          weekDelta: delta,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: supporting
              .map(
                (k) => DashboardKpiCard(
                  label: k.label,
                  value: k.value,
                  icon: k.icon,
                  accent: k.accent,
                  isDark: isDark,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String _txt(AsyncValue v) => v.when(
    data: (l) => (l as List).length.toString(),
    loading: () => '—',
    error: (_, _) => '0',
  );
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
}
