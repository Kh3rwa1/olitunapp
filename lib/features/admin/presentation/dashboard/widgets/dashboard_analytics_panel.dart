import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import 'analytics_chart.dart';
import 'dashboard_empty_state.dart';

class DashboardAnalyticsPanel extends ConsumerStatefulWidget {
  final bool isDark;
  const DashboardAnalyticsPanel({super.key, required this.isDark});

  @override
  ConsumerState<DashboardAnalyticsPanel> createState() => _DashboardAnalyticsPanelState();
}

class _DashboardAnalyticsPanelState extends ConsumerState<DashboardAnalyticsPanel> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTokens.raised(widget.isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radius2xl),
        border: Border.all(color: AdminTokens.border(widget.isDark)),
        boxShadow: AdminTokens.raisedShadow(widget.isDark),
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
                      widget.isDark,
                    ).copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text('Last 7 days', style: AdminTokens.sectionTitle(widget.isDark)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: SlidingSegmentController(
                      selectedIndex: _selectedSegment,
                      options: const ['Overview', 'Lessons', 'Vocabulary'],
                      isDark: widget.isDark,
                      onChanged: (index) {
                        setState(() {
                          _selectedSegment = index;
                        });
                      },
                    ),
                  ),
                ),
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
              error: (_, _) => DashboardEmptyState(
                isDark: widget.isDark,
                icon: Icons.cloud_off_rounded,
                message: 'Couldn\'t load engagement data',
              ),
              data: (m) {
                final hasData =
                    m.lessonsSeries.any((v) => v > 0) ||
                    m.vocabularySeries.any((v) => v > 0);
                if (!hasData) {
                  return DashboardEmptyState(
                    isDark: widget.isDark,
                    icon: Icons.show_chart_rounded,
                    message: 'No activity in the last 7 days',
                  );
                }
                return AnalyticsChart(
                  isDark: widget.isDark,
                  lessons: m.lessonsSeries,
                  vocabulary: m.vocabularySeries,
                  dayLabels: m.dayLabels,
                  selectedSegment: _selectedSegment,
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }
}

class SlidingSegmentController extends StatelessWidget {
  final int selectedIndex;
  final List<String> options;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const SlidingSegmentController({
    super.key,
    required this.selectedIndex,
    required this.options,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0F18) : AdminTokens.neutral75,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 6) / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: selectedIndex * width,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2638)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(options.length, (index) {
                  final isSelected = selectedIndex == index;
                  return SizedBox(
                    width: width,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(index),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AdminTokens.textPrimary(isDark)
                                : AdminTokens.textSecondary(isDark),
                          ),
                          child: Text(options[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
