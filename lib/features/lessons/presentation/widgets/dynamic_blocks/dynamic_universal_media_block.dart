import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/presentation/animations/scale_button.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../../../shared/utils/media_type_resolver.dart';
import '../../../domain/entities/lesson_entity.dart';
import '../full_bleed_hero_media.dart';

String? blockVisualMediaUrl(LessonBlockEntity block) {
  final data = block.data;
  final isVideo =
      block.type == 'video' || (data?['mediaType'] as String?) == 'video';
  final candidates = [
    if (isVideo) block.audioUrl,
    data?['heroMediaUrl'],
    data?['mediaUrl'],
    data?['videoUrl'],
    data?['animationUrl'],
    data?['htmlUrl'],
    data?['imageUrl'],
    block.imageUrl,
    if (!isVideo) block.audioUrl,
  ];

  for (final candidate in candidates) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      final value = candidate.trim();
      if (MediaTypeResolver.isRenderableHero(value)) return value;
    }
  }
  return null;
}

bool isLottieMedia(String url) {
  return MediaTypeResolver.resolve(url) == MediaKind.lottie;
}

class DynamicUniversalMediaBlock extends ConsumerWidget {
  const DynamicUniversalMediaBlock({
    super.key,
    required this.lessonId,
    required this.block,
    required this.isDark,
    required this.accentColor,
    this.isSvg = false,
  });

  final String lessonId;
  final LessonBlockEntity block;
  final bool isDark;
  final Color accentColor;
  final bool isSvg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = blockVisualMediaUrl(block);
    if (url == null) return const SizedBox.shrink();

    final lessons = ref.watch(learnerLessonsProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;
    final blockIndex = lesson?.blocks.indexOf(block) ?? -1;
    final route = blockIndex >= 0
        ? '/lesson/$lessonId/block/$blockIndex'
        : null;
    final caption = block.textLatin?.trim() ?? '';

    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: FullBleedHeroMedia(
              mediaKind: MediaTypeResolver.resolveFromType(
                block.data?['mediaType'] as String? ?? block.type,
              ),
              animationUrl:
                  (block.type == 'lottie' ||
                      (block.data?['mediaType'] as String?) == 'lottie' ||
                      isLottieMedia(url))
                  ? url
                  : null,
              imageUrl: url,
              isSvg: isSvg || (block.data?['mediaType'] as String?) == 'svg',
              fallback: Icon(
                block.type == 'video' ||
                        (block.data?['mediaType'] as String?) == 'video'
                    ? Icons.videocam_rounded
                    : (block.type == 'lottie' ||
                              (block.data?['mediaType'] as String?) == 'lottie'
                          ? Icons.animation_rounded
                          : Icons.perm_media_rounded),
                size: 52,
                color: accentColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                caption,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );

    if (route == null) return card;
    return ScaleButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      child: card,
    );
  }
}
