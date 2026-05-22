import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/admin_glass_card.dart';

class DashboardHealthPanel extends StatefulWidget {
  final bool isDark;
  const DashboardHealthPanel({super.key, required this.isDark});

  @override
  State<DashboardHealthPanel> createState() => _DashboardHealthPanelState();
}

class _DashboardHealthPanelState extends State<DashboardHealthPanel> {
  late Timer _timer;
  final Random _random = Random();
  int _latency = 24;
  int _sockets = 142;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _latency = 22 + _random.nextInt(5); // Jitters between 22ms and 26ms
          _sockets = 140 + _random.nextInt(5); // Jitters between 140 and 144
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminGlassCard(
      padding: const EdgeInsets.all(24),
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                        begin: 0.7,
                        end: 1.5,
                        duration: 1200.ms,
                        curve: Curves.easeInOutCubic,
                      )
                      .fadeOut(begin: 0.6),
                ],
              ),
              const SizedBox(width: 10),
              Text(
                'LIVE SYSTEM STATUS',
                style: AdminTokens.eyebrow(
                  widget.isDark,
                ).copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniKpi(
                  label: 'API LATENCY',
                  value: '$_latency ms',
                  icon: Icons.speed_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniKpi(
                  label: 'WS TUNNELS',
                  value: '$_sockets',
                  icon: Icons.lan_rounded,
                  color: AppColors.duoBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.015),
              borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
              border: Border.all(color: AdminTokens.border(widget.isDark)),
            ),
            child: Column(
              children: [
                _gridStatusRow('Auth Nodes', 'Operational', true),
                const SizedBox(height: 8),
                _gridStatusRow('DB Clusters', 'Operational', true),
                const SizedBox(height: 8),
                _gridStatusRow('Storage CDNs', 'Operational', true),
                const SizedBox(height: 8),
                _gridStatusRow('Razorpay Sync', 'Active', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniKpi({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(widget.isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AdminTokens.label(widget.isDark).copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AdminTokens.metricSmall(widget.isDark),
          ),
        ],
      ),
    );
  }

  Widget _gridStatusRow(String service, String status, bool active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          service,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AdminTokens.textSecondary(widget.isDark),
          ),
        ),
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
