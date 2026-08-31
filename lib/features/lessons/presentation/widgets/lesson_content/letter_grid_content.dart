import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/presentation/animations/scale_button.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/text_match.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../../../shared/widgets/bento_grid.dart';
import '../../../../content/presentation/providers/audio_playback_providers.dart';
import '../../../domain/entities/lesson_entity.dart';
import 'empty_content_placeholder.dart';
import 'lesson_content_helpers.dart';

/// Grid of Ol Chiki letter cards for the lesson detail screen.
/// Scoped: only shows letters that appear in the lesson's blocks.
class LetterGridContent extends ConsumerWidget {
  final String lessonId;

  const LetterGridContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLetters = ref.watch(learnerLettersProvider).value ?? [];
    final lessons = ref.watch(learnerLessonsProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;

    // Scope letters to this lesson's blocks
    final letters = _scopeLetters(allLetters, lesson);

    if (letters.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No letters in this lesson. Add content blocks in admin.',
        isDark: isDark,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: getResponsiveCrossAxisCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        return ScaleButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            if (letter.audioUrl != null && letter.audioUrl!.isNotEmpty) {
              ref
                  .read(playbackControllerProvider)
                  .playSingle(
                    id: letter.audioUrl!,
                    contentKind: 'letter',
                    contentId: letter.id,
                    trackType: 'targetNormal',
                    languageCode: 'sat',
                  );
            }
            context.push('/letter/$lessonId/${letter.charOlChiki}');
          },
          child: BentoCell(
            padding: const EdgeInsets.all(16),
            borderRadius: 24,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        letter.charOlChiki,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        letter.transliterationLatin.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Extract letters referenced by lesson blocks.
  /// Returns only matched letters — empty list triggers the placeholder.
  List<LetterModel> _scopeLetters(
    List<LetterModel> allLetters,
    LessonEntity? lesson,
  ) {
    if (lesson == null || lesson.blocks.isEmpty) {
      return const [];
    }

    final blockTexts = lesson.blocks
        .where((b) => b.type == 'text' && b.textOlChiki != null)
        .map((b) => b.textOlChiki!.trim())
        .toSet();

    if (blockTexts.isEmpty) return const [];

    return allLetters
        .where(
          (l) =>
              l.isActive &&
              blockTexts.any(
                (t) => isTextMatch(t, l.charOlChiki, isLetter: true),
              ),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
