import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:itun/shared/widgets/lottie_display.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/glass_card.dart';

class FeaturedBannerCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Gradient gradient;
  final String? imageUrl;
  final String? animationUrl;
  final IconData? icon;
  final VoidCallback? onTap;

  const FeaturedBannerCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.gradient,
    this.imageUrl,
    this.animationUrl,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: gradient,
      height: 140,
      padding: EdgeInsets.zero,
      borderRadius: AppConstants.radiusLarge,
      onTap: onTap,
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Background animation or image (if provided)
          if (animationUrl != null)
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.6,
                child: LottieDisplay(
                  url: animationUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  placeholder: const SizedBox.shrink(),
                  errorWidget: const SizedBox.shrink(),
                ),
              ),
            )
          else if (imageUrl != null)
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.3,
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppConstants.spacingM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingM,
                          vertical: AppConstants.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSmall,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (icon != null)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
