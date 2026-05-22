import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_form_widgets.dart';
import '../widgets/admin_empty_state.dart';
import '../../../../shared/providers/providers.dart';
import '../../../rhymes/domain/rhyme_category_model.dart';
import 'widgets/rhyme_categories_header.dart';
import 'widgets/rhyme_category_card.dart';
import 'widgets/rhyme_category_form_sheet.dart';

class AdminRhymeCategoriesScreen extends ConsumerStatefulWidget {
  const AdminRhymeCategoriesScreen({super.key});

  @override
  ConsumerState<AdminRhymeCategoriesScreen> createState() =>
      _AdminRhymeCategoriesScreenState();
}

class _AdminRhymeCategoriesScreenState
    extends ConsumerState<AdminRhymeCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(rhymeCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: categoriesAsync.when(
        data: (categories) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RhymeCategoriesHeader(count: categories.length),
            Expanded(
              child: categories.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildCategoriesList(
                      categories,
                      isDark,
                    ),
            ),
          ],
        ),
        loading: () => const AdminLoadingState(label: 'Loading categories…'),
        error: (e, _) => AdminErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(rhymeCategoriesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Category',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AdminEmptyState(
      icon: Icons.folder_open_rounded,
      title: 'No categories yet',
      message: 'Create a category to start organising your bakhed and stories.',
      actionLabel: 'Add Category',
      onAction: () => _showCategoryDialog(null),
    );
  }

  Widget _buildCategoriesList(
    List<RhymeCategoryModel> categories,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];

        return RhymeCategoryCard(
          category: cat,
          onEditCategory: () => _showCategoryDialog(cat),
          onDeleteCategory: () => _confirmDeleteCategory(cat),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
      },
    );
  }

  // ─── Category CRUD actions ───

  void _showCategoryDialog(RhymeCategoryModel? cat) {
    final categories = ref.read(rhymeCategoriesProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RhymeCategoryFormSheet(
        category: cat,
        categoryCount: categories.length,
        onSave: (item) {
          if (cat == null) {
            ref.read(rhymeCategoriesProvider.notifier).add(item);
          } else {
            ref.read(rhymeCategoriesProvider.notifier).update(item);
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteCategory(RhymeCategoryModel cat) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Category',
      message:
          'Delete "${cat.nameLatin}"? This action cannot be undone.',
    );
    if (ok == true) {
      ref.read(rhymeCategoriesProvider.notifier).delete(cat.id);
    }
  }
}
