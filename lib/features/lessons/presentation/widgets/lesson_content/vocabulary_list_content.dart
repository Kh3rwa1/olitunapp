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
import '../../../domain/entities/lesson_entity.dart';
import 'empty_content_placeholder.dart';
import 'lesson_content_helpers.dart';

/// List of vocabulary word cards for the lesson detail screen.
/// Scoped: only shows words that appear in the lesson's blocks.
class VocabularyListContent extends ConsumerWidget {
  final String lessonId;

  const VocabularyListContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allWords = ref.watch(learnerWordsProvider).value ?? [];
    final lessons = ref.watch(learnerLessonsProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;

    final words = _scopeWords(allWords, lesson);

    if (words.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No words in this lesson. Add content blocks in admin.',
        isDark: isDark,
      );
    }

    final layoutMode = ref.watch(lessonLayoutModeProvider);

    final teachingLanguage = ref.watch(effectiveTeachingLanguageProvider);
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final isOlChikiOnly = scriptMode == 'olchiki';

    if (layoutMode == LessonLayoutMode.grid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getResponsiveCrossAxisCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: words.length,
        itemBuilder: (context, index) {
          final word = words[index];
          final transliteration = word.localizedTransliteration(
            teachingLanguage,
          );
          final meaning = word.localizedMeaning(teachingLanguage);

          return ScaleButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/word/$lessonId/${word.id}');
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
                          word.wordOlChiki,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isOlChikiOnly) ...[
                          const SizedBox(height: 6),
                          Text(
                            transliteration.isNotEmpty
                                ? transliteration
                                : word.wordLatin,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (word.pronunciation != null &&
                            word.pronunciation!.isNotEmpty &&
                            !isOlChikiOnly) ...[
                          const SizedBox(height: 2),
                          Text(
                            '[${word.pronunciation}]',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (meaning.isNotEmpty && !isOlChikiOnly) ...[
                          const SizedBox(height: 4),
                          Text(
                            meaning,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                        size: 10,
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

    return Column(
      children: words.map((word) {
        final transliteration = word.localizedTransliteration(teachingLanguage);
        final meaning = word.localizedMeaning(teachingLanguage);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ScaleButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/word/$lessonId/${word.id}');
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: contentCardDecoration(isDark),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.wordOlChiki,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            height: 1.2,
                          ),
                        ),
                        if (!isOlChikiOnly) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                transliteration.isNotEmpty
                                    ? transliteration
                                    : word.wordLatin,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (word.pronunciation != null &&
                                  word.pronunciation!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: isDark ? 0.2 : 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: isDark ? 0.35 : 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '[${word.pronunciation}]',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (meaning.isNotEmpty && !isOlChikiOnly) ...[
                          const SizedBox(height: 8),
                          Text(
                            meaning,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const ContentNavArrow(),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<WordModel> _scopeWords(List<WordModel> allWords, LessonEntity? lesson) {
    if (lesson == null || lesson.blocks.isEmpty) {
      return const [];
    }

    final blockTexts = lesson.blocks
        .where((b) => b.type == 'text' && b.textOlChiki != null)
        .map((b) => b.textOlChiki!.trim())
        .toSet();

    if (blockTexts.isEmpty) return const [];

    return allWords
        .where(
          (w) =>
              w.isActive &&
              blockTexts.any((t) => isTextMatch(t, w.wordOlChiki)),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
