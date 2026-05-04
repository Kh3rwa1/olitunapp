import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/providers.dart';
import '../providers/admin_auth_provider.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';

/// AAA+ admin dashboard. Re-composed bento grid with a clear focal hierarchy:
///   * Hero metric — total content units (largest, gradient-tinted card).
///   * Supporting KPI strip — categories, lessons, vocabulary, quizzes.
///   * Main analytics panel — restyled fl_chart line chart.
///   * Recent activity panel — designed empty state placeholder.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1024;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 36 : 18,
        vertical: isWide ? 32 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(isDark: isDark),
              SizedBox(height: isWide ? 32 : 24),
              _BentoGrid(isDark: isDark, isWide: isWide),
              SizedBox(height: isWide ? 24 : 20),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _AnalyticsPanel(isDark: isDark),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: _ActivityPanel(isDark: isDark),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _AnalyticsPanel(isDark: isDark),
                        const SizedBox(height: 20),
                        _ActivityPanel(isDark: isDark),
                      ],
                    ),
            ],
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.015, end: 0),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 700;
    final greeting = _greeting();

    return Wrap(
      spacing: 24,
      runSpacing: 18,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: compact ? double.infinity : width * 0.45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'OVERVIEW · LIVE',
                    style: AdminTokens.eyebrow(
                      isDark,
                    ).copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$greeting, Admin',
                style: AdminTokens.display(
                  isDark,
                ).copyWith(fontSize: compact ? 28 : 36),
              ),
              const SizedBox(height: 6),
              Text(
                'A snapshot of your curriculum, content, and engagement.',
                style: AdminTokens.body(isDark),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconAction(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh data',
              isDark: isDark,
              onTap: () {
                ref.invalidate(categoryNotifierProvider);
                ref.invalidate(lessonNotifierProvider);
                ref.invalidate(dashboardMetricsProvider);
              },
            ),
            const SizedBox(width: 10),
            _IconAction(
              icon: Icons.logout_rounded,
              tooltip: 'Sign out',
              isDark: isDark,
              onTap: () async {
                await ref.read(adminAuthServiceProvider).signOut();
                ref.invalidate(adminAuthProvider);
                if (context.mounted) context.go('/admin/login');
              },
            ),
            const SizedBox(width: 12),
            _PrimaryAction(
              icon: Icons.auto_fix_high_rounded,
              label: 'Seed data',
              onTap: () => _handleSeeding(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Working late';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AdminTokens.raised(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AdminTokens.textSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            boxShadow: AdminTokens.brandGlow(AppColors.primary, strength: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoGrid extends ConsumerWidget {
  final bool isDark;
  final bool isWide;
  const _BentoGrid({required this.isDark, required this.isWide});

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
      error: (_, __) => 0,
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
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _HeroMetric(
              isDark: isDark,
              total: totalContent,
              isLoading: categoriesAsync.isLoading || lessonsAsync.isLoading,
              weekDelta: delta,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 7,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.55,
              children: supporting
                  .map((k) => _KpiCard(kpi: k, isDark: isDark))
                  .toList(),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _HeroMetric(
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
              .map((k) => _KpiCard(kpi: k, isDark: isDark))
              .toList(),
        ),
      ],
    );
  }

  String _txt(AsyncValue v) => v.when(
    data: (l) => (l as List).length.toString(),
    loading: () => '—',
    error: (_, __) => '0',
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

class _HeroMetric extends StatelessWidget {
  final bool isDark;
  final int total;
  final bool isLoading;
  final double? weekDelta;
  const _HeroMetric({
    required this.isDark,
    required this.total,
    required this.isLoading,
    this.weekDelta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AdminTokens.radius2xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0E1A14), const Color(0xFF0A0F0C)]
              : [const Color(0xFFE8FFF3), const Color(0xFFFAFFFC)],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 18),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.10 : 0.07,
                ),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.06 : 0.05,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'TOTAL CONTENT',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isLoading ? '—' : total.toString(),
                style: AdminTokens.display(
                  isDark,
                ).copyWith(fontSize: 64, height: 1, letterSpacing: -2),
              ),
              const SizedBox(height: 6),
              Text(
                'Published units across the curriculum',
                style: AdminTokens.body(
                  isDark,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (weekDelta != null) ...[
                    _HeroPill(
                      isDark: isDark,
                      icon: weekDelta! >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      label:
                          '${weekDelta! >= 0 ? '+' : ''}${weekDelta!.toStringAsFixed(0)}% wk',
                      color: weekDelta! >= 0
                          ? AppColors.primary
                          : AppColors.duoOrange,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _HeroPill(
                    isDark: isDark,
                    icon: Icons.history_rounded,
                    label: 'Updated just now',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final Color? color;
  const _HeroPill({
    required this.isDark,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminTokens.textSecondary(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  final bool isDark;
  const _KpiCard({required this.kpi, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                kpi.label.toUpperCase(),
                style: AdminTokens.eyebrow(isDark).copyWith(fontSize: 10.5),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kpi.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kpi.accent.withValues(alpha: 0.25)),
                ),
                child: Icon(kpi.icon, size: 15, color: kpi.accent),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kpi.value, style: AdminTokens.metric(isDark)),
              const SizedBox(height: 4),
              Text(
                'Active items',
                style: AdminTokens.label(isDark).copyWith(
                  color: AdminTokens.textTertiary(isDark),
                  fontSize: 11,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsPanel extends ConsumerWidget {
  final bool isDark;
  const _AnalyticsPanel({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radius2xl),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTENT ACTIVITY',
                    style: AdminTokens.eyebrow(
                      isDark,
                    ).copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text('Last 7 days', style: AdminTokens.sectionTitle(isDark)),
                ],
              ),
              Wrap(
                spacing: 14,
                children: [
                  _LegendDot(
                    color: AppColors.primary,
                    label: 'Lessons',
                    isDark: isDark,
                  ),
                  _LegendDot(
                    color: AppColors.duoBlue,
                    label: 'Vocabulary',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 230,
            child: metricsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                ),
              ),
              error: (_, __) => _ChartEmpty(
                isDark: isDark,
                icon: Icons.cloud_off_rounded,
                message: 'Couldn\'t load engagement data',
              ),
              data: (m) {
                final hasData =
                    m.lessonsSeries.any((v) => v > 0) ||
                    m.vocabularySeries.any((v) => v > 0);
                if (!hasData) {
                  return _ChartEmpty(
                    isDark: isDark,
                    icon: Icons.show_chart_rounded,
                    message: 'No activity in the last 7 days',
                  );
                }
                return _Chart(
                  isDark: isDark,
                  lessons: m.lessonsSeries,
                  vocabulary: m.vocabularySeries,
                  dayLabels: m.dayLabels,
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }
}

class _ChartEmpty extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;
  const _ChartEmpty({
    required this.isDark,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AdminTokens.textMuted(isDark)),
          const SizedBox(height: 10),
          Text(
            message,
            style: AdminTokens.body(
              isDark,
            ).copyWith(fontSize: 13, color: AdminTokens.textTertiary(isDark)),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AdminTokens.label(isDark).copyWith(
            fontSize: 11.5,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  final bool isDark;
  final List<int> lessons;
  final List<int> vocabulary;
  final List<String> dayLabels;
  const _Chart({
    required this.isDark,
    required this.lessons,
    required this.vocabulary,
    required this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black12;
    final axisColor = AdminTokens.textMuted(isDark);

    final maxValue = [
      ...lessons,
      ...vocabulary,
    ].fold<int>(0, (m, v) => v > m ? v : m);
    final yMax = (maxValue < 4 ? 4 : maxValue + 1).toDouble();
    final rawInterval = (yMax / 4).ceilToDouble();
    final yInterval = rawInterval < 1.0 ? 1.0 : rawInterval;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: yMax,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: yInterval,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: axisColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= dayLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: axisColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF1A2030) : Colors.white,
            tooltipBorder: BorderSide(color: AdminTokens.border(isDark)),
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      color: AdminTokens.textPrimary(isDark),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          _series(
            lessons.map((e) => e.toDouble()).toList(),
            color: AppColors.primary,
            fillTop: 0.18,
          ),
          _series(
            vocabulary.map((e) => e.toDouble()).toList(),
            color: AppColors.duoBlue,
            fillTop: 0.10,
            barWidth: 3,
          ),
        ],
      ),
    );
  }

  LineChartBarData _series(
    List<double> ys, {
    required Color color,
    double fillTop = 0.15,
    double fillBottom = 0.0,
    bool isDashed = false,
    double barWidth = 3.5,
  }) {
    return LineChartBarData(
      spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
      isCurved: true,
      curveSmoothness: 0.32,
      color: color,
      barWidth: barWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3.5,
          color: color,
          strokeWidth: 2,
          strokeColor: isDark ? const Color(0xFF111621) : Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: fillTop),
            color.withValues(alpha: fillBottom),
          ],
        ),
      ),
      dashArray: isDashed ? [4, 4] : null,
    );
  }
}

class _ActivityPanel extends ConsumerWidget {
  final bool isDark;
  const _ActivityPanel({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radius2xl),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVITY',
                    style: AdminTokens.eyebrow(
                      isDark,
                    ).copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recent changes',
                    style: AdminTokens.sectionTitle(isDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTokens.sunken(isDark),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AdminTokens.border(isDark)),
                ),
                child: Text(
                  'Latest',
                  style: AdminTokens.label(isDark).copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0.4,
                    color: AdminTokens.textTertiary(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          metricsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            error: (_, __) => _ActivityEmpty(
              isDark: isDark,
              icon: Icons.cloud_off_rounded,
              message: 'Couldn\'t load recent activity',
            ),
            data: (m) {
              final items = m.recentActivity;
              if (items.isEmpty) {
                return _ActivityEmpty(
                  isDark: isDark,
                  icon: Icons.inbox_rounded,
                  message: 'No recent changes yet',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _ActivityRow(
                      isDark: isDark,
                      title: items[i].title,
                      subtitle:
                          '${items[i].subtitle} · ${_formatRelative(items[i].timestamp)}',
                      icon: items[i].icon,
                      color: items[i].color,
                    ),
                    if (i < items.length - 1)
                      Divider(color: AdminTokens.divider(isDark), height: 18),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 220.ms);
  }
}

String _formatRelative(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

class _ActivityEmpty extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;
  const _ActivityEmpty({
    required this.isDark,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: AdminTokens.textMuted(isDark)),
            const SizedBox(height: 10),
            Text(
              message,
              style: AdminTokens.body(
                isDark,
              ).copyWith(fontSize: 13, color: AdminTokens.textTertiary(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _ActivityRow({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AdminTokens.label(isDark).copyWith(
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                  color: AdminTokens.textTertiary(isDark),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AdminTokens.textMuted(isDark),
        ),
      ],
    );
  }
}

void _handleSeeding(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AdminTokens.overlay(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
      ),
      title: Text('Seed sample data?', style: AdminTokens.sectionTitle(isDark)),
      content: Text(
        'This will populate the app with rich sample categories, lessons, and letters. Existing data is preserved.',
        style: AdminTokens.body(isDark),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminTokens.textTertiary(isDark),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await seedAppContent(ref);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Content seeded successfully'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            ),
          ),
          child: const Text('Seed data'),
        ),
      ],
    ),
  );
}

Future<void> seedAppContent(WidgetRef ref) async {
  await ref.read(categoryNotifierProvider.notifier).seed();
  await ref.read(lettersProvider.notifier).seed();
  await ref.read(lessonNotifierProvider.notifier).seed();
  await ref.read(numbersProvider.notifier).seed();
  await ref.read(wordsProvider.notifier).seed();
  ref.invalidate(dashboardMetricsProvider);
}
