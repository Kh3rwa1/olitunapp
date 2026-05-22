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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const maxExtent = 180.0;
        const spacing = 16.0;
        int columns = ((width + spacing) / (maxExtent + spacing)).floor();
        if (columns < 1) columns = 1;

        final cardWidth = (width - (spacing * (columns - 1))) / columns;
        final cardHeight = cardWidth / 0.9;
        final rowsCount = (letters.length / columns).ceil();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(rowsCount, (rowIndex) {
            final start = rowIndex * columns;
            final end = (start + columns < letters.length)
                ? start + columns
                : letters.length;
            final rowLetters = letters.sublist(start, end);

            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex < rowsCount - 1 ? spacing : 0,
              ),
              child: Row(
                children: List.generate(columns, (colIndex) {
                  final hasItem = colIndex < rowLetters.length;
                  final rightPadding = colIndex < columns - 1 ? spacing : 0.0;

                  if (!hasItem) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: rightPadding),
                        child: const SizedBox.shrink(),
                      ),
                    );
                  }

                  final letter = rowLetters[colIndex];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: rightPadding),
                      child: SizedBox(
                        height: cardHeight,
                        child: ScaleButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (letter.audioUrl != null &&
                                letter.audioUrl!.isNotEmpty) {
                              ref
                                  .read(audioServiceProvider)
                                  .playUrl(letter.audioUrl!);
                            }
                            context.push(
                              '/letter/$lessonId/${letter.charOlChiki}',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.06,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
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
                                        letter.transliterationLatin
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
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
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
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
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const maxExtent = 150.0;
        const spacing = 14.0;
        int columns = ((width + spacing) / (maxExtent + spacing)).floor();
        if (columns < 1) columns = 1;

        final cardWidth = (width - (spacing * (columns - 1))) / columns;
        final cardHeight = cardWidth / 0.85;
        final rowsCount = (numbers.length / columns).ceil();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(rowsCount, (rowIndex) {
            final start = rowIndex * columns;
            final end = (start + columns < numbers.length)
                ? start + columns
                : numbers.length;
            final rowNumbers = numbers.sublist(start, end);

            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex < rowsCount - 1 ? spacing : 0,
              ),
              child: Row(
                children: List.generate(columns, (colIndex) {
                  final hasItem = colIndex < rowNumbers.length;
                  final rightPadding = colIndex < columns - 1 ? spacing : 0.0;

                  if (!hasItem) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: rightPadding),
                        child: const SizedBox.shrink(),
                      ),
                    );
                  }

                  final number = rowNumbers[colIndex];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: rightPadding),
                      child: SizedBox(
                        height: cardHeight,
                        child: ScaleButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push('/number/$lessonId/${number.id}');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.05,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        number.nameLatin,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
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
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
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
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
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
