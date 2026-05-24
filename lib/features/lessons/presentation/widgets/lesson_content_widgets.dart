import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../core/presentation/animations/scale_button.dart';
import '../../../../shared/models/content_models.dart';
import '../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/utils/text_match.dart';
import '../../../../shared/widgets/bento_grid.dart';

int _getResponsiveCrossAxisCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 1200) {
    return 6;
  } else if (width > 800) {
    return 4;
  } else if (width > 600) {
    return 3;
  } else {
    return 2;
  }
}

/// Grid of Ol Chiki letter cards for the lesson detail screen.
/// Scoped: only shows letters that appear in the lesson's blocks.
class LetterGridContent extends ConsumerWidget {
  final String lessonId;

  const LetterGridContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLetters = ref.read(lettersProvider).value ?? [];
    final lessons = ref.read(lessonNotifierProvider).value ?? [];
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
        crossAxisCount: _getResponsiveCrossAxisCount(context),
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
              ref.read(audioServiceProvider).playUrl(letter.audioUrl!);
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

/// Grid of Santali number cards for the lesson detail screen.
/// Scoped: only shows numbers that appear in the lesson's blocks.
class NumberGridContent extends ConsumerWidget {
  final String lessonId;

  const NumberGridContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allNumbers = ref.read(numbersProvider).value ?? [];
    final lessons = ref.read(lessonNotifierProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;

    final numbers = _scopeNumbers(allNumbers, lesson);

    if (numbers.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No numbers in this lesson. Add content blocks in admin.',
        isDark: isDark,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getResponsiveCrossAxisCount(context),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final number = numbers[index];
        return ScaleButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/number/$lessonId/${number.id}');
          },
          child: BentoCell(
            padding: const EdgeInsets.all(14),
            borderRadius: 20,
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
                        number.numeral,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${number.value}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        number.nameLatin,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  /// Extract numbers referenced by lesson blocks.
  /// Returns only matched numbers — empty list triggers the placeholder.
  List<NumberModel> _scopeNumbers(
    List<NumberModel> allNumbers,
    LessonEntity? lesson,
  ) {
    if (lesson == null) {
      return const [];
    }

    final blockTexts = lesson.blocks
        .where((b) => b.type == 'text' && b.textOlChiki != null)
        .map((b) => b.textOlChiki!.trim())
        .toSet();

    if (blockTexts.isNotEmpty) {
      final scoped = allNumbers
          .where(
            (n) =>
                n.isActive &&
                blockTexts.any(
                  (t) =>
                      isTextMatch(t, n.numeral) ||
                      isTextMatch(t, n.value.toString()) ||
                      isTextMatch(t, n.nameOlChiki) ||
                      isTextMatch(t, n.nameLatin),
                ),
          )
          .toList();

      if (scoped.isNotEmpty) {
        return scoped..sort((a, b) => a.order.compareTo(b.order));
      }
    }

    // Fallback: If no blocks or no matching numbers were found, fallback to category/range mapping
    final title = lesson.titleLatin.toLowerCase();
    List<NumberModel> fallbackList = [];
    if (title.contains('0-9') ||
        title.contains('single') ||
        title.contains('basic')) {
      fallbackList = allNumbers
          .where((n) => n.value >= 0 && n.value <= 9 && n.isActive)
          .toList();
    } else if (title.contains('10-99') ||
        title.contains('double') ||
        title.contains('tens') ||
        title.contains('10 to 99')) {
      fallbackList = allNumbers
          .where((n) => n.value >= 10 && n.value <= 99 && n.isActive)
          .toList();
    } else if (title.contains('100') ||
        title.contains('hundred') ||
        title.contains('large')) {
      fallbackList = allNumbers
          .where((n) => n.value >= 100 && n.isActive)
          .toList();
    } else {
      // General fallback if the lesson title or category indicates it's a numbers category
      fallbackList = allNumbers.where((n) => n.isActive).toList();
    }

    return fallbackList..sort((a, b) => a.order.compareTo(b.order));
  }
}

/// List of vocabulary word cards for the lesson detail screen.
/// Scoped: only shows words that appear in the lesson's blocks.
class VocabularyListContent extends ConsumerWidget {
  final String lessonId;

  const VocabularyListContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allWords = ref.read(wordsProvider).value ?? [];
    final lessons = ref.read(lessonNotifierProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;

    final words = _scopeWords(allWords, lesson);

    if (words.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No words in this lesson. Add content blocks in admin.',
        isDark: isDark,
      );
    }

    final layoutMode = ref.watch(lessonLayoutModeProvider);

    if (layoutMode == LessonLayoutMode.grid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getResponsiveCrossAxisCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: words.length,
        itemBuilder: (context, index) {
          final word = words[index];
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
                        const SizedBox(height: 6),
                        Text(
                          word.wordLatin,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.meaning,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
      children: words
          .map(
            (word) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ScaleButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/word/$lessonId/${word.id}');
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(isDark),
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
                            const SizedBox(height: 4),
                            Text(
                              word.wordLatin,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              word.meaning,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _NavArrow(),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
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

/// List of sentence cards for the lesson detail screen.
/// Scoped: only shows sentences that appear in the lesson's blocks.
class SentenceListContent extends ConsumerWidget {
  final String lessonId;

  const SentenceListContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSentences = ref.read(sentencesProvider).value ?? [];
    final lessons = ref.read(lessonNotifierProvider).value ?? [];
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
          crossAxisCount: _getResponsiveCrossAxisCount(context),
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
                  decoration: _cardDecoration(isDark),
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
                      _NavArrow(),
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

/// Shared empty content placeholder.
class EmptyContentPlaceholder extends StatelessWidget {
  final String message;
  final bool isDark;

  const EmptyContentPlaceholder({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Shared decoration for content cards
BoxDecoration _cardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.15),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// Shared nav arrow indicator
class _NavArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }
}

/// Dynamic grid builder that renders the lesson's blocks directly to ensure
/// the grid view matches the list view item count perfectly (1:1 alignment).
class BlockGridContent extends ConsumerWidget {
  final String lessonId;
  final List<LessonBlockEntity> blocks;
  final String categoryId;

  const BlockGridContent({
    super.key,
    required this.lessonId,
    required this.blocks,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cleanCategory = categoryId.toLowerCase();
    final isAlphabet =
        cleanCategory.contains('alphabet') || cleanCategory.contains('letter');
    final isNumber = cleanCategory.contains('number');
    final isSentence =
        cleanCategory.contains('sentence') || cleanCategory.contains('phrase');

    if (blocks.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No items in this lesson. Add content blocks in admin.',
        isDark: isDark,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getResponsiveCrossAxisCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isAlphabet
            ? 0.9
            : (isNumber ? 0.85 : (isSentence ? 0.82 : 0.85)),
      ),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return DynamicBlockGridCell(
          lessonId: lessonId,
          block: block,
          isAlphabet: isAlphabet,
          isNumber: isNumber,
          isSentence: isSentence,
        );
      },
    );
  }
}

/// Bento styled grid cell representation of a single content block.
class DynamicBlockGridCell extends ConsumerWidget {
  final String lessonId;
  final LessonBlockEntity block;
  final bool isAlphabet;
  final bool isNumber;
  final bool isSentence;

  const DynamicBlockGridCell({
    super.key,
    required this.lessonId,
    required this.block,
    required this.isAlphabet,
    required this.isNumber,
    required this.isSentence,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textOlChiki = block.textOlChiki?.trim() ?? '';
    final textLatin = block.textLatin?.trim() ?? '';

    // All grid cells use primary brand neon green per user request
    const cellAccentColor = AppColors.primary;

    final navRoute =
        _resolveNavRoute(ref, lessonId, textOlChiki) ??
        (textLatin.isNotEmpty
            ? _resolveNavRoute(ref, lessonId, textLatin)
            : null);

    return ScaleButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        if (navRoute != null) {
          context.push(navRoute);
        } else {
          if (block.audioUrl != null && block.audioUrl!.isNotEmpty) {
            ref.read(audioServiceProvider).playUrl(block.audioUrl!);
          }
        }
      },
      child: BentoCell(
        padding: const EdgeInsets.all(14),
        borderRadius: 20,
        border: Border.all(
          color: cellAccentColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    textOlChiki,
                    style: TextStyle(
                      fontSize: isAlphabet
                          ? 44
                          : (isNumber ? 36 : (isSentence ? 20 : 26)),
                      fontWeight: FontWeight.w900,
                      color: cellAccentColor,
                      height: 1.2,
                    ),
                    maxLines: isSentence ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  if (textLatin.isNotEmpty) ...[
                    Text(
                      isAlphabet ? textLatin.toUpperCase() : textLatin,
                      style: TextStyle(
                        fontSize: isAlphabet
                            ? 16
                            : (isNumber ? 18 : (isSentence ? 13 : 14)),
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                        letterSpacing: isAlphabet ? 1.5 : 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!isAlphabet && !isNumber) ...[
                    Builder(
                      builder: (context) {
                        String meaning = '';
                        if (block.data != null &&
                            block.data!['meaning'] != null) {
                          meaning = block.data!['meaning'] as String;
                        }

                        if (meaning.isEmpty && navRoute != null) {
                          if (navRoute.contains('/word/')) {
                            final wordId = navRoute.split('/').last;
                            final matchedWord = ref
                                .read(wordsProvider)
                                .value
                                ?.where((w) => w.id == wordId)
                                .firstOrNull;
                            if (matchedWord != null) {
                              meaning = matchedWord.meaning;
                            }
                          } else if (navRoute.contains('/sentence/')) {
                            final sentenceId = navRoute.split('/').last;
                            final matchedSentence = ref
                                .read(sentencesProvider)
                                .value
                                ?.where((s) => s.id == sentenceId)
                                .firstOrNull;
                            if (matchedSentence != null) {
                              meaning = matchedSentence.meaning;
                            }
                          }
                        }

                        if (meaning.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              meaning,
                              style: TextStyle(
                                fontSize: isSentence ? 11 : 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: isSentence ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (navRoute != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cellAccentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: isAlphabet ? 12 : 10,
                    color: cellAccentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _resolveNavRoute(WidgetRef ref, String lessonId, String text) {
    final t = text.trim();
    if (t.isEmpty) return null;

    final dashRegex = RegExp(r'\s*[\-–—−]\s*');
    final List<String> parts = t.contains(dashRegex)
        ? t
              .split(dashRegex)
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList()
        : [t];

    final letters = ref.read(lettersProvider).value ?? [];
    for (final part in parts) {
      final matched = letters
          .where(
            (l) =>
                l.charOlChiki.toLowerCase() == part.toLowerCase() ||
                l.transliterationLatin.toLowerCase() == part.toLowerCase(),
          )
          .firstOrNull;
      if (matched != null) return '/letter/$lessonId/${matched.charOlChiki}';
    }

    final numbers = ref.read(numbersProvider).value ?? [];
    for (final part in parts) {
      final matched = numbers
          .where(
            (n) =>
                n.numeral.toLowerCase() == part.toLowerCase() ||
                n.value.toString().toLowerCase() == part.toLowerCase() ||
                n.nameOlChiki.toLowerCase() == part.toLowerCase() ||
                n.nameLatin.toLowerCase() == part.toLowerCase(),
          )
          .firstOrNull;
      if (matched != null) return '/number/$lessonId/${matched.id}';
    }

    final words = ref.read(wordsProvider).value ?? [];
    for (final part in parts) {
      final matched = words
          .where(
            (w) =>
                w.wordOlChiki.toLowerCase() == part.toLowerCase() ||
                w.wordLatin.toLowerCase() == part.toLowerCase() ||
                w.meaning.toLowerCase() == part.toLowerCase(),
          )
          .firstOrNull;
      if (matched != null) return '/word/$lessonId/${matched.id}';
    }

    final sentences = ref.read(sentencesProvider).value ?? [];
    for (final part in parts) {
      final matched = sentences
          .where(
            (s) =>
                s.sentenceOlChiki.toLowerCase() == part.toLowerCase() ||
                s.sentenceLatin.toLowerCase() == part.toLowerCase() ||
                s.meaning.toLowerCase() == part.toLowerCase(),
          )
          .firstOrNull;
      if (matched != null) return '/sentence/$lessonId/${matched.id}';
    }

    return null;
  }
}
