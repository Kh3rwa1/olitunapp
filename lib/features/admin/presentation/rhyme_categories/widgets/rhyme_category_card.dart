import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../rhymes/domain/rhyme_category_model.dart';
import '../../widgets/admin_form_widgets.dart';
import '../../widgets/admin_glass_card.dart';

class RhymeCategoryCard extends StatelessWidget {
  final RhymeCategoryModel category;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;

  const RhymeCategoryCard({
    super.key,
    required this.category,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'agriculture':
        return Icons.agriculture_rounded;
      case 'local_florist':
        return Icons.local_florist_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'child_friendly':
        return Icons.child_friendly_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'group':
        return Icons.group_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminGlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: AdminTokens.radiusLg,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AdminTokens.accentSoft(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
            border: Border.all(color: AdminTokens.accentBorder(isDark)),
          ),
          child: Icon(
            _getIconFromName(category.iconName),
            color: AdminTokens.accent,
          ),
        ),
        title: Text(category.nameLatin, style: AdminTokens.cardTitle(isDark)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            category.nameOlChiki,
            style: AdminTokens.label(isDark),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminIconAction(
              icon: Icons.edit_rounded,
              tooltip: 'Edit',
              onTap: onEditCategory,
            ),
            const SizedBox(width: 6),
            AdminIconAction(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              destructive: true,
              onTap: onDeleteCategory,
            ),
          ],
        ),
      ),
    );
  }
}
