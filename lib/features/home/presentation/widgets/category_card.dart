import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:itun/shared/widgets/lottie_display.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/widgets/scale_button.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final double progress;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(category.gradientPreset);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: onTap ?? () {},
      child: SoftCard(
        onTap: null, // Handled by ScaleButton now
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      category.animationUrl != null &&
                          category.animationUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: LottieDisplay(
                            url: category.animationUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : category.iconUrl != null && category.iconUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _isLottieUrl(category.iconUrl!)
                              ? LottieDisplay(
                                  url: category.iconUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: category.iconUrl!,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                  errorWidget: (_, __, ___) =>
                                      _buildDefaultIcon(),
                                ),
                        )
                      : _buildDefaultIcon(),
                ),

                // Progress Ring
                ProgressRing(
                  progress: progress / 100,
                  size: 44,
                  strokeWidth: 4,
                  progressGradient: gradient,
                  child: Text(
                    '${progress.toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Title
            Text(
              category.titleLatin,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Ol Chiki Title
            if (category.titleOlChiki.isNotEmpty)
              Text(
                category.titleOlChiki,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'OlChiki',
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: AppConstants.spacingS),

            // Lessons count
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.lessonsCount(category.totalLessons),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Checks if a URL points to a Lottie JSON file
  bool _isLottieUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.json');
  }

  Widget _buildDefaultIcon() {
    final iconData = _getIconFromName(category.iconName);
    return Center(child: Icon(iconData, color: Colors.white, size: 24));
  }

  IconData _getIconFromName(String? name) {
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
        return AppColors.skyBlueGradient;
      default:
        return AppColors.skyBlueGradient;
    }
  }
}
