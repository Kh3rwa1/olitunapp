import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/dashboard_header.dart';
import 'widgets/dashboard_bento_grid.dart';
import 'widgets/dashboard_analytics_panel.dart';
import 'widgets/dashboard_activity_panel.dart';

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
              DashboardHeader(
                isDark: isDark,
                onSeedData: () => _handleSeeding(context, ref),
              ),
              SizedBox(height: isWide ? 32 : 24),
              DashboardBentoGrid(isDark: isDark, isWide: isWide),
              SizedBox(height: isWide ? 24 : 20),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: DashboardAnalyticsPanel(isDark: isDark),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: DashboardActivityPanel(isDark: isDark),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        DashboardAnalyticsPanel(isDark: isDark),
                        const SizedBox(height: 20),
                        DashboardActivityPanel(isDark: isDark),
                      ],
                    ),
            ],
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.015, end: 0),
        ),
      ),
    );
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
        title: Text(
          'Seed sample data?',
          style: AdminTokens.sectionTitle(isDark),
        ),
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
}
