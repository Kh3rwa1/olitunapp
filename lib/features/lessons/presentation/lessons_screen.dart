import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final progress = ref.watch(userProgressProvider);
    final letters = ref.watch(lettersProvider);

    return BubbleBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Learning Journey',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Master Ol Chiki step by step',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Alphabet Preview (Letters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ol Chiki Alphabet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to full alphabet
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    letters.when(
                      data: (letterList) => _buildLetterPreview(context, letterList),
                      loading: () => const ShimmerCard(height: 100),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingL),
            ),

            // Categories Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                ),
                child: Text(
                  'Learning Modules',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingM),
            ),

            // Categories List
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
              ),
              sliver: categories.when(
                data: (categoryList) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categoryList[index];
                      final categoryProgress = progress.when(
                        data: (list) {
                          final p = list.where((p) => p.categoryId == category.id).firstOrNull;
                          return p?.percent ?? 0.0;
                        },
                        loading: () => 0.0,
                        error: (_, __) => 0.0,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.spacingM,
                        ),
                        child: _ModuleCard(
                          category: category,
                          progress: categoryProgress,
                          onTap: () => context.goNamed(
                            'categoryLessons',
                            pathParameters: {'categoryId': category.id},
                          ),
                        ),
                      );
                    },
                    childCount: categoryList.length,
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: ShimmerLessonList(itemCount: 4),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: Center(child: Text('Failed to load modules')),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingXL),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterPreview(BuildContext context, List<LetterModel> letters) {
    final previewLetters = letters.take(6).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: previewLetters.map((letter) {
              return Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        letter.charOlChiki,
                        style: const TextStyle(
                          fontFamily: 'OlChiki',
                          fontSize: 24,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    letter.transliterationLatin,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final CategoryModel category;
  final double progress;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.category,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = _getGradient(category.gradientPreset);

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          // Progress Ring with Icon
          Stack(
            alignment: Alignment.center,
            children: [
              ProgressRing(
                progress: progress / 100,
                size: 72,
                strokeWidth: 6,
                progressGradient: gradient,
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    _getIcon(category.iconName),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppConstants.spacingM),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.titleLatin,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (category.titleOlChiki.isNotEmpty) ...[
                  const SizedBox(height: 2),
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
                const SizedBox(height: AppConstants.spacingS),
                Row(
                  children: [
                    // Progress bar
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      '${progress.toInt()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),

          // Arrow
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ],
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
      case 'sentences':
        return Icons.format_quote_rounded;
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
      case 'sunset':
        return AppColors.sunsetGradient;
      case 'coral':
        return AppColors.coralGradient;
      case 'mint':
        return AppColors.mintGradient;
      case 'purple':
        return AppColors.purpleGradient;
      default:
        return AppColors.skyBlueGradient;
    }
  }
}
