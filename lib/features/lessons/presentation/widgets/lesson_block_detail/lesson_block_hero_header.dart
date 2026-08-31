import 'package:flutter/material.dart';

import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/full_bleed_hero_media.dart';
import 'package:itun/shared/utils/media_type_resolver.dart';

/// Top hero media section for the lesson block detail view.
class LessonBlockHeroHeader extends StatelessWidget {
  const LessonBlockHeroHeader({
    super.key,
    required this.block,
    required this.accentColor,
    required this.isDark,
    required this.topHeight,
    required this.blendColor,
    required this.displayText,
    required this.glyph,
    required this.isLongText,
    required this.animationUrl,
  });

  final LessonBlockEntity block;
  final Color accentColor;
  final bool isDark;
  final double topHeight;
  final Color blendColor;
  final String displayText;
  final String glyph;
  final bool isLongText;
  final String? animationUrl;

  static bool isLottieMedia(String url) {
    return MediaTypeResolver.resolve(url) == MediaKind.lottie;
  }

  @override
  Widget build(BuildContext context) {
    final titleTextColor = (animationUrl != null)
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1E293B));

    final badgeBgColor = (animationUrl != null)
        ? Colors.white.withValues(alpha: 0.15)
        : (isDark
              ? Colors.white.withValues(alpha: 0.1)
              : accentColor.withValues(alpha: 0.08));

    final badgeTextColor = (animationUrl != null)
        ? Colors.white
        : (isDark ? Colors.white70 : accentColor);

    return Container(
      height: topHeight,
      width: double.infinity,
      decoration: animationUrl == null
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.85), accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (glyph.isNotEmpty)
            Positioned(
              right: -20,
              top: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: animationUrl != null ? 0.06 : 0.14,
                  child: Text(
                    glyph,
                    style: TextStyle(
                      fontSize: 240,
                      fontWeight: FontWeight.w900,
                      color: animationUrl != null
                          ? Colors.white
                          : (isDark ? Colors.white : accentColor),
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          if (animationUrl != null) ...[
            // Edge-to-Edge Hero Media
            Positioned.fill(
              child: FullBleedHeroMedia(
                mediaKind: MediaTypeResolver.resolveFromType(
                  block.data?['mediaType'] as String? ?? block.type,
                ),
                animationUrl:
                    (block.type == 'lottie' ||
                        (block.data?['mediaType'] as String?) == 'lottie' ||
                        isLottieMedia(animationUrl!))
                    ? animationUrl
                    : null,
                imageUrl: animationUrl,
                isSvg:
                    block.type == 'svg' ||
                    (block.data?['mediaType'] as String?) == 'svg',
                fallback: Center(
                  child: Icon(
                    block.type == 'video' ||
                            (block.data?['mediaType'] as String?) == 'video'
                        ? Icons.videocam_rounded
                        : (block.type == 'lottie' ||
                                  (block.data?['mediaType'] as String?) ==
                                      'lottie'
                              ? Icons.animation_rounded
                              : Icons.image_rounded),
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            // Dark elegant gradient overlay for text readability + blending bottom edge
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.transparent,
                        blendColor,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Title Overlay Text
          Positioned(
            left: 24,
            bottom: 12,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: animationUrl != null
                        ? null
                        : Border.all(
                            color: badgeTextColor.withValues(alpha: 0.15),
                          ),
                  ),
                  child: Text(
                    (block.data?['mediaType'] as String? ?? block.type)
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: badgeTextColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: isLongText ? 20 : 32,
                    fontWeight: FontWeight.w900,
                    color: titleTextColor,
                    shadows: animationUrl != null
                        ? [
                            const Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
