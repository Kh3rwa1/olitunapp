import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../providers/admin_auth_provider.dart';

class DashboardHeader extends ConsumerWidget {
  final bool isDark;
  final VoidCallback onSeedData;
  const DashboardHeader({super.key, required this.isDark, required this.onSeedData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 700;
    final hour = DateTime.now().hour;
    final greeting = hour < 5 ? 'Working late' : hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Wrap(
      spacing: 24, runSpacing: 18,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: compact ? double.infinity : width * 0.45,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text('OVERVIEW · LIVE', style: AdminTokens.eyebrow(isDark).copyWith(color: AppColors.primary)),
            ]),
            const SizedBox(height: 10),
            Text('$greeting, Admin', style: AdminTokens.display(isDark).copyWith(fontSize: compact ? 28 : 36)),
            const SizedBox(height: 6),
            Text('A snapshot of your curriculum, content, and engagement.', style: AdminTokens.body(isDark)),
          ]),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _action(Icons.refresh_rounded, 'Refresh data', isDark, () {
            ref.invalidate(categoryNotifierProvider);
            ref.invalidate(lessonNotifierProvider);
            ref.invalidate(dashboardMetricsProvider);
          }),
          const SizedBox(width: 10),
          _action(Icons.logout_rounded, 'Sign out', isDark, () async {
            await ref.read(adminAuthServiceProvider).signOut();
            ref.invalidate(adminAuthProvider);
            if (context.mounted) context.go('/admin/login');
          }),
          const SizedBox(width: 12),
          Material(color: Colors.transparent, child: InkWell(
            onTap: onSeedData,
            borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                boxShadow: AdminTokens.brandGlow(AppColors.primary, strength: 0.7),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_fix_high_rounded, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Seed data', style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2)),
              ]),
            ),
          )),
        ]),
      ],
    );
  }

  Widget _action(IconData icon, String tooltip, bool isDark, VoidCallback onTap) {
    return Tooltip(message: tooltip, child: Material(color: Colors.transparent, child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AdminTokens.raised(isDark),
          borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
          border: Border.all(color: AdminTokens.border(isDark)),
        ),
        child: Icon(icon, size: 18, color: AdminTokens.textSecondary(isDark)),
      ),
    )));
  }
}
