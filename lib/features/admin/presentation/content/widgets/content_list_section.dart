import 'package:flutter/material.dart';

import 'package:itun/features/admin/domain/content_badge_resolver.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/shared/models/content_item.dart';
import 'content_list_tile.dart';

class ContentListSection extends StatelessWidget {
  final ScrollController scrollController;
  final List<ContentItem> items;
  final Set<String> selectedIds;
  final List<CategoryEntity> categories;
  final String? defaultCategoryId;
  final bool isDark;
  final bool isWideScreen;
  final bool supportsPublished;
  final bool supportsPremium;
  final bool supportsTags;
  final IconData icon;
  final ValueChanged<ContentItem> onEditItem;
  final ValueChanged<ContentItem> onDeleteItem;
  final ValueChanged<ContentItem>? onEditBlocks;
  final void Function(String id, bool selected) onToggleSelect;

  const ContentListSection({
    super.key,
    required this.scrollController,
    required this.items,
    required this.selectedIds,
    required this.categories,
    required this.defaultCategoryId,
    required this.isDark,
    required this.isWideScreen,
    required this.supportsPublished,
    required this.supportsPremium,
    required this.supportsTags,
    required this.icon,
    required this.onEditItem,
    required this.onDeleteItem,
    this.onEditBlocks,
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
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIds.contains(item.id);
        final badgeType = _resolveBadge(item);

        return ContentListTile(
          item: item,
          index: index,
          isSelected: isSelected,
          isDark: isDark,
          supportsPublished: supportsPublished,
          supportsPremium: supportsPremium,
          supportsTags: supportsTags,
          badgeType: badgeType,
          fallbackIcon: icon,
          onSelectChanged: (val) => onToggleSelect(item.id, val == true),
          onTap: () => onEditItem(item),
          onEditMetadata: () => onEditItem(item),
          onDelete: () => onDeleteItem(item),
          onEditBlocks: onEditBlocks != null ? () => onEditBlocks!(item) : null,
        );
      },
    );
  }
}
