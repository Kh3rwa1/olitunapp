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
import 'widgets/rhyme_subcategory_form_sheet.dart';

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
    final subcategoriesAsync = ref.watch(rhymeSubcategoriesProvider);
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
                  : subcategoriesAsync.when(
                      data: (subcategories) => _buildCategoriesList(
                        categories,
                        subcategories,
                        isDark,
                      ),
                      loading: () => const AdminLoadingState(
                        label: 'Loading subcategories…',
                      ),
                      error: (e, _) => AdminErrorState(
                        message: '$e',
                        onRetry: () =>
                            ref.invalidate(rhymeSubcategoriesProvider),
                      ),
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
    List<RhymeSubcategoryModel> allSubcategories,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final subcats = allSubcategories
            .where((s) => s.categoryId == cat.id)
            .toList();

        return RhymeCategoryCard(
          category: cat,
          subcategories: subcats,
          onAddSubcategory: () => _showSubcategoryDialog(cat.id, null),
          onEditCategory: () => _showCategoryDialog(cat),
          onDeleteCategory: () => _confirmDeleteCategory(cat),
          onEditSubcategory: (sub) => _showSubcategoryDialog(cat.id, sub),
          onDeleteSubcategory: _confirmDeleteSubcategory,
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
          'Delete "${cat.nameLatin}" and all of its subcategories? This action cannot be undone.',
    );
    if (ok == true) {
      final subcats = ref.read(rhymeSubcategoriesProvider).value ?? [];
      for (final sub in subcats) {
        if (sub.categoryId == cat.id) {
          ref.read(rhymeSubcategoriesProvider.notifier).delete(sub.id);
        }
      }
      ref.read(rhymeCategoriesProvider.notifier).delete(cat.id);
    }
  }

  // ─── Subcategory CRUD actions ───

  void _showSubcategoryDialog(String categoryId, RhymeSubcategoryModel? sub) {
    final subcats = ref.read(rhymeSubcategoriesProvider).value ?? [];
    final catSubs = subcats.where((s) => s.categoryId == categoryId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RhymeSubcategoryFormSheet(
        categoryId: categoryId,
        subcategory: sub,
        categorySubcategoriesCount: catSubs.length,
        onSave: (item) {
          if (sub == null) {
            ref.read(rhymeSubcategoriesProvider.notifier).add(item);
          } else {
            ref.read(rhymeSubcategoriesProvider.notifier).update(item);
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteSubcategory(RhymeSubcategoryModel sub) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Subcategory',
      message: 'Delete "${sub.nameLatin}"? This action cannot be undone.',
    );
    if (ok == true) {
      ref.read(rhymeSubcategoriesProvider.notifier).delete(sub.id);
    }
  }
}
