import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Shimmer loading placeholder for cards
class ShimmerCard extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.width,
    this.height = 120,
    this.borderRadius = AppConstants.radiusLarge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      highlightColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer loading for text lines
class ShimmerText extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerText({
    super.key,
    this.width = 100,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      highlightColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Shimmer loading for circles (avatars, icons)
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      highlightColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Shimmer loading for featured banner
class ShimmerFeaturedBanner extends StatelessWidget {
  const ShimmerFeaturedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      highlightColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
      ),
    );
  }
}

/// Shimmer loading for category grid
class ShimmerCategoryGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerCategoryGrid({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.spacingM,
        mainAxisSpacing: AppConstants.spacingM,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          highlightColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer loading for lesson list
class ShimmerLessonList extends StatelessWidget {
  final int itemCount;

  const ShimmerLessonList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          highlightColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
          ),
        );
      },
    );
  }
}

/// Full page shimmer loading
class ShimmerPage extends StatelessWidget {
  const ShimmerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Row(
            children: [
              const ShimmerCircle(size: 48),
              const SizedBox(width: AppConstants.spacingM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerText(width: 120, height: 20),
                  SizedBox(height: 8),
                  ShimmerText(width: 80, height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Stats row shimmer
          const Row(
            children: [
              ShimmerCard(width: 80, height: 40, borderRadius: 12),
              SizedBox(width: AppConstants.spacingM),
              ShimmerCard(width: 80, height: 40, borderRadius: 12),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Featured banners shimmer
          const ShimmerFeaturedBanner(),
          const SizedBox(height: AppConstants.spacingM),
          const ShimmerFeaturedBanner(),
          const SizedBox(height: AppConstants.spacingL),
          
          // Section title shimmer
          const ShimmerText(width: 150, height: 24),
          const SizedBox(height: AppConstants.spacingM),
          
          // Grid shimmer
          const ShimmerCategoryGrid(itemCount: 4),
        ],
      ),
    );
  }
}
