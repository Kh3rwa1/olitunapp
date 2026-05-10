import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/models/content_models.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_glass_card.dart';
import 'widgets/banner_card.dart';
import 'widgets/banner_form_sheet.dart';

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
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        isWideScreen ? 32 : 20,
                        0,
                        isWideScreen ? 32 : 20,
                        100,
                      ),
                      itemCount: banners.length,
                      itemBuilder: (context, index) {
                        final banner = banners[index];
                        return BannerCard(
                          banner: banner,
                          isDark: isDark,
                          index: index,
                          onEdit: () =>
                              BannerFormSheet.show(context, ref, banner),
                          onDelete: () =>
                              _showDeleteDialog(context, ref, banner),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
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
      onAction: () => BannerFormSheet.show(context, ref, null),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
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
}
