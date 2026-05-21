import 'package:flutter/material.dart';

import '../../../../core/theme/admin_tokens.dart';

class AdminLessonBlockInfoBanner extends StatelessWidget {
  const AdminLessonBlockInfoBanner({
    super.key,
    required this.title,
    required this.message,
    required this.isDark,
  });

  final String title;
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.7),
              borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 18,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AdminTokens.bodyStrong(isDark).copyWith(
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : AdminTokens.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AdminTokens.label(isDark).copyWith(
                    color: AdminTokens.textSecondary(isDark),
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
