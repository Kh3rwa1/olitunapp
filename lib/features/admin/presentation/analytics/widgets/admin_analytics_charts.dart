part of '../admin_analytics_screen.dart';

// Chart shells, heatmap primitives and empty-state surfaces.
class RetentionHeatmapCard extends StatelessWidget {
  const RetentionHeatmapCard({
    super.key,
    required this.snapshot,
    required this.isDark,
    required this.compact,
  });

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cohorts = snapshot.retentionCohorts;
    return Panel(
      isDark: isDark,
      compact: compact,
      child: Semantics(
        label: 'Retention cohort heatmap with ${cohorts.length} cohorts.',
        image: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHeader(
              title: 'Retention Cohorts',
              subtitle: 'Percent of learners returning in later weeks',
              isDark: isDark,
            ),
            const SizedBox(height: AdminTokens.space5),
            if (cohorts.isEmpty)
              SizedBox(
                height: 180,
                child: NoChartData(
                  isDark: isDark,
                  label: 'Raw events are needed for retention cohorts',
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeatmapLabel('Cohort', width: 120, isDark: isDark),
                        HeatmapLabel('Size', width: 70, isDark: isDark),
                        for (var week = 0; week < 6; week += 1)
                          HeatmapLabel('W$week', width: 70, isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: AdminTokens.space2),
                    for (final cohort in cohorts)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AdminTokens.space2,
                        ),
                        child: Row(
                          children: [
                            HeatmapLabel(
                              formatShortDate(cohort.weekStart),
                              width: 120,
                              isDark: isDark,
                              strong: true,
                            ),
                            HeatmapLabel(
                              cohort.size.toString(),
                              width: 70,
                              isDark: isDark,
                            ),
                            for (final value in cohort.weekRetention)
                              HeatmapCell(value: value, isDark: isDark),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.left,
    required this.right,
    required this.spacing,
  });

  final Widget left;
  final Widget right;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: spacing),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    required this.child,
    required this.isDark,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final String semanticsLabel;
  final Widget child;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Panel(
      isDark: isDark,
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: title, subtitle: subtitle, isDark: isDark),
          SizedBox(height: compact ? AdminTokens.space4 : AdminTokens.space5),
          SizedBox(
            height: compact ? 246 : 300,
            child: Semantics(label: semanticsLabel, image: true, child: child),
          ),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    required this.isDark,
    this.compact = false,
  });

  final Widget child;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        compact ? AdminTokens.space4 : AdminTokens.space5,
      ),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: child,
    );
  }
}

class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AdminTokens.sectionTitle(isDark)),
        const SizedBox(height: AdminTokens.space1),
        Text(subtitle, style: AdminTokens.body(isDark)),
      ],
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.isDark,
    this.compact = false,
  });

  final IconData icon;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 44 : 52,
      height: compact ? 44 : 52,
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Icon(icon, color: AdminTokens.accent),
    );
  }
}

class LegendList extends StatelessWidget {
  const LegendList({
    super.key,
    required this.entries,
    required this.colors,
    required this.isDark,
    required this.total,
    required this.compact,
  });

  final List<MapEntry<String, int>> entries;
  final List<Color> colors;
  final bool isDark;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i += 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: compact ? AdminTokens.space2 : AdminTokens.space3,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AdminTokens.space2),
                Expanded(
                  child: Text(
                    entries[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTokens.label(
                      isDark,
                    ).copyWith(color: AdminTokens.textPrimary(isDark)),
                  ),
                ),
                Text(
                  '${(entries[i].value / total * 100).round()}% · ${entries[i].value}',
                  style: AdminTokens.label(isDark),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class HeatmapLabel extends StatelessWidget {
  const HeatmapLabel(
    this.label, {
    super.key,
    required this.width,
    required this.isDark,
    this.strong = false,
  });

  final String label;
  final double width;
  final bool isDark;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style:
            (strong
                    ? AdminTokens.bodyStrong(isDark)
                    : AdminTokens.label(isDark))
                .copyWith(fontSize: 12),
      ),
    );
  }
}

class HeatmapCell extends StatelessWidget {
  const HeatmapCell({super.key, required this.value, required this.isDark});

  final double value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      AdminTokens.sunken(isDark),
      AdminTokens.accent,
      value.clamp(0, 1),
    )!;
    return Semantics(
      label: '${(value * 100).round()} percent retained',
      child: Container(
        width: 58,
        height: 38,
        margin: const EdgeInsets.only(right: AdminTokens.space3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
          border: Border.all(color: AdminTokens.border(isDark)),
        ),
        child: Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: value > 0.48
                ? Colors.white
                : AdminTokens.textPrimary(isDark),
          ),
        ),
      ),
    );
  }
}

class NoChartData extends StatelessWidget {
  const NoChartData({super.key, required this.isDark, required this.label});

  final bool isDark;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: Icons.insights_rounded, isDark: isDark),
          const SizedBox(height: AdminTokens.space3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AdminTokens.bodyStrong(isDark),
          ),
        ],
      ),
    );
  }
}

class EmptyAnalyticsCard extends StatelessWidget {
  const EmptyAnalyticsCard({
    super.key,
    required this.isDark,
    required this.compact,
  });

  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Panel(
      isDark: isDark,
      compact: compact,
      child: Row(
        children: [
          IconBadge(
            icon: Icons.schedule_rounded,
            isDark: isDark,
            compact: compact,
          ),
          const SizedBox(width: AdminTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for first rollup',
                  style: AdminTokens.cardTitle(isDark),
                ),
                const SizedBox(height: AdminTokens.space1),
                Text(
                  'The nightly pipeline is connected. This dashboard will populate after learning events are aggregated.',
                  style: AdminTokens.body(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
