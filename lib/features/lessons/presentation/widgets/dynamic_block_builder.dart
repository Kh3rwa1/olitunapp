import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/lesson_entity.dart';
import 'dynamic_blocks/dynamic_audio_block.dart';
import 'dynamic_blocks/dynamic_html_block.dart';
import 'dynamic_blocks/dynamic_quiz_block.dart';
import 'dynamic_blocks/dynamic_text_block.dart';
import 'dynamic_blocks/dynamic_universal_media_block.dart';

/// Renders a single dynamic content block (text, image, quiz, lottie, html, audio).
class DynamicBlockBuilder extends ConsumerWidget {
  final String lessonId;
  final LessonBlockEntity block;

  const DynamicBlockBuilder({
    super.key,
    required this.lessonId,
    required this.block,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // All categories use primary brand neon green per user request
    const accentColor = AppColors.primary;
    const brandGradient = AppColors.heroGradient;

    switch (block.type) {
      case 'text':
      case 'image':
      case 'svg':
      case 'video':
      case 'lottie':
        final hasText =
            (block.textOlChiki?.trim().isNotEmpty == true) ||
            (block.textLatin?.trim().isNotEmpty == true);
        final mediaUrl = blockVisualMediaUrl(block);

        final textBlock = hasText
            ? DynamicTextBlock(
                lessonId: lessonId,
                block: block,
                isDark: isDark,
                accentColor: accentColor,
              )
            : const SizedBox.shrink();

        if (mediaUrl == null) return textBlock;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DynamicUniversalMediaBlock(
              lessonId: lessonId,
              block: block,
              isDark: isDark,
              accentColor: accentColor,
              isSvg:
                  block.type == 'svg' ||
                  mediaUrl.toLowerCase().contains('.svg'),
            ),
            if (hasText) const SizedBox(height: 12),
            textBlock,
          ],
        );
      case 'audio':
        return DynamicAudioBlock(
          block: block,
          isDark: isDark,
          accentColor: accentColor,
        );
      case 'quiz':
        return DynamicQuizBlock(
          block: block,
          accentColor: accentColor,
          brandGradient: brandGradient,
        );
      case 'html':
      case 'rich_text':
      case 'custom':
        return DynamicHtmlBlock(
          block: block,
          isDark: isDark,
          accentColor: accentColor,
        );
      default:
        return DynamicTextBlock(
          lessonId: lessonId,
          block: block,
          isDark: isDark,
          accentColor: accentColor,
        );
    }
  }
}
