import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_form_widgets.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_page_header.dart';
import '../../../shared/providers/providers.dart';
import '../../rhymes/domain/rhyme_category_model.dart';

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
            _buildHeader(isDark, categories.length),
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

  Widget _buildHeader(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.all(AdminTokens.space7),
      child: AdminPageHeader(
        title: 'Rhyme Categories',
        subtitle: 'Manage categories & subcategories ($count categories)',
        eyebrow: 'CONTENT · CATEGORIES',
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AdminEmptyState(
      icon: Icons.folder_open_rounded,
      title: 'No categories yet',
      message: 'Create a category to start organising your rhymes and stories.',
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
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AdminTokens.accentSoft(isDark),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                  border: Border.all(color: AdminTokens.accentBorder(isDark)),
                ),
                child: Icon(
                  _getIconFromName(cat.iconName),
                  color: AdminTokens.accent,
                ),
              ),
              title: Text(cat.nameLatin, style: AdminTokens.cardTitle(isDark)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${cat.nameOlChiki} · ${subcats.length} subcategories',
                  style: AdminTokens.label(isDark),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminIconAction(
                    icon: Icons.add_circle_outline_rounded,
                    tooltip: 'Add subcategory',
                    onTap: () => _showSubcategoryDialog(cat.id, null),
                  ),
                  const SizedBox(width: 6),
                  AdminIconAction(
                    icon: Icons.edit_rounded,
                    tooltip: 'Edit',
                    onTap: () => _showCategoryDialog(cat),
                  ),
                  const SizedBox(width: 6),
                  AdminIconAction(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete',
                    destructive: true,
                    onTap: () => _confirmDeleteCategory(cat),
                  ),
                ],
              ),
              children: subcats.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                        child: Text(
                          'No subcategories yet. Tap + to add.',
                          style: AdminTokens.label(isDark).copyWith(
                            color: AdminTokens.textTertiary(isDark),
                          ),
                        ),
                      ),
                    ]
                  : subcats
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
                              border: Border.all(
                                color: AdminTokens.border(isDark),
                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  onTap: () =>
                                      _showSubcategoryDialog(cat.id, sub),
                                ),
                                const SizedBox(width: 6),
                                AdminIconAction(
                                  icon: Icons.delete_outline_rounded,
                                  tooltip: 'Delete',
                                  destructive: true,
                                  onTap: () => _confirmDeleteSubcategory(sub),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
      },
    );
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'pets':
        return Icons.pets_rounded;
      case 'nature':
        return Icons.wb_sunny_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'child_care':
        return Icons.child_care_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  // ─── Category CRUD dialogs ───

  void _showCategoryDialog(RhymeCategoryModel? cat) {
    final nameLatinCtrl = TextEditingController(text: cat?.nameLatin);
    final nameOlChikiCtrl = TextEditingController(text: cat?.nameOlChiki);
    String iconName = cat?.iconName ?? 'child_care';

    final iconOptions = ['pets', 'nature', 'auto_awesome', 'child_care'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AdminModalSheet(
            title: cat == null ? 'Add Category' : 'Edit Category',
            subtitle: 'Organise rhymes into top-level groups',
            icon: Icons.folder_rounded,
            primaryLabel: cat == null ? 'Create Category' : 'Save Changes',
            heightFactor: 0.7,
            onPrimary: () {
              final categories =
                  ref.read(rhymeCategoriesProvider).value ?? [];
              final item = RhymeCategoryModel(
                id: cat?.id ?? 'rcat_${const Uuid().v4().substring(0, 8)}',
                nameOlChiki: nameOlChikiCtrl.text,
                nameLatin: nameLatinCtrl.text,
                iconName: iconName,
                order: cat?.order ?? categories.length,
              );
              if (cat == null) {
                ref.read(rhymeCategoriesProvider.notifier).add(item);
              } else {
                ref.read(rhymeCategoriesProvider.notifier).update(item);
              }
              Navigator.pop(context);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminTextField(
                  controller: nameLatinCtrl,
                  label: 'Name (Latin)',
                  hint: 'e.g. Animals',
                ),
                const SizedBox(height: AdminTokens.space5),
                AdminTextField(
                  controller: nameOlChikiCtrl,
                  label: 'Name (Ol Chiki)',
                  hint: 'ᱡᱟᱱᱣᱟᱨ',
                ),
                const SizedBox(height: AdminTokens.space5),
                Text(
                  'Icon',
                  style: AdminTokens.label(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                const SizedBox(height: AdminTokens.space2),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: iconOptions.map((e) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final selected = iconName == e;
                    return GestureDetector(
                      onTap: () => setDialogState(() => iconName = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AdminTokens.accentSoft(isDark)
                              : AdminTokens.sunken(isDark),
                          borderRadius:
                              BorderRadius.circular(AdminTokens.radiusMd),
                          border: Border.all(
                            color: selected
                                ? AdminTokens.accentBorder(isDark)
                                : AdminTokens.border(isDark),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconFromName(e),
                              size: 18,
                              color: selected
                                  ? AdminTokens.accent
                                  : AdminTokens.textSecondary(isDark),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e,
                              style: AdminTokens.label(isDark).copyWith(
                                color: selected
                                    ? AdminTokens.accent
                                    : AdminTokens.textSecondary(isDark),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
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

  // ─── Subcategory CRUD dialogs ───

  void _showSubcategoryDialog(String categoryId, RhymeSubcategoryModel? sub) {
    final nameLatinCtrl = TextEditingController(text: sub?.nameLatin);
    final nameOlChikiCtrl = TextEditingController(text: sub?.nameOlChiki);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminModalSheet(
        title: sub == null ? 'Add Subcategory' : 'Edit Subcategory',
        subtitle: 'A child group nested under a category',
        icon: Icons.subdirectory_arrow_right_rounded,
        primaryLabel: sub == null ? 'Create Subcategory' : 'Save Changes',
        heightFactor: 0.55,
        onPrimary: () {
          final subcats = ref.read(rhymeSubcategoriesProvider).value ?? [];
          final catSubs =
              subcats.where((s) => s.categoryId == categoryId).toList();
          final item = RhymeSubcategoryModel(
            id: sub?.id ?? 'rsub_${const Uuid().v4().substring(0, 8)}',
            categoryId: categoryId,
            nameOlChiki: nameOlChikiCtrl.text,
            nameLatin: nameLatinCtrl.text,
            order: sub?.order ?? catSubs.length,
          );
          if (sub == null) {
            ref.read(rhymeSubcategoriesProvider.notifier).add(item);
          } else {
            ref.read(rhymeSubcategoriesProvider.notifier).update(item);
          }
          Navigator.pop(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminTextField(
              controller: nameLatinCtrl,
              label: 'Name (Latin)',
              hint: 'e.g. Tigers',
            ),
            const SizedBox(height: AdminTokens.space5),
            AdminTextField(
              controller: nameOlChikiCtrl,
              label: 'Name (Ol Chiki)',
              hint: 'ᱠᱩᱞ',
            ),
          ],
        ),
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
