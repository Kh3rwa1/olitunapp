import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';

/// Informational banner shown when the Numbers category is selected in the
/// lessons content screen, guiding the admin to the dedicated 100 Numbers management database.
class NumberDiscoveryBanner extends StatelessWidget {
  final bool isDark;
  final bool isWideScreen;

  const NumberDiscoveryBanner({
    super.key,
    required this.isDark,
    required this.isWideScreen,
  });

  /// Helper to check if a category ID refers to the Numbers category.
  static bool isNumberCategory(String? categoryId, List<dynamic> categories) {
    if (categoryId == null) return false;
    for (final c in categories) {
      if (c.id == categoryId) {
        final iconName = c.iconName?.toString().toLowerCase();
        final title = c.titleLatin.toString().toLowerCase();
        final id = c.id.toString().toLowerCase();
        if (iconName == 'numbers' ||
            id.contains('number') ||
            title.contains('number')) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 32 : 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Looking for the 100 Ol Chiki Numbers (0-100)? Numbers with numerals, pronunciation, and stroke tracing are managed in the 100 Numbers Database.',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => context.go('/admin/numbers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                ),
              ),
              icon: const Icon(Icons.pin_rounded, size: 18),
              label: const Text(
                'Manage 100 Numbers',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
