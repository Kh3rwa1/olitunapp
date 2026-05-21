import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../lessons/domain/entities/lesson_entity.dart';
import 'admin_form_widgets.dart';
import 'admin_glass_card.dart';

enum AdminContentKind { vocabulary, sentences }

CategoryEntity? findAdminContentCategory(
  List<CategoryEntity> categories,
  AdminContentKind kind,
) {
  final ids = kind == AdminContentKind.vocabulary
      ? const {'cat_vocab', 'cat_words', 'seed_words'}
      : const {'cat_sentences', 'seed_sentences'};
  final titles = kind == AdminContentKind.vocabulary
      ? const {'vocabulary', 'words'}
      : const {'sentences'};

  for (final category in categories) {
    if (ids.contains(category.id)) return category;
  }
  for (final category in categories) {
    if (titles.contains(category.titleLatin.trim().toLowerCase())) {
      return category;
    }
  }
  return null;
}

List<LessonEntity> filterAdminContentLessons(
  List<LessonEntity> lessons,
  CategoryEntity? category,
  AdminContentKind kind,
) {
  final candidateIds = kind == AdminContentKind.vocabulary
      ? <String>{'cat_vocab', 'cat_words', 'seed_words'}
      : <String>{'cat_sentences', 'seed_sentences'};
  if (category != null) candidateIds.add(category.id);

  final filtered =
      lessons
          .where((lesson) => candidateIds.contains(lesson.categoryId))
          .toList()
        ..sort((a, b) {
          final order = a.order.compareTo(b.order);
          if (order != 0) return order;
          return a.titleLatin.compareTo(b.titleLatin);
        });
  return filtered;
}

List<String> adminContentCategorySuggestions({
  required Iterable<String?> existingCategories,
  required Iterable<LessonEntity> lessons,
}) {
  final values = <String>{};
  for (final category in existingCategories) {
    final value = category?.trim();
    if (value != null && value.isNotEmpty) values.add(value);
  }
  for (final lesson in lessons) {
    final title = lesson.titleLatin.trim();
    if (title.isNotEmpty) values.add(title);
  }
  final sorted = values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return sorted;
}

class AdminContentSubcategories extends StatelessWidget {
  const AdminContentSubcategories({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.lessons,
    required this.isDark,
    required this.onAdd,
    required this.onSeed,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptyMessage;
  final List<LessonEntity> lessons;
  final bool isDark;
  final VoidCallback onAdd;
  final VoidCallback onSeed;
  final ValueChanged<LessonEntity> onEdit;
  final ValueChanged<LessonEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminGlassCard(
      glass: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminTokens.cardTitle(isDark)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AdminTokens.body(
                        isDark,
                      ).copyWith(color: AdminTokens.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
              AdminPrimaryButton(
                label: 'Add Subcategory',
                icon: Icons.add_rounded,
                compact: true,
                onTap: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (lessons.isEmpty)
            _MissingSubcategoriesState(
              title: emptyTitle,
              message: emptyMessage,
              isDark: isDark,
              onSeed: onSeed,
            )
          else
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 2),
                itemCount: lessons.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  return _SubcategoryCard(
                    lesson: lesson,
                    isDark: isDark,
                    onEdit: () => onEdit(lesson),
                    onContent: () =>
                        context.go('/admin/lessons/content/${lesson.id}'),
                    onDelete: () => onDelete(lesson),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MissingSubcategoriesState extends StatelessWidget {
  const _MissingSubcategoriesState({
    required this.title,
    required this.message,
    required this.isDark,
    required this.onSeed,
  });

  final String title;
  final String message;
  final bool isDark;
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_off_rounded,
            color: AdminTokens.textTertiary(isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AdminTokens.bodyStrong(isDark)),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: AdminTokens.label(isDark).copyWith(
                    color: AdminTokens.textSecondary(isDark),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          AdminSecondaryButton(
            label: 'Seed Default Data',
            icon: Icons.cloud_download_rounded,
            onTap: onSeed,
          ),
        ],
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  const _SubcategoryCard({
    required this.lesson,
    required this.isDark,
    required this.onEdit,
    required this.onContent,
    required this.onDelete,
  });

  final LessonEntity lesson;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onContent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.folder_copy_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.titleLatin.isEmpty
                          ? 'Untitled Subcategory'
                          : lesson.titleLatin,
                      style: AdminTokens.bodyStrong(isDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.titleOlChiki.isNotEmpty)
                      Text(
                        lesson.titleOlChiki,
                        style: AdminTokens.label(isDark).copyWith(
                          color: AdminTokens.textSecondary(isDark),
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaChip(
                icon: Icons.sort_rounded,
                label: 'Order ${lesson.order}',
                isDark: isDark,
              ),
              _MetaChip(
                icon: Icons.school_rounded,
                label: lesson.level,
                isDark: isDark,
              ),
              _MetaChip(
                icon: Icons.layers_rounded,
                label: '${lesson.blocks.length} blocks',
                isDark: isDark,
              ),
              _MetaChip(
                icon: lesson.isActive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                label: lesson.isActive ? 'Active' : 'Hidden',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AdminIconAction(
                icon: Icons.edit_rounded,
                tooltip: 'Edit metadata',
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              AdminIconAction(
                icon: Icons.dashboard_customize_rounded,
                tooltip: 'Edit content',
                onTap: onContent,
              ),
              const Spacer(),
              AdminIconAction(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete',
                destructive: true,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminTokens.baseTint(isDark),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AdminTokens.textTertiary(isDark)),
          const SizedBox(width: 5),
          Text(
            label,
            style: AdminTokens.label(isDark).copyWith(
              fontSize: 10.5,
              letterSpacing: 0,
              color: AdminTokens.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
