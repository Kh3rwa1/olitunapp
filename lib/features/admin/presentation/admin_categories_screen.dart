import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isWideScreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              leading: CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.go('/admin'),
              ),
              title: const Text('Categories'),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWideScreen)
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Manage learning categories',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    PrimaryButton(
                      text: 'Add Category',
                      
                      icon: Icons.add_rounded,
                      onPressed: () => _showCategoryDialog(context, null),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No categories yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          PrimaryButton(
                            text: 'Add First Category',
                            
                            onPressed: () => _showCategoryDialog(context, null),
                          ),
                        ],
                      ),
                    );
                  }

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    itemCount: categories.length,
                    onReorder: (oldIndex, newIndex) {
                      // TODO: Implement reorder
                    },
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _CategoryTile(
                        key: ValueKey(category.id),
                        category: category,
                        onEdit: () => _showCategoryDialog(context, category),
                        onDelete: () => _showDeleteDialog(context, category),
                      );
                    },
                  );
                },
                loading: () => const ShimmerLessonList(itemCount: 4),
                error: (error, _) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, CategoryModel? category) {
    final isEditing = category != null;
    final titleOlChikiController = TextEditingController(text: category?.titleOlChiki ?? '');
    final titleLatinController = TextEditingController(text: category?.titleLatin ?? '');
    String selectedGradient = category?.gradientPreset ?? 'skyBlue';
    String selectedIcon = category?.iconName ?? 'alphabet';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleLatinController,
                  decoration: const InputDecoration(
                    labelText: 'Title (Latin)',
                    hintText: 'e.g., Alphabets',
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  controller: titleOlChikiController,
                  decoration: const InputDecoration(
                    labelText: 'Title (Ol Chiki)',
                    hintText: 'e.g., ᱚᱠᱷᱚᱨ',
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'Gradient',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppConstants.spacingS),
                Wrap(
                  spacing: 8,
                  children: [
                    _GradientOption(
                      gradient: AppColors.skyBlueGradient,
                      isSelected: selectedGradient == 'skyBlue',
                      onTap: () => setDialogState(() => selectedGradient = 'skyBlue'),
                    ),
                    _GradientOption(
                      gradient: AppColors.peachGradient,
                      isSelected: selectedGradient == 'peach',
                      onTap: () => setDialogState(() => selectedGradient = 'peach'),
                    ),
                    _GradientOption(
                      gradient: AppColors.mintGradient,
                      isSelected: selectedGradient == 'mint',
                      onTap: () => setDialogState(() => selectedGradient = 'mint'),
                    ),
                    _GradientOption(
                      gradient: AppColors.sunsetGradient,
                      isSelected: selectedGradient == 'sunset',
                      onTap: () => setDialogState(() => selectedGradient = 'sunset'),
                    ),
                    _GradientOption(
                      gradient: AppColors.purpleGradient,
                      isSelected: selectedGradient == 'purple',
                      onTap: () => setDialogState(() => selectedGradient = 'purple'),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'Icon',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppConstants.spacingS),
                Wrap(
                  spacing: 8,
                  children: [
                    _IconOption(
                      icon: Icons.abc_rounded,
                      isSelected: selectedIcon == 'alphabet',
                      onTap: () => setDialogState(() => selectedIcon = 'alphabet'),
                    ),
                    _IconOption(
                      icon: Icons.pin_rounded,
                      isSelected: selectedIcon == 'numbers',
                      onTap: () => setDialogState(() => selectedIcon = 'numbers'),
                    ),
                    _IconOption(
                      icon: Icons.text_fields_rounded,
                      isSelected: selectedIcon == 'words',
                      onTap: () => setDialogState(() => selectedIcon = 'words'),
                    ),
                    _IconOption(
                      icon: Icons.calculate_rounded,
                      isSelected: selectedIcon == 'arithmetic',
                      onTap: () => setDialogState(() => selectedIcon = 'arithmetic'),
                    ),
                    _IconOption(
                      icon: Icons.auto_stories_rounded,
                      isSelected: selectedIcon == 'stories',
                      onTap: () => setDialogState(() => selectedIcon = 'stories'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final contentRepo = ref.read(contentRepositoryProvider);
                final newCategory = CategoryModel(
                  id: category?.id ?? '',
                  titleOlChiki: titleOlChikiController.text,
                  titleLatin: titleLatinController.text,
                  gradientPreset: selectedGradient,
                  iconName: selectedIcon,
                  order: category?.order ?? 0,
                  isActive: true,
                );
                await contentRepo.saveCategory(newCategory);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.titleLatin}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final contentRepo = ref.read(contentRepositoryProvider);
              await contentRepo.deleteCategory(category.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = _getGradient(category.gradientPreset);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: SoftCard(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(category.iconName),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.titleLatin,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (category.titleOlChiki.isNotEmpty)
                    Text(
                      category.titleOlChiki,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'OlChiki',
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle_rounded),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? name) {
    switch (name) {
      case 'alphabet':
        return Icons.abc_rounded;
      case 'numbers':
        return Icons.pin_rounded;
      case 'words':
        return Icons.text_fields_rounded;
      case 'arithmetic':
        return Icons.calculate_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  LinearGradient _getGradient(String preset) {
    switch (preset) {
      case 'skyBlue':
        return AppColors.skyBlueGradient;
      case 'peach':
        return AppColors.peachGradient;
      case 'mint':
        return AppColors.mintGradient;
      case 'sunset':
        return AppColors.sunsetGradient;
      case 'purple':
        return AppColors.purpleGradient;
      default:
        return AppColors.skyBlueGradient;
    }
  }
}

class _GradientOption extends StatelessWidget {
  final Gradient gradient;
  final bool isSelected;
  final VoidCallback onTap;

  const _GradientOption({
    required this.gradient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.black, width: 2)
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryCyan
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          size: 20,
        ),
      ),
    );
  }
}
