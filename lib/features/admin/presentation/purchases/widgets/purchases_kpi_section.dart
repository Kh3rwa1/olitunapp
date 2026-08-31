import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/admin/domain/purchase_metrics_calculator.dart';

class PurchasesKpiSection extends StatelessWidget {
  final bool isDark;
  final PurchaseMetricsResult metrics;

  const PurchasesKpiSection({
    super.key,
    required this.isDark,
    required this.metrics,
  });

  static final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final kpis = [
      _KpiItem(
        title: 'Net Revenue',
        value: _inrCurrencyFormat.format(metrics.netRevenueInr),
        subtitle: metrics.isSampledOrPartial
            ? 'Loaded (gross ${_inrCurrencyFormat.format(metrics.grossCollectedInr)} - ref ${_inrCurrencyFormat.format(metrics.refundedInr)})'
            : 'Gross ${_inrCurrencyFormat.format(metrics.grossCollectedInr)} - Refunds ${_inrCurrencyFormat.format(metrics.refundedInr)}',
        tooltip:
            'Net = Gross Collected - Confirmed Refunds. Does not double-subtract.',
        icon: Icons.currency_rupee_rounded,
        accentColor: AppColors.primary,
      ),
      _KpiItem(
        title: 'Verified Unlocks',
        value: '${metrics.activePaidCount + metrics.reviewUnlockCount}',
        subtitle:
            '${metrics.activePaidCount} Paid (${metrics.verifiedPaidShare.toStringAsFixed(0)}%) · ${metrics.reviewUnlockCount} Review',
        tooltip:
            'Combined verified course unlock volume across Razorpay and Review flows.',
        icon: Icons.lock_open_rounded,
        accentColor: Colors.blueAccent,
      ),
      _KpiItem(
        title: 'Confirmed Refunds',
        value: metrics.refundedCount.toString(),
        subtitle: _inrCurrencyFormat.format(metrics.refundedInr),
        tooltip:
            'Total refunded transactions recorded. Amounts subtracted once from gross revenue.',
        icon: Icons.replay_circle_filled_rounded,
        accentColor: Colors.orange,
      ),
      _KpiItem(
        title: 'Failed Payments',
        value: metrics.failedCount.toString(),
        subtitle: 'Abandoned / Failed',
        tooltip:
            'Uncompleted payment attempts. Never counted in collected revenue.',
        icon: Icons.cancel_outlined,
        accentColor: AppColors.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        if (totalWidth >= 900) {
          return Row(
            children: kpis
                .map(
                  (kpi) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildKpiCard(kpi, isDark),
                    ),
                  ),
                )
                .toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kpis
                .map(
                  (kpi) => Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    child: _buildKpiCard(kpi, isDark),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiItem kpi, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  kpi.title,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTokens.label(isDark).copyWith(
                    color: AdminTokens.textMuted(isDark),
                    fontSize: 11,
                  ),
                ),
              ),
              Icon(kpi.icon, size: 16, color: kpi.accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            kpi.value,
            style: AdminTokens.sectionTitle(
              isDark,
            ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (kpi.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              kpi.subtitle!,
              overflow: TextOverflow.ellipsis,
              style: AdminTokens.body(
                isDark,
              ).copyWith(fontSize: 10, color: AdminTokens.textMuted(isDark)),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final String? subtitle;
  final String? tooltip;
  final IconData icon;
  final Color accentColor;

  _KpiItem({
    required this.title,
    required this.value,
    this.subtitle,
    this.tooltip,
    required this.icon,
    required this.accentColor,
  });
}
