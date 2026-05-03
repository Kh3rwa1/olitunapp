import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/upload_service.dart';
import '../../../shared/providers/providers.dart';
import '../../categories/presentation/providers/category_notifier.dart';
import '../../categories/domain/entities/category_entity.dart';
import 'widgets/admin_glass_card.dart';
import 'widgets/admin_section_header.dart';
import 'widgets/admin_empty_state.dart';

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
            actions: isWideScreen ? [] : null,
          ),

          // Categories List
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => categories.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : _buildCategoriesList(categories, isDark, isWideScreen),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: SelectableText(
                  'Error loading categories: $error',
                  style: TextStyle(color: AppColors.error),
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
      message: 'Create your first learning category to start grouping lessons.',
      actionLabel: 'Create Category',
      onAction: () => _showCategoryDialog(context, null),
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
        return _CategoryCard(
          key: ValueKey(category.id),
          category: category,
          isDark: isDark,
          index: index,
          onEdit: () => _showCategoryDialog(context, category),
          onDelete: () => _showDeleteDialog(context, category),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, CategoryEntity? category) {
    final isEditing = category != null;
    final titleLatinController = TextEditingController(
      text: category?.titleLatin ?? '',
    );
    final titleOlChikiController = TextEditingController(
      text: category?.titleOlChiki ?? '',
    );
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    final iconUrlController = TextEditingController(
      text: category?.iconUrl ?? '',
    );
    final animationUrlController = TextEditingController(
      text: category?.animationUrl ?? '',
    );
    String selectedGradient = category?.gradientPreset ?? 'skyBlue';
    String selectedIcon = category?.iconName ?? 'alphabet';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_rounded : Icons.add_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEditing ? 'Edit Category' : 'New Category',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: titleLatinController,
                        label: 'Title (English)',
                        hint: 'e.g., Alphabets',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: titleOlChikiController,
                        label: 'Title (Ol Chiki)',
                        hint: 'e.g., ᱚᱠᱷᱚᱨ',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: descriptionController,
                        label: 'Description',
                        hint: 'Brief description of this category',
                        isDark: isDark,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      _buildUploadField(
                        controller: iconUrlController,
                        label: 'Icon / Lottie Animation',
                        icon: Icons.animation_rounded,
                        isDark: isDark,
                        onUpload: () => _pickAndUploadIconOrLottie(
                          context,
                          iconUrlController,
                          'category-icons',
                          setDialogState,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildUploadField(
                        controller: animationUrlController,
                        label: 'Lottie Animation (Optional)',
                        icon: Icons.animation_rounded,
                        isDark: isDark,
                        onUpload: () => _pickAndUploadLottie(
                          context,
                          animationUrlController,
                          'animations',
                          setDialogState,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Gradient Selection
                      Text(
                        'Color Theme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _GradientOption(
                            gradient: AppColors.skyBlueGradient,
                            label: 'Blue',
                            isSelected: selectedGradient == 'skyBlue',
                            onTap: () => setDialogState(
                              () => selectedGradient = 'skyBlue',
                            ),
                          ),
                          _GradientOption(
                            gradient: AppColors.peachGradient,
                            label: 'Peach',
                            isSelected: selectedGradient == 'peach',
                            onTap: () => setDialogState(
                              () => selectedGradient = 'peach',
                            ),
                          ),
                          _GradientOption(
                            gradient: AppColors.mintGradient,
                            label: 'Mint',
                            isSelected: selectedGradient == 'mint',
                            onTap: () =>
                                setDialogState(() => selectedGradient = 'mint'),
                          ),
                          _GradientOption(
                            gradient: AppColors.sunsetGradient,
                            label: 'Sunset',
                            isSelected: selectedGradient == 'sunset',
                            onTap: () => setDialogState(
                              () => selectedGradient = 'sunset',
                            ),
                          ),
                          _GradientOption(
                            gradient: AppColors.skyBlueGradient,
                            label: 'Purple',
                            isSelected: selectedGradient == 'purple',
                            onTap: () => setDialogState(
                              () => selectedGradient = 'purple',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Icon Selection
                      Text(
                        'Icon',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _IconOption(
                            icon: Icons.abc_rounded,
                            label: 'ABC',
                            isSelected: selectedIcon == 'alphabet',
                            onTap: () =>
                                setDialogState(() => selectedIcon = 'alphabet'),
                            isDark: isDark,
                          ),
                          _IconOption(
                            icon: Icons.pin_rounded,
                            label: 'Numbers',
                            isSelected: selectedIcon == 'numbers',
                            onTap: () =>
                                setDialogState(() => selectedIcon = 'numbers'),
                            isDark: isDark,
                          ),
                          _IconOption(
                            icon: Icons.text_fields_rounded,
                            label: 'Words',
                            isSelected: selectedIcon == 'words',
                            onTap: () =>
                                setDialogState(() => selectedIcon = 'words'),
                            isDark: isDark,
                          ),
                          _IconOption(
                            icon: Icons.calculate_rounded,
                            label: 'Math',
                            isSelected: selectedIcon == 'arithmetic',
                            onTap: () => setDialogState(
                              () => selectedIcon = 'arithmetic',
                            ),
                            isDark: isDark,
                          ),
                          _IconOption(
                            icon: Icons.auto_stories_rounded,
                            label: 'Stories',
                            isSelected: selectedIcon == 'stories',
                            onTap: () =>
                                setDialogState(() => selectedIcon = 'stories'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D1117)
                      : const Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final newCategory = CategoryEntity(
                            id: category?.id ?? const Uuid().v4(),
                            titleLatin: titleLatinController.text,
                            titleOlChiki: titleOlChikiController.text,
                            description: descriptionController.text,
                            iconUrl: iconUrlController.text.isNotEmpty
                                ? iconUrlController.text
                                : null,
                            animationUrl: animationUrlController.text.isNotEmpty
                                ? animationUrlController.text
                                : null,
                            gradientPreset: selectedGradient,
                            iconName: selectedIcon,
                            order: category?.order ?? 0,
                            isActive: true,
                          );

                          if (isEditing) {
                            ref
                                .read(categoryNotifierProvider.notifier)
                                .updateCategory(newCategory);
                          } else {
                            ref
                                .read(categoryNotifierProvider.notifier)
                                .addCategory(newCategory);
                          }
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isEditing ? 'Save Changes' : 'Create Category',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, CategoryEntity category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 14),
            const Text('Delete Category'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${category.titleLatin}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onUpload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onUpload,
              icon: Icon(icon, size: 20),
              tooltip: 'Upload Icon',
            ),
          ],
        ),
      ],
    );
  }

  /// Picks and uploads an icon image OR Lottie animation (.json, .webp, .png, .jpg, .gif)
  Future<void> _pickAndUploadIconOrLottie(
    BuildContext context,
    TextEditingController controller,
    String folder,
    StateSetter setDialogState,
  ) async {
    try {
      final validExtensions = [
        'json',
        'webp',
        'png',
        'jpg',
        'jpeg',
        'gif',
        'svg',
      ];

      // On web, FileType.custom with allowedExtensions throws PlatformException
      // Use FileType.any and validate client-side instead
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final ext = pickedFile.name.split('.').last.toLowerCase();

        if (!validExtensions.contains(ext)) {
          throw Exception(
            'Invalid file type: .$ext\nAllowed: ${validExtensions.map((e) => '.$e').join(', ')}',
          );
        }

        if (pickedFile.bytes == null || pickedFile.bytes!.isEmpty) {
          throw Exception('File data is empty. Please try again.');
        }

        final url = await ref
            .read(uploadServiceProvider)
            .uploadMedia(pickedFile, folder);
        if (url != null) {
          setDialogState(() {
            controller.text = url;
          });
          if (context.mounted) {
            final isLottie = ext == 'json';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isLottie
                      ? '✅ Lottie animation uploaded!'
                      : '✅ Icon uploaded!',
                ),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// Picks and uploads a Lottie animation (.json only)
  Future<void> _pickAndUploadLottie(
    BuildContext context,
    TextEditingController controller,
    String folder,
    StateSetter setDialogState,
  ) async {
    try {
      // On web, FileType.custom throws PlatformException — use FileType.any
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final ext = pickedFile.name.split('.').last.toLowerCase();

        if (ext != 'json') {
          throw Exception('Only .json Lottie files are allowed. Got: .$ext');
        }

        if (pickedFile.bytes == null || pickedFile.bytes!.isEmpty) {
          throw Exception('File data is empty. Please try again.');
        }

        final url = await ref
            .read(uploadServiceProvider)
            .uploadMedia(pickedFile, folder);
        if (url != null) {
          setDialogState(() {
            controller.text = url;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Lottie animation uploaded!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }
}

class _CategoryCard extends StatefulWidget {
  final CategoryEntity category;
  final bool isDark;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    super.key,
    required this.category,
    required this.isDark,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
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
        return AppColors.skyBlueGradient;
      default:
        return AppColors.skyBlueGradient;
    }
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

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(widget.category.gradientPreset);
    final themeColor = gradient.colors.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AdminGlassCard(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 380;
            return Row(
              children: [
                // Order Handle
                ReorderableDragStartListener(
                  index: widget.index,
                  child: Padding(
                    padding: EdgeInsets.only(right: isSmall ? 8 : 16),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: widget.isDark ? Colors.white24 : Colors.black12,
                      size: isSmall ? 20 : 24,
                    ),
                  ),
                ),

                // Icon
                Container(
                  width: isSmall ? 40 : 52,
                  height: isSmall ? 40 : 52,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIcon(widget.category.iconName),
                    color: Colors.white,
                    size: isSmall ? 20 : 26,
                  ),
                ).animate().shimmer(delay: 1.seconds, duration: 2.seconds),
                SizedBox(width: isSmall ? 12 : 20),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.titleLatin,
                        style: TextStyle(
                          fontSize: isSmall ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.category.titleOlChiki,
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark
                              ? Colors.white38
                              : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  onPressed: widget.onEdit,
                  icon: Icon(
                    Icons.edit_note_rounded,
                    color: widget.isDark ? Colors.white54 : Colors.black45,
                    size: isSmall ? 20 : 24,
                  ),
                  visualDensity: isSmall ? VisualDensity.compact : null,
                  padding: isSmall ? EdgeInsets.zero : null,
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: isSmall ? 20 : 24,
                  ),
                  visualDensity: isSmall ? VisualDensity.compact : null,
                  padding: isSmall ? EdgeInsets.zero : null,
                  tooltip: 'Delete',
                ),
              ],
            );
          },
        ),
      ),
    ).animate().fadeIn(delay: (widget.index * 50).ms).slideX(begin: 0.05);
  }
}

class _GradientOption extends StatelessWidget {
  final LinearGradient gradient;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GradientOption({
    required this.gradient,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _IconOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white10 : Colors.black12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
