import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../providers/admin_auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      ),
      child: Stack(
        children: [
          // Subtle background decoration
          if (isDark)
            Positioned(
              top: -100,
              right: -100,
              child:
                  Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 10.seconds,
                      ),
            ),

          _buildOverview(context, ref, isDark),
        ],
      ),
    );
  }

  Widget _buildOverview(BuildContext context, WidgetRef ref, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(context, ref, isDark),
          const SizedBox(height: 40),

          // Bento Grid Layout
          _buildBentoGrid(context, ref, isDark),

          const SizedBox(height: 40),

          // Analytics Section
          _buildAnalyticsSection(context, ref, isDark),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.02, end: 0);
  }

  Widget _buildHeroHeader(BuildContext context, WidgetRef ref, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SECURE ACCESS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                color: isDark ? Colors.white : AppColors.primaryDark,
                height: 0.9,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderAction(
              icon: Icons.logout_rounded,
              onTap: () => ref.read(adminAuthProvider.notifier).logout(),
              isDark: isDark,
              tooltip: 'Sign Out',
            ),
            const SizedBox(width: 12),
            DuoButton(
              text: 'SEED DATA',
              icon: Icons.auto_fix_high_rounded,
              color: AppColors.primary,
              width: 160,
              height: 48,
              borderRadius: 12,
              onPressed: () => _handleSeeding(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, WidgetRef ref, bool isDark) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final lettersAsync = ref.watch(lettersProvider);
    final lessonsAsync = ref.watch(lessonNotifierProvider);
    final wordsAsync = ref.watch(wordsProvider);
    final numbersAsync = ref.watch(numbersProvider);
    final quizzesAsync = ref.watch(quizzesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.5,
          children: [
            _buildPremiumStatCard(
              title: 'Curriculum',
              value: categoriesAsync.when(
                data: (l) => l.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              subtitle: 'Categories Active',
              icon: Icons.category_rounded,
              color: AppColors.duoGreen,
              isDark: isDark,
            ),
            _buildPremiumStatCard(
              title: 'Alphabets',
              value: lettersAsync.when(
                data: (l) => l.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              subtitle: 'Total Letters',
              icon: Icons.text_fields_rounded,
              color: AppColors.duoOrange,
              isDark: isDark,
            ),
            _buildPremiumStatCard(
              title: 'Lessons',
              value: lessonsAsync.when(
                data: (l) => l.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              subtitle: 'Educational Units',
              icon: Icons.book_rounded,
              color: AppColors.duoBlue,
              isDark: isDark,
            ),
            _buildPremiumStatCard(
              title: 'Vocabulary',
              value: wordsAsync.when(
                data: (l) => l.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              subtitle: 'Words & Phrases',
              icon: Icons.menu_book_rounded,
              color: AppColors.duoYellow,
              isDark: isDark,
            ),
            _buildPremiumStatCard(
              title: 'Numerals',
              value: numbersAsync.when(
                data: (l) => l.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              subtitle: 'Number Objects',
              icon: Icons.format_list_numbered_rounded,
              color: AppColors.duoOrange,
              isDark: isDark,
            ),
            _buildPremiumStatCard(
              title: 'Evaluation',
              value: quizzesAsync.when(
                data: (l) => l.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              subtitle: 'Quizzes Created',
              icon: Icons.quiz_rounded,
              color: AppColors.duoBlue,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.6), size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _buildAnalyticsSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
        ),
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
                    'ENGAGEMENT INSIGHTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark ? AppColors.primary : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Content performance metrics',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      size: 16,
                      color: AppColors.duoGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+12% overall growth',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Chart placeholder / real chart
          SizedBox(height: 250, child: _buildMainChart(isDark)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildMainChart(bool isDark) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                if (value.toInt() < 0 || value.toInt() >= days.length) {
                  return const SizedBox();
                }
                return Text(
                  days[value.toInt()],
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 3),
              FlSpot(1, 4),
              FlSpot(2, 3.5),
              FlSpot(3, 5),
              FlSpot(4, 4),
              FlSpot(5, 6),
              FlSpot(6, 5.5),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: const [
              FlSpot(0, 2),
              FlSpot(1, 2.5),
              FlSpot(2, 2.2),
              FlSpot(3, 3),
              FlSpot(4, 3.5),
              FlSpot(5, 3),
              FlSpot(6, 4),
            ],
            isCurved: true,
            color: AppColors.duoGreen,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.duoGreen.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSeeding(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          'Seed Sample Data?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'This will populate the app with rich sample categories, lessons, and letters. It will not delete existing data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await seedAppContent(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Content seeded successfully! ✨'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.duoGreen,
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('SEED DATA'),
          ),
        ],
      ),
    );
  }
}

// Extension to help with seeding (imported from providers.dart typically)
Future<void> seedAppContent(WidgetRef ref) async {
  // Mock seeding logic - calls existing providers
  await ref.read(categoryNotifierProvider.notifier).seed();
  await ref.read(lettersProvider.notifier).seed();
  await ref.read(lessonNotifierProvider.notifier).seed();
  await ref.read(numbersProvider.notifier).seed();
  await ref.read(wordsProvider.notifier).seed();
}
