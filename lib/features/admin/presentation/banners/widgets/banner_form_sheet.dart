import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_form_widgets.dart';

class BannerFormSheet extends ConsumerStatefulWidget {
  final FeaturedBannerModel? banner;

  const BannerFormSheet({super.key, this.banner});

  static void show(
    BuildContext context,
    WidgetRef ref,
    FeaturedBannerModel? banner,
  ) {
    showAdminBottomSheet(
      context: context,
      builder: (_) => BannerFormSheet(banner: banner),
    );
  }

  @override
  ConsumerState<BannerFormSheet> createState() => _BannerFormSheetState();
}

class _BannerFormSheetState extends ConsumerState<BannerFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _targetRouteCtrl;
  String? _imageUrl;
  String? _animationUrl;
  late String _selectedGradient;

  bool get _isEditing => widget.banner != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.banner?.title ?? '');
    _subtitleCtrl = TextEditingController(text: widget.banner?.subtitle ?? '');
    _targetRouteCtrl = TextEditingController(
      text: widget.banner?.targetRoute ?? '',
    );
    _imageUrl = widget.banner?.imageUrl;
    _animationUrl = widget.banner?.animationUrl;
    _selectedGradient = widget.banner?.gradientPreset ?? 'skyBlue';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _targetRouteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.heavyImpact();
    final newBanner = FeaturedBannerModel(
      id: widget.banner?.id ?? const Uuid().v4(),
      title: _titleCtrl.text,
      subtitle: _subtitleCtrl.text.isNotEmpty ? _subtitleCtrl.text : null,
      imageUrl: _imageUrl != null && _imageUrl!.isNotEmpty ? _imageUrl : null,
      animationUrl: _animationUrl != null && _animationUrl!.isNotEmpty
          ? _animationUrl
          : null,
      gradientPreset: _selectedGradient,
      targetRoute: _targetRouteCtrl.text.isNotEmpty
          ? _targetRouteCtrl.text
          : null,
      order: widget.banner?.order ?? 0,
    );

    if (_isEditing) {
      ref.read(featuredBannersProvider.notifier).updateBanner(newBanner);
    } else {
      ref.read(featuredBannersProvider.notifier).addBanner(newBanner);
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
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumPurple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _isEditing
                        ? Icons.edit_note_rounded
                        : Icons.add_photo_alternate_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Banner' : 'Create New Banner',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _isEditing
                          ? 'Update featured content'
                          : 'Promote new modules',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close form',
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTextField(
                    controller: _titleCtrl,
                    label: 'Banner Title',
                    hint: 'What will users see first?',
                  ),
                  const SizedBox(height: 24),
                  AdminTextField(
                    controller: _subtitleCtrl,
                    label: 'Description',
                    hint: 'Additional details (optional)',
                  ),
                  const SizedBox(height: 24),
                  AdminTextField(
                    controller: _targetRouteCtrl,
                    label: 'Target Action',
                    hint: '/lessons/alphabet-intro',
                  ),
                  const SizedBox(height: 24),
                  AdminMediaField(
                    label: 'Featured Image',
                    icon: Icons.upload_file_rounded,
                    accent: AppColors.primary,
                    currentUrl: _imageUrl,
                    uploadFolder: 'banners',
                    fileType: FileType.image,
                    onUploaded: (url) => setState(() => _imageUrl = url),
                    previewBuilder: (url) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_rounded,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 32),
                  Text(
                    'Aesthetic Style',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _GradientOption(
                        gradient: AppColors.skyBlueGradient,
                        isSelected: _selectedGradient == 'skyBlue',
                        onTap: () =>
                            setState(() => _selectedGradient = 'skyBlue'),
                      ),
                      _GradientOption(
                        gradient: AppColors.peachGradient,
                        isSelected: _selectedGradient == 'peach',
                        onTap: () =>
                            setState(() => _selectedGradient = 'peach'),
                      ),
                      _GradientOption(
                        gradient: AppColors.mintGradient,
                        isSelected: _selectedGradient == 'mint',
                        onTap: () => setState(() => _selectedGradient = 'mint'),
                      ),
                      _GradientOption(
                        gradient: AppColors.sunsetGradient,
                        isSelected: _selectedGradient == 'sunset',
                        onTap: () =>
                            setState(() => _selectedGradient = 'sunset'),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Publish Banner',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ).animate().shimmer(delay: 1.seconds),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientOption extends StatelessWidget {
  final LinearGradient gradient;
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
            : null,
      ),
    );
  }
}
