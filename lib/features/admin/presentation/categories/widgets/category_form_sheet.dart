import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../categories/domain/entities/category_entity.dart';
import '../../../../categories/presentation/providers/category_notifier.dart';
import '../../widgets/admin_form_widgets.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryEntity? category;

  const CategoryFormSheet({super.key, this.category});

  static void show(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity? category,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(category: category),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _titleLatinCtrl;
  late final TextEditingController _titleOlChikiCtrl;
  late final TextEditingController _descriptionCtrl;
  String? _iconUrl;
  String? _animationUrl;
  late String _selectedGradient;
  late String _selectedIcon;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _titleLatinCtrl = TextEditingController(
      text: widget.category?.titleLatin ?? '',
    );
    _titleOlChikiCtrl = TextEditingController(
      text: widget.category?.titleOlChiki ?? '',
    );
    _descriptionCtrl = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _iconUrl = widget.category?.iconUrl;
    _animationUrl = widget.category?.animationUrl;
    _selectedGradient = widget.category?.gradientPreset ?? 'skyBlue';
    _selectedIcon = widget.category?.iconName ?? 'alphabet';
  }

  @override
  void dispose() {
    _titleLatinCtrl.dispose();
    _titleOlChikiCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final newCategory = CategoryEntity(
      id: widget.category?.id ?? const Uuid().v4(),
      titleLatin: _titleLatinCtrl.text,
      titleOlChiki: _titleOlChikiCtrl.text,
      description: _descriptionCtrl.text,
      iconUrl: _iconUrl != null && _iconUrl!.isNotEmpty ? _iconUrl : null,
      animationUrl: _animationUrl != null && _animationUrl!.isNotEmpty
          ? _animationUrl
          : null,
      gradientPreset: _selectedGradient,
      iconName: _selectedIcon,
      order: widget.category?.order ?? 0,
    );

    if (_isEditing) {
      ref.read(categoryNotifierProvider.notifier).updateCategory(newCategory);
    } else {
      ref.read(categoryNotifierProvider.notifier).addCategory(newCategory);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AdminTokens.radius2xl),
        ),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
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
                    _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _isEditing ? 'Edit Category' : 'New Category',
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

          Divider(height: 1, color: AdminTokens.divider(isDark)),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTextField(
                    controller: _titleLatinCtrl,
                    label: 'Title (English)',
                    hint: 'e.g., Alphabets',
                  ),
                  const SizedBox(height: 20),
                  AdminTextField(
                    controller: _titleOlChikiCtrl,
                    label: 'Title (Ol Chiki)',
                    hint: 'e.g., ᱚᱠᱷᱚᱨ',
                  ),
                  const SizedBox(height: 20),
                  AdminTextField(
                    controller: _descriptionCtrl,
                    label: 'Description',
                    hint: 'Brief description of this category',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  AdminMediaField(
                    label: 'Icon / Lottie Animation',
                    icon: Icons.animation_rounded,
                    accent: AppColors.primary,
                    currentUrl: _iconUrl,
                    uploadFolder: 'category-icons',
                    fileType: FileType.any,
                    onUploaded: (url) => setState(() => _iconUrl = url),
                  ),
                  const SizedBox(height: 20),
                  AdminMediaField(
                    label: 'Lottie Animation (Optional)',
                    icon: Icons.animation_rounded,
                    accent: const Color(0xFF10B981),
                    currentUrl: _animationUrl,
                    uploadFolder: 'animations',
                    fileType: FileType.custom,
                    allowedExtensions: const ['json'],
                    onUploaded: (url) => setState(() => _animationUrl = url),
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
                        isSelected: _selectedGradient == 'skyBlue',
                        onTap: () =>
                            setState(() => _selectedGradient = 'skyBlue'),
                      ),
                      _GradientOption(
                        gradient: AppColors.peachGradient,
                        label: 'Peach',
                        isSelected: _selectedGradient == 'peach',
                        onTap: () =>
                            setState(() => _selectedGradient = 'peach'),
                      ),
                      _GradientOption(
                        gradient: AppColors.mintGradient,
                        label: 'Mint',
                        isSelected: _selectedGradient == 'mint',
                        onTap: () => setState(() => _selectedGradient = 'mint'),
                      ),
                      _GradientOption(
                        gradient: AppColors.sunsetGradient,
                        label: 'Sunset',
                        isSelected: _selectedGradient == 'sunset',
                        onTap: () =>
                            setState(() => _selectedGradient = 'sunset'),
                      ),
                      _GradientOption(
                        gradient: AppColors.purpleGradient,
                        label: 'Purple',
                        isSelected: _selectedGradient == 'purple',
                        onTap: () =>
                            setState(() => _selectedGradient = 'purple'),
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
                        isSelected: _selectedIcon == 'alphabet',
                        onTap: () => setState(() => _selectedIcon = 'alphabet'),
                        isDark: isDark,
                      ),
                      _IconOption(
                        icon: Icons.pin_rounded,
                        label: 'Numbers',
                        isSelected: _selectedIcon == 'numbers',
                        onTap: () => setState(() => _selectedIcon = 'numbers'),
                        isDark: isDark,
                      ),
                      _IconOption(
                        icon: Icons.text_fields_rounded,
                        label: 'Words',
                        isSelected: _selectedIcon == 'words',
                        onTap: () => setState(() => _selectedIcon = 'words'),
                        isDark: isDark,
                      ),
                      _IconOption(
                        icon: Icons.calculate_rounded,
                        label: 'Math',
                        isSelected: _selectedIcon == 'arithmetic',
                        onTap: () =>
                            setState(() => _selectedIcon = 'arithmetic'),
                        isDark: isDark,
                      ),
                      _IconOption(
                        icon: Icons.auto_stories_rounded,
                        label: 'Stories',
                        isSelected: _selectedIcon == 'stories',
                        onTap: () => setState(() => _selectedIcon = 'stories'),
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: AdminTokens.baseTint(isDark),
              border: Border(
                top: BorderSide(color: AdminTokens.divider(isDark)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: AdminSecondaryButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AdminPrimaryButton(
                      label: _isEditing ? 'Save Changes' : 'Create Category',
                      icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AdminTokens.sunken(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AdminTokens.border(isDark),
              ),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.white54
                  : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
