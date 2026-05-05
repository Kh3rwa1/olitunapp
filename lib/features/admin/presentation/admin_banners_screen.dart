import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/upload_service.dart';
import 'widgets/admin_form_widgets.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import 'widgets/admin_glass_card.dart';
import 'widgets/admin_section_header.dart';
import 'widgets/admin_empty_state.dart';

class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(featuredBannersProvider);
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
            title: 'Featured Banners',
            subtitle: 'Home screen promotional banners',
            icon: Icons.featured_play_list_rounded,
            eyebrow: 'CONTENT · BANNERS',
            actions: isWideScreen ? [] : null,
          ),

          // Banners List
          Expanded(
            child: bannersAsync.when(
              data: (banners) => banners.isEmpty
                  ? _buildEmptyState(context, ref, isDark)
                  : _buildBannersList(
                      context,
                      ref,
                      banners,
                      isDark,
                      isWideScreen,
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: SelectableText(
                  'Error loading banners: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isDark) {
    return AdminEmptyState(
      icon: Icons.featured_play_list_outlined,
      title: 'No banners yet',
      message:
          'Create your first promotional banner to highlight on the home screen.',
      actionLabel: 'Create Banner',
      onAction: () => _showBannerDialog(context, ref, null),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildBannersList(
    BuildContext context,
    WidgetRef ref,
    List<FeaturedBannerModel> banners,
    bool isDark,
    bool isWideScreen,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      itemCount: banners.length,
      itemBuilder: (context, index) {
        final banner = banners[index];
        return _BannerCard(
          banner: banner,
          isDark: isDark,
          index: index,
          onEdit: () => _showBannerDialog(context, ref, banner),
          onDelete: () => _showDeleteDialog(context, ref, banner),
        );
      },
    );
  }

  void _showBannerDialog(
    BuildContext context,
    WidgetRef ref,
    FeaturedBannerModel? banner,
  ) {
    final isEditing = banner != null;
    final titleController = TextEditingController(text: banner?.title ?? '');
    final subtitleController = TextEditingController(
      text: banner?.subtitle ?? '',
    );
    final targetRouteController = TextEditingController(
      text: banner?.targetRoute ?? '',
    );
    final imageUrlController = TextEditingController(
      text: banner?.imageUrl ?? '',
    );
    final animationUrlController = TextEditingController(
      text: banner?.animationUrl ?? '',
    );
    String selectedGradient = banner?.gradientPreset ?? 'skyBlue';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
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
                        isEditing
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
                          isEditing ? 'Edit Banner' : 'Create New Banner',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          isEditing
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
                      _buildTextField(
                        controller: titleController,
                        label: 'Banner Title',
                        hint: 'What will users see first?',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: subtitleController,
                        label: 'Description',
                        hint: 'Additional details (optional)',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: targetRouteController,
                        label: 'Target Action',
                        hint: '/lessons/alphabet-intro',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildUploadField(
                        controller: imageUrlController,
                        label: 'Featured Image',
                        icon: Icons.upload_file_rounded,
                        isDark: isDark,
                        onUpload: () => _pickAndUpload(
                          context,
                          ref,
                          imageUrlController,
                          'banners',
                          setDialogState,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildUploadField(
                        controller: animationUrlController,
                        label: 'Lottie Animation (Optional)',
                        icon: Icons.animation_rounded,
                        isDark: isDark,
                        onUpload: () => _pickAndUploadLottie(
                          context,
                          ref,
                          animationUrlController,
                          'animations',
                          setDialogState,
                        ),
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
                            isSelected: selectedGradient == 'skyBlue',
                            onTap: () => setDialogState(
                              () => selectedGradient = 'skyBlue',
                            ),
                          ),
                          _GradientOption(
                            gradient: AppColors.peachGradient,
                            isSelected: selectedGradient == 'peach',
                            onTap: () => setDialogState(
                              () => selectedGradient = 'peach',
                            ),
                          ),
                          _GradientOption(
                            gradient: AppColors.mintGradient,
                            isSelected: selectedGradient == 'mint',
                            onTap: () =>
                                setDialogState(() => selectedGradient = 'mint'),
                          ),
                          _GradientOption(
                            gradient: AppColors.sunsetGradient,
                            isSelected: selectedGradient == 'sunset',
                            onTap: () => setDialogState(
                              () => selectedGradient = 'sunset',
                            ),
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
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          final newBanner = FeaturedBannerModel(
                            id: banner?.id ?? const Uuid().v4(),
                            title: titleController.text,
                            subtitle: subtitleController.text.isNotEmpty
                                ? subtitleController.text
                                : null,
                            imageUrl: imageUrlController.text.isNotEmpty
                                ? imageUrlController.text
                                : null,
                            animationUrl: animationUrlController.text.isNotEmpty
                                ? animationUrlController.text
                                : null,
                            gradientPreset: selectedGradient,
                            targetRoute: targetRouteController.text.isNotEmpty
                                ? targetRouteController.text
                                : null,
                            order: banner?.order ?? 0,
                          );
                          if (isEditing) {
                            ref
                                .read(featuredBannersProvider.notifier)
                                .updateBanner(newBanner);
                          } else {
                            ref
                                .read(featuredBannersProvider.notifier)
                                .addBanner(newBanner);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Publish Banner',
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
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return AdminTextField(controller: controller, label: label, hint: hint);
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    FeaturedBannerModel banner,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) =>
          Center(
                child: AdminGlassCard(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          color: AppColors.error,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Delete Banner?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to remove "${banner.title}"? This cannot be undone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Keep it',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                ref
                                    .read(featuredBannersProvider.notifier)
                                    .deleteBanner(banner.id);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.9, 0.9),
                curve: Curves.easeOutBack,
                duration: 400.ms,
              )
              .fadeIn(),
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
              tooltip: 'Upload Image',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref,
    TextEditingController controller,
    String folder,
    StateSetter setDialogState,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        final url = await ref
            .read(uploadServiceProvider)
            .uploadMedia(result.files.first, folder);
        if (url != null) {
          setDialogState(() {
            controller.text = url;
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _pickAndUploadLottie(
    BuildContext context,
    WidgetRef ref,
    TextEditingController controller,
    String folder,
    StateSetter setDialogState,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final url = await ref
            .read(uploadServiceProvider)
            .uploadMedia(result.files.first, folder);
        if (url != null) {
          setDialogState(() {
            controller.text = url;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lottie animation uploaded!')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }
}

class _BannerCard extends StatefulWidget {
  final FeaturedBannerModel banner;
  final bool isDark;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BannerCard({
    required this.banner,
    required this.isDark,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
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

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(widget.banner.gradientPreset);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AdminGlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual Banner Area
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  // Abstract patterns or Glow
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 400;
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.banner.title,
                                    style: TextStyle(
                                      fontSize: isSmall ? 20 : 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (widget.banner.subtitle != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.banner.subtitle!,
                                      style: TextStyle(
                                        fontSize: isSmall ? 13 : 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Action buttons inside banner
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _BannerActionButton(
                                  icon: Icons.edit_note_rounded,
                                  onTap: widget.onEdit,
                                ),
                                const SizedBox(height: 12),
                                _BannerActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  onTap: widget.onDelete,
                                  isDelete: true,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Info Bar
            if (widget.banner.targetRoute != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.banner.targetRoute!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (widget.index * 60).ms).slideY(begin: 0.1);
  }
}

class _BannerActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDelete;

  const _BannerActionButton({
    required this.icon,
    required this.onTap,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDelete ? Colors.white.withValues(alpha: 0.9) : Colors.white,
        ),
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
