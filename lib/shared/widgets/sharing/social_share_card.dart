import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'share_card_payload.dart';

class SocialShareCard extends StatelessWidget {
  final ShareCardPayload payload;

  const SocialShareCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderXxl,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Header & Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'OLITUN • ᱚᱞ ᱪᱤᱠᱤ',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Central Icon / Emoji Visualizer
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: Center(
              child: payload.emoji != null
                  ? Text(payload.emoji!, style: const TextStyle(fontSize: 40))
                  : Icon(
                      payload.icon ?? Icons.star_rounded,
                      color: AppColors.accentOchre,
                      size: 44,
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            payload.title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          if (payload.olChikiText != null &&
              payload.olChikiText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              payload.olChikiText!,
              textAlign: TextAlign.center,
              style: AppTypography.olChikiHeading.copyWith(
                color: AppColors.accentOchre,
                fontSize: 20,
              ),
            ),
          ],

          if (payload.subtitle != null && payload.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              payload.subtitle!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Metrics Bento Box
          if (payload.metricLabel != null && payload.metricValue != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        payload.metricLabel!,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payload.metricValue!,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (payload.secondaryMetricLabel != null &&
                      payload.secondaryMetricValue != null) ...[
                    Container(height: 24, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          payload.secondaryMetricLabel!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payload.secondaryMetricValue!,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentOchre,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Footer Watermark
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Colors.white60,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Learn Santali (Ol Chiki) • olitun.app',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
