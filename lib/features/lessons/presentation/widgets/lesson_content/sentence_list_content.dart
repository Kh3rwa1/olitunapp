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

/// List of sentence cards for the lesson detail screen.
/// Scoped: only shows sentences that appear in the lesson's blocks.
class SentenceListContent extends ConsumerWidget {
  final String lessonId;

  const SentenceListContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSentences = ref.watch(learnerSentencesProvider).value ?? [];
    final lessons = ref.watch(learnerLessonsProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;

    final sentences = _scopeSentences(allSentences, lesson);

    if (sentences.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No sentences in this lesson. Add content blocks in admin.',
        isDark: isDark,
      );
    }

    final layoutMode = ref.watch(lessonLayoutModeProvider);

    if (layoutMode == LessonLayoutMode.grid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getResponsiveCrossAxisCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.82,
        ),
        itemCount: sentences.length,
        itemBuilder: (context, index) {
          final sentence = sentences[index];
          return ScaleButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/sentence/$lessonId/${sentence.id}');
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
                          sentence.sentenceOlChiki,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sentence.sentenceLatin,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sentence.meaning,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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
      children: sentences
          .map(
            (sentence) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ScaleButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/sentence/$lessonId/${sentence.id}');
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
                              sentence.sentenceOlChiki,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sentence.sentenceLatin,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (sentence.pronunciation != null &&
                                sentence.pronunciation!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
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
                                  'Pronunciation: ${sentence.pronunciation}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              sentence.meaning,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const ContentNavArrow(),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  List<SentenceModel> _scopeSentences(
    List<SentenceModel> allSentences,
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

    return allSentences
        .where(
          (s) =>
              s.isActive &&
              blockTexts.any((t) => isTextMatch(t, s.sentenceOlChiki)),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
