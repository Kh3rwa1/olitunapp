import 'package:flutter/material.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/admin_form_widgets.dart';

class AdminDangerZoneSection extends StatelessWidget {
  const AdminDangerZoneSection({
    super.key,
    required this.onBackup,
    required this.onWipe,
  });

  final VoidCallback onBackup;
  final VoidCallback onWipe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 620;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Database & Seeding',
                style: AdminTokens.bodyStrong(isDark).copyWith(
                  color: isDark ? AppColors.error : AppColors.duoRedDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create an admin-only backup, wipe content collections, clear the local Hive cache, and run a fresh seeder.',
                style: AdminTokens.body(isDark),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
            children: [
              AdminSecondaryButton(
                label: 'Backup',
                icon: Icons.cloud_download_rounded,
                onTap: onBackup,
              ),
              AdminSecondaryButton(
                label: 'Wipe & Re-seed',
                icon: Icons.delete_forever_rounded,
                destructive: true,
                onTap: onWipe,
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}
