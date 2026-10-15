import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../admin_analytics_csv_exporter.dart';
import '../admin_analytics_models.dart';
import '../admin_analytics_providers.dart';

/// Range selector, density toggle, CSV export and refresh actions.
class AdminAnalyticsToolbar extends StatelessWidget {
  const AdminAnalyticsToolbar({
    super.key,
    required this.range,
    required this.density,
    required this.snapshot,
    required this.isDark,
    required this.onRefresh,
    required this.onRangeChanged,
    required this.onDensityChanged,
  });

  final AdminAnalyticsDateRange range;
  final AdminAnalyticsDensity density;
  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final VoidCallback onRefresh;
  final ValueChanged<AdminAnalyticsDateRange> onRangeChanged;
  final ValueChanged<AdminAnalyticsDensity> onDensityChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminTokens.space3,
      runSpacing: AdminTokens.space3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RangeSegmentedControl(
          range: range,
          isDark: isDark,
          onChanged: (preset) => _changeRange(context, preset),
        ),
        _ToolbarAction(
          label: density == AdminAnalyticsDensity.compact
              ? 'Compact'
              : 'Comfortable',
          icon: density == AdminAnalyticsDensity.compact
              ? Icons.density_small_rounded
              : Icons.density_medium_rounded,
          isDark: isDark,
          onTap: () {
            onDensityChanged(
              density == AdminAnalyticsDensity.compact
                  ? AdminAnalyticsDensity.comfortable
                  : AdminAnalyticsDensity.compact,
            );
          },
        ),
        _ToolbarAction(
          label: 'Export CSV',
          icon: Icons.download_rounded,
          isDark: isDark,
          onTap: () => _exportCsv(context),
        ),
        _ToolbarAction(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          isDark: isDark,
          onTap: onRefresh,
        ),
      ],
    );
  }

  Future<void> _changeRange(
    BuildContext context,
    AdminAnalyticsRangePreset preset,
  ) async {
    if (preset != AdminAnalyticsRangePreset.custom) {
      onRangeChanged(AdminAnalyticsDateRange(preset: preset));
      return;
    }

    final now = DateTime.now().toUtc();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.utc(2025),
      lastDate: adminAnalyticsDateOnly(now).add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: range.startFor(now),
        end: range.endFor(now),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AdminTokens.accent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    onRangeChanged(
      AdminAnalyticsDateRange.custom(start: picked.start, end: picked.end),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final csv = snapshot.toRollupsCsv();
    final now = DateTime.now().toUtc();
    final renderObject = context.findRenderObject();
    final sharePositionOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    await exportAnalyticsCsv(
      filename:
          'olitun-learning-analytics-${formatDateKey(range.startFor(now))}-to-${formatDateKey(range.endFor(now))}.csv',
      csv: csv,
      sharePositionOrigin: sharePositionOrigin,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          snapshot.rollupsForExport.isEmpty
              ? 'CSV header $analyticsCsvExportLabel. No rollups loaded for this range yet.'
              : 'CSV $analyticsCsvExportLabel with ${snapshot.rollupsForExport.length} rollup rows.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _RangeSegmentedControl extends StatelessWidget {
  const _RangeSegmentedControl({
    required this.range,
    required this.isDark,
    required this.onChanged,
  });

  final AdminAnalyticsDateRange range;
  final bool isDark;
  final ValueChanged<AdminAnalyticsRangePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Analytics date range selector',
      child: SegmentedButton<AdminAnalyticsRangePreset>(
        selected: {range.preset},
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AdminTokens.accentSoft(isDark)
                : AdminTokens.sunken(isDark);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AdminTokens.accent
                : AdminTokens.textSecondary(isDark);
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: AdminTokens.border(isDark)),
          ),
        ),
        segments: const [
          ButtonSegment(
            value: AdminAnalyticsRangePreset.seven,
            label: Text('7d'),
          ),
          ButtonSegment(
            value: AdminAnalyticsRangePreset.thirty,
            label: Text('30d'),
          ),
          ButtonSegment(
            value: AdminAnalyticsRangePreset.ninety,
            label: Text('90d'),
          ),
          ButtonSegment(
            value: AdminAnalyticsRangePreset.custom,
            label: Text('Custom'),
          ),
        ],
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AdminTokens.sunken(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AdminTokens.textSecondary(isDark)),
                const SizedBox(width: AdminTokens.space2),
                Text(label, style: AdminTokens.label(isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
