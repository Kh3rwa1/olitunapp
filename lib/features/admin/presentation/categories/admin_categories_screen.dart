import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../shared/providers/providers.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_form_widgets.dart';
import 'widgets/category_card.dart';
import 'widgets/category_form_sheet.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

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
            title: 'Categories',
            subtitle: 'Organize your learning modules',
            icon: Icons.category_rounded,
            eyebrow: 'CONTENT · CATEGORIES',
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
                  'Seed Default Data',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          // Categories List
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => categories.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : _buildCategoriesList(categories, isDark, isWideScreen),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: SelectableText(
                  'Error loading categories: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return AdminEmptyState(
          icon: Icons.category_outlined,
          title: 'No categories yet',
          message:
              'Create your first learning category to start grouping lessons.',
          actionLabel: 'Create Category',
          onAction: () => CategoryFormSheet.show(context, ref, null),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildCategoriesList(
    List<CategoryEntity> categories,
    bool isDark,
    bool isWideScreen,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: categories.length,
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) async {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        await ref
            .read(categoryNotifierProvider.notifier)
            .reorderCategories(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          key: ValueKey(category.id),
          category: category,
          isDark: isDark,
          index: index,
          onEdit: () => CategoryFormSheet.show(context, ref, category),
          onDelete: () => _showDeleteDialog(context, category),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    CategoryEntity category,
  ) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Category',
      message:
          'Are you sure you want to delete "${category.titleLatin}"? This action cannot be undone.',
    );
    if (ok == true) {
      ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);
    }
  }

  Future<void> _handleSeedData(BuildContext context) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Seed Default Data',
      message:
          'This will populate your app with rich sample categories, letters, lessons, and numbers. Existing custom data is preserved and not overwritten.',
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
