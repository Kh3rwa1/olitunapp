import 'package:flutter/material.dart';

import 'package:itun/features/admin/domain/content_badge_resolver.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/shared/models/content_item.dart';
import 'content_grid_card.dart';

class ContentGridSection extends StatelessWidget {
  final ScrollController scrollController;
  final List<ContentItem> items;
  final Set<String> selectedIds;
  final List<CategoryEntity> categories;
  final String? defaultCategoryId;
  final bool isDark;
  final bool isWideScreen;
  final bool supportsPremium;
  final ValueChanged<ContentItem> onEditItem;
  final ValueChanged<ContentItem> onDeleteItem;
  final void Function(String id, bool selected) onToggleSelect;

  const ContentGridSection({
    super.key,
    required this.scrollController,
    required this.items,
    required this.selectedIds,
    required this.categories,
    required this.defaultCategoryId,
    required this.isDark,
    required this.isWideScreen,
    required this.supportsPremium,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleSelect,
  });

  ContentBadgeType _resolveBadge(ContentItem item) {
    final itemCategoryId = item.categoryId.isNotEmpty ? item.categoryId : null;
    final effectiveCategoryId = itemCategoryId ?? defaultCategoryId;
    CategoryEntity? category;
    if (effectiveCategoryId != null) {
      for (final cat in categories) {
        if (cat.id == effectiveCategoryId) {
          category = cat;
          break;
        }
      }
    }
    return resolveBadgeType(
      kind: item.kind,
      categoryId: effectiveCategoryId,
      categorySlug: category?.titleLatin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 6 : 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIds.contains(item.id);
        final badgeType = _resolveBadge(item);

        return ContentGridCard(
          item: item,
          index: index,
          isSelected: isSelected,
          isDark: isDark,
          supportsPremium: supportsPremium,
          badgeType: badgeType,
          onSelectChanged: (val) => onToggleSelect(item.id, val == true),
          onTap: () => onEditItem(item),
          onDelete: () => onDeleteItem(item),
        );
      },
    );
  }
}
