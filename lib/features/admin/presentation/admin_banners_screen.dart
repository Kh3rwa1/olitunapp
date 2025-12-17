import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';

class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(featuredBannersProvider);
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
              title: const Text('Featured Banners'),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBannerDialog(context, ref, null),
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
                          'Featured Banners',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Manage home screen promotional banners',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    PrimaryButton(
                      text: 'Add Banner',
                      
                      icon: Icons.add_rounded,
                      onPressed: () => _showBannerDialog(context, ref, null),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: bannersAsync.when(
                data: (banners) {
                  if (banners.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.featured_play_list_outlined,
                            size: 64,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No banners yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          PrimaryButton(
                            text: 'Add First Banner',
                            
                            onPressed: () => _showBannerDialog(context, ref, null),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return _BannerPreviewCard(
                        banner: banner,
                        onEdit: () => _showBannerDialog(context, ref, banner),
                        onDelete: () => _showDeleteDialog(context, ref, banner),
                      );
                    },
                  );
                },
                loading: () => const ShimmerLessonList(itemCount: 3),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBannerDialog(BuildContext context, WidgetRef ref, FeaturedBannerModel? banner) {
    final isEditing = banner != null;
    final titleController = TextEditingController(text: banner?.title ?? '');
    final subtitleController = TextEditingController(text: banner?.subtitle ?? '');
    final targetRouteController = TextEditingController(text: banner?.targetRoute ?? '');
    String selectedGradient = banner?.gradientPreset ?? 'skyBlue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          title: Text(isEditing ? 'Edit Banner' : 'Add Banner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Continue Learning',
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle',
                    hintText: 'e.g., Pick up where you left off',
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  controller: targetRouteController,
                  decoration: const InputDecoration(
                    labelText: 'Target Route (optional)',
                    hintText: 'e.g., /lessons',
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
                      gradient: AppColors.coralGradient,
                      isSelected: selectedGradient == 'coral',
                      onTap: () => setDialogState(() => selectedGradient = 'coral'),
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
                final newBanner = FeaturedBannerModel(
                  id: banner?.id ?? '',
                  title: titleController.text,
                  subtitle: subtitleController.text.isNotEmpty ? subtitleController.text : null,
                  gradientPreset: selectedGradient,
                  targetRoute: targetRouteController.text.isNotEmpty ? targetRouteController.text : null,
                  order: banner?.order ?? 0,
                  isActive: true,
                );
                await contentRepo.saveBanner(newBanner);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, FeaturedBannerModel banner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: const Text('Delete Banner'),
        content: Text('Are you sure you want to delete "${banner.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final contentRepo = ref.read(contentRepositoryProvider);
              await contentRepo.deleteBanner(banner.id);
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

class _BannerPreviewCard extends StatelessWidget {
  final FeaturedBannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BannerPreviewCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(banner.gradientPreset);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (banner.subtitle != null)
                  Text(
                    banner.subtitle!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (banner.targetRoute != null)
                Expanded(
                  child: Text(
                    'Route: ${banner.targetRoute}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
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
            ],
          ),
        ],
      ),
    );
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
      case 'coral':
        return AppColors.coralGradient;
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
          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
