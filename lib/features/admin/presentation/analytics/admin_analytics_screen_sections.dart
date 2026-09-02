part of 'admin_analytics_screen.dart';

// Range status row and status chips shown beneath the analytics header.
class _RangeStatus extends StatelessWidget {
  const _RangeStatus({
    required this.range,
    required this.snapshot,
    required this.isDark,
  });

  final AdminAnalyticsDateRange range;
  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AdminTokens.space3,
          runSpacing: AdminTokens.space2,
          children: [
            _StatusChip(
              isDark: isDark,
              icon: Icons.date_range_rounded,
              label: '${range.label(now)} (UTC)',
            ),
            _StatusChip(
              isDark: isDark,
              icon: Icons.storage_rounded,
              label: '${snapshot.rollupRows} rollups',
            ),
            _StatusChip(
              isDark: isDark,
              icon: Icons.bolt_rounded,
              label: snapshot.isSampled
                  ? '${snapshot.eventRows} raw events (Sampled 1,000 max)'
                  : '${snapshot.eventRows} raw events',
            ),
            _StatusChip(
              isDark: isDark,
              icon: snapshot.completeness == AnalyticsDataCompleteness.complete
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              label: 'Status: ${snapshot.completeness.name.toUpperCase()}',
            ),
          ],
        ),
        if (snapshot.completeness == AnalyticsDataCompleteness.partial ||
            snapshot.isSampled) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(
                color: Colors.amber.withValues(alpha: isDark ? 0.35 : 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sampled Data Window: Raw events query reached the 1,000 document threshold. DAU and unique user counts reflect the sampled active population, while total volume is derived from nightly server rollups.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.amber[200] : Colors.amber[900],
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.isDark,
    required this.icon,
    required this.label,
  });

  final bool isDark;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AdminTokens.accent),
          const SizedBox(width: AdminTokens.space2),
          Text(
            label,
            style: AdminTokens.label(
              isDark,
            ).copyWith(color: AdminTokens.textPrimary(isDark)),
          ),
        ],
      ),
    );
  }
}
