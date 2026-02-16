import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
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
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rhyme Categories',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            'Manage categories & subcategories ($count categories)',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'No categories found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
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
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconFromName(cat.iconName),
                color: AppColors.primary,
              ),
            ),
            title: Text(
              cat.nameLatin,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            subtitle: Text(
              '${cat.nameOlChiki} · ${subcats.length} subcategories',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  tooltip: 'Add Subcategory',
                  onPressed: () => _showSubcategoryDialog(cat.id, null),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => _showCategoryDialog(cat),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed: () => _confirmDeleteCategory(cat),
                ),
              ],
            ),
            children: subcats.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No subcategories yet. Tap + to add.',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                  ]
                : subcats
                      .map(
                        (sub) => ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 72,
                            right: 16,
                          ),
                          leading: Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 18,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          title: Text(
                            sub.nameLatin,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            sub.nameOlChiki,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                onPressed: () =>
                                    _showSubcategoryDialog(cat.id, sub),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDeleteSubcategory(sub),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(cat == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameLatinCtrl,
                  decoration: const InputDecoration(labelText: 'Name (Latin)'),
                ),
                TextField(
                  controller: nameOlChikiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name (Ol Chiki)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: iconName,
                  items: iconOptions
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Row(
                            children: [
                              Icon(_getIconFromName(e), size: 20),
                              const SizedBox(width: 8),
                              Text(e),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => iconName = val!);
                  },
                  decoration: const InputDecoration(labelText: 'Icon'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(RhymeCategoryModel cat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "${cat.nameLatin}" and all its subcategories?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete subcategories first
              final subcats = ref.read(rhymeSubcategoriesProvider).value ?? [];
              for (final sub in subcats) {
                if (sub.categoryId == cat.id) {
                  ref.read(rhymeSubcategoriesProvider.notifier).delete(sub.id);
                }
              }
              ref.read(rhymeCategoriesProvider.notifier).delete(cat.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Subcategory CRUD dialogs ───

  void _showSubcategoryDialog(String categoryId, RhymeSubcategoryModel? sub) {
    final nameLatinCtrl = TextEditingController(text: sub?.nameLatin);
    final nameOlChikiCtrl = TextEditingController(text: sub?.nameOlChiki);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sub == null ? 'Add Subcategory' : 'Edit Subcategory'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameLatinCtrl,
                decoration: const InputDecoration(labelText: 'Name (Latin)'),
              ),
              TextField(
                controller: nameOlChikiCtrl,
                decoration: const InputDecoration(labelText: 'Name (Ol Chiki)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final subcats = ref.read(rhymeSubcategoriesProvider).value ?? [];
              final catSubs = subcats
                  .where((s) => s.categoryId == categoryId)
                  .toList();
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubcategory(RhymeSubcategoryModel sub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subcategory?'),
        content: Text('Delete "${sub.nameLatin}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(rhymeSubcategoriesProvider.notifier).delete(sub.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
