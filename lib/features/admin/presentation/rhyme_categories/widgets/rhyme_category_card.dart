import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../rhymes/domain/rhyme_category_model.dart';
import '../../widgets/admin_form_widgets.dart';

class RhymeCategoryCard extends StatelessWidget {
  final RhymeCategoryModel category;
  final List<RhymeSubcategoryModel> subcategories;
  final VoidCallback onAddSubcategory;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final ValueChanged<RhymeSubcategoryModel> onEditSubcategory;
  final ValueChanged<RhymeSubcategoryModel> onDeleteSubcategory;

  const RhymeCategoryCard({
    super.key,
    required this.category,
    required this.subcategories,
    required this.onAddSubcategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onEditSubcategory,
    required this.onDeleteSubcategory,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              '${category.nameOlChiki} · ${subcategories.length} subcategories',
              style: AdminTokens.label(isDark),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminIconAction(
                icon: Icons.add_circle_outline_rounded,
                tooltip: 'Add subcategory',
                onTap: onAddSubcategory,
              ),
              const SizedBox(width: 6),
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
          children: subcategories.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                    child: Text(
                      'No subcategories yet. Tap + to add.',
                      style: AdminTokens.label(
                        isDark,
                      ).copyWith(color: AdminTokens.textTertiary(isDark)),
                    ),
                  ),
                ]
              : subcategories
                    .map(
                      (sub) => Container(
                        margin: const EdgeInsets.fromLTRB(64, 0, 16, 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AdminTokens.sunken(isDark),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                          border: Border.all(color: AdminTokens.border(isDark)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 16,
                              color: AdminTokens.textTertiary(isDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sub.nameLatin,
                                    style: AdminTokens.bodyStrong(isDark),
                                  ),
                                  Text(
                                    sub.nameOlChiki,
                                    style: AdminTokens.label(isDark),
                                  ),
                                ],
                              ),
                            ),
                            AdminIconAction(
                              icon: Icons.edit_rounded,
                              tooltip: 'Edit',
                              onTap: () => onEditSubcategory(sub),
                            ),
                            const SizedBox(width: 6),
                            AdminIconAction(
                              icon: Icons.delete_outline_rounded,
                              tooltip: 'Delete',
                              destructive: true,
                              onTap: () => onDeleteSubcategory(sub),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
        ),
      ),
    );
  }
}
