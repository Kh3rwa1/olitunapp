import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';

class DashboardEmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;

  const DashboardEmptyState({
    super.key,
    required this.isDark,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: AdminTokens.textMuted(isDark)),
            const SizedBox(height: 10),
            Text(
              message,
              style: AdminTokens.body(isDark).copyWith(
                fontSize: 13,
                color: AdminTokens.textTertiary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
