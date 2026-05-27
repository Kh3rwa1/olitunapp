import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/content_badge_resolver.dart';

class ContentTypeBadge extends StatelessWidget {
  final ContentBadgeType type;
  final double size;
  final bool showLabel;
  final bool hasShadowRing;
  final EdgeInsets? padding;

  const ContentTypeBadge({
    super.key,
    required this.type,
    this.size = 32,
    this.showLabel = false,
    this.hasShadowRing = false,
    this.padding,
  });

  static const Map<ContentBadgeType, String> labels = {
    ContentBadgeType.letters: 'Letters',
    ContentBadgeType.numbers: 'Numbers',
    ContentBadgeType.words: 'Words',
    ContentBadgeType.sentences: 'Sentences',
    ContentBadgeType.video: 'Video',
    ContentBadgeType.audio: 'Audio',
    ContentBadgeType.quiz: 'Quiz',
    ContentBadgeType.tracing: 'Tracing',
    ContentBadgeType.typing: 'Typing',
    ContentBadgeType.lesson: 'Lesson',
  };

  static const Map<ContentBadgeType, IconData> icons = {
    ContentBadgeType.letters: Icons.abc_rounded,
    ContentBadgeType.numbers: Icons.numbers_rounded,
    ContentBadgeType.words: Icons.menu_book_rounded,
    ContentBadgeType.sentences: Icons.chat_bubble_outline_rounded,
    ContentBadgeType.video: Icons.play_circle_outline_rounded,
    ContentBadgeType.audio: Icons.music_note_rounded,
    ContentBadgeType.quiz: Icons.quiz_rounded,
    ContentBadgeType.tracing: Icons.gesture_rounded,
    ContentBadgeType.typing: Icons.keyboard_alt_rounded,
    ContentBadgeType.lesson: Icons.school_rounded,
  };

  static const Map<ContentBadgeType, Color> colors = {
    ContentBadgeType.letters: AppColors.badgeLetters,
    ContentBadgeType.numbers: AppColors.badgeNumbers,
    ContentBadgeType.words: AppColors.badgeWords,
    ContentBadgeType.sentences: AppColors.badgeSentences,
    ContentBadgeType.video: AppColors.badgeVideo,
    ContentBadgeType.audio: AppColors.badgeAudio,
    ContentBadgeType.quiz: AppColors.badgeQuiz,
    ContentBadgeType.tracing: AppColors.badgeTracing,
    ContentBadgeType.typing: AppColors.badgeTyping,
    ContentBadgeType.lesson: AppColors.badgeLesson,
  };

  double get _iconSize => (size * 0.6).roundToDouble();
  double get _fontSize => (size * 0.4).clamp(11.0, 14.0);

  @override
  Widget build(BuildContext context) {
    final color = colors[type] ?? AppColors.badgeLesson;
    final icon = icons[type] ?? Icons.extension;
    final label = labels[type] ?? 'Lesson';

    final textStyle = TextStyle(
      fontSize: _fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.3,
    );

    return Semantics(
      label: 'Content type: $label',
      container: true,
      child: Container(
        padding:
            padding ??
            (showLabel
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : EdgeInsets.zero),
        width: showLabel ? null : size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(showLabel ? size / 2 : 8),
          boxShadow: hasShadowRing
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: _iconSize),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(label, style: textStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
