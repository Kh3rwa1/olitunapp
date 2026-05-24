import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../lessons/domain/entities/lesson_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_form_widgets.dart';
import 'widgets/lesson_card.dart';
import 'widgets/lesson_form_sheet.dart';

class AdminLessonsScreen extends ConsumerStatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  ConsumerState<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends ConsumerState<AdminLessonsScreen> {
  String? _lastRouteCategoryId;
  String? _selectedCategoryId;
  String _searchQuery = '';

  bool _isStandardCategory(CategoryEntity? category) {
    if (category == null) return false;
    final id = category.id;
    final lowerTitle = category.titleLatin.toLowerCase();
    return id == 'cat_vocab' ||
        id == 'cat_words' ||
        id == 'seed_words' ||
        lowerTitle.contains('vocab') ||
        lowerTitle.contains('word') ||
        id == 'cat_sentences' ||
        id == 'seed_sentences' ||
        lowerTitle.contains('sentence') ||
        id == 'cat_alphabets' ||
        id == 'cat_letters' ||
        id == 'letters' ||
        lowerTitle.contains('alphabet') ||
        lowerTitle.contains('letter') ||
        id == 'cat_numbers' ||
        lowerTitle.contains('number');
  }

  @override
  Widget build(BuildContext context) {
    // Sync with sidebar selected category ID
    final routeCategoryId = GoRouterState.of(
      context,
    ).uri.queryParameters['categoryId'];
    if (routeCategoryId != _lastRouteCategoryId) {
      _lastRouteCategoryId = routeCategoryId;
      _selectedCategoryId = routeCategoryId;
    }

    final lessonsAsync = ref.watch(lessonNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    final categories = categoriesAsync.value ?? const <CategoryEntity>[];
    final activeCategory = _selectedCategoryId != null
        ? categories.firstWhere(
            (c) => c.id == _selectedCategoryId,
            orElse: () => const CategoryEntity(
              id: '',
              titleLatin: 'Lessons',
              titleOlChiki: '',
              description: '',
            ),
          )
        : null;

    final headerTitle = activeCategory != null && activeCategory.id.isNotEmpty
        ? '${activeCategory.titleLatin} Subcategories'
        : 'Subcategories';

    final headerSubtitle =
        activeCategory != null && activeCategory.id.isNotEmpty
        ? 'Create and manage subcategories for ${activeCategory.titleLatin}'
        : 'Create and manage subcategories';

    final headerEyebrow = activeCategory != null && activeCategory.id.isNotEmpty
        ? 'CONTENT · ${activeCategory.titleLatin.toUpperCase()}'
        : 'CONTENT · SUBCATEGORIES';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 32 : 16,
        vertical: isWideScreen ? 32 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          AdminSectionHeader(
            title: headerTitle,
            subtitle: headerSubtitle,
            icon: Icons.school_rounded,
            eyebrow: headerEyebrow,
            actions: [
              OutlinedButton.icon(
                onPressed: () => _handleSeedData(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  ),
                ),
                icon: const Icon(Icons.cloud_download_rounded, size: 18),
                label: const Text(
                  'Seed Data',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => LessonFormSheet.show(
                  context,
                  ref,
                  null,
                  initialCategoryId: _selectedCategoryId,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Add Subcategory',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search bar
          _buildSearchBar(isDark),

          const SizedBox(height: 14),

          // Category filter chips
          if (routeCategoryId == null) ...[
            categoriesAsync.when(
              data: (categories) => _buildCategoryFilter(categories, isDark),
              loading: () => const SizedBox(height: 40),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 16),
          ],

          // Lessons list
          Expanded(
            child: lessonsAsync.when(
              data: (lessons) {
                var filtered = lessons;
                if (_selectedCategoryId != null) {
                  filtered = lessons
                      .where((l) => l.categoryId == _selectedCategoryId)
                      .toList();
                } else {
                  // Exclude standard subcategories from general Lessons view
                  filtered = lessons.where((l) {
                    final cat = categories.firstWhere(
                      (c) => c.id == l.categoryId,
                      orElse: () => const CategoryEntity(
                        id: '',
                        titleLatin: '',
                        titleOlChiki: '',
                        description: '',
                      ),
                    );
                    return !_isStandardCategory(cat);
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered
                      .where(
                        (l) =>
                            l.titleLatin.toLowerCase().contains(q) ||
                            l.titleOlChiki.toLowerCase().contains(q) ||
                            (l.description?.toLowerCase().contains(q) ?? false),
                      )
                      .toList();
                }

                if (filtered.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }

                return _buildLessonsList(filtered, isDark, isWideScreen);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: SelectableText(
                  'Error: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search subcategories by name...',
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black26,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? Colors.white30 : Colors.black26,
          size: 20,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildCategoryFilter(List<CategoryEntity> categories, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            isSelected: _selectedCategoryId == null,
            onTap: () => setState(() => _selectedCategoryId = null),
            isDark: isDark,
          ),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildFilterChip(
                label: c.titleLatin,
                isSelected: _selectedCategoryId == c.id,
                onTap: () => setState(() => _selectedCategoryId = c.id),
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isDark
                ? Colors.white60
                : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'No lessons match "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _searchQuery = ''),
              child: const Text('Clear search'),
            ),
          ],
        ),
      );
    }

    return AdminEmptyState(
          icon: Icons.school_outlined,
          title: 'No subcategories yet',
          message:
              'Create your first subcategory to start building learning content.',
          actionLabel: 'Create Subcategory',
          onAction: () => LessonFormSheet.show(
            context,
            ref,
            null,
            initialCategoryId: _selectedCategoryId,
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildLessonsList(
    List<LessonEntity> lessons,
    bool isDark,
    bool isWideScreen,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return LessonCard(
          lesson: lesson,
          isDark: isDark,
          onEdit: () => LessonFormSheet.show(context, ref, lesson),
          onDelete: () => _showDeleteDialog(context, lesson),
        ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05);
      },
    );
  }

  void _showDeleteDialog(BuildContext context, LessonEntity lesson) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Subcategory',
      message:
          'Are you sure you want to delete "${lesson.titleLatin}"? This action cannot be undone.',
    );
    if (ok == true) {
      try {
        await ref.read(lessonNotifierProvider.notifier).deleteLesson(lesson.id);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete lesson: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSeedData(BuildContext context) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Seed Default Data',
      message:
          'This will populate your app with rich sample categories, letters, lessons, and numbers. Existing custom data is preserved.',
    );

    if (ok == true) {
      try {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seeding default data to database...'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        await seedAppContent(ref);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Default data seeded successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to seed data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
