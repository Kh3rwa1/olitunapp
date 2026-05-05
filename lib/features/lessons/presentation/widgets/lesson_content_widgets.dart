import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../core/presentation/animations/scale_button.dart';

/// Grid of Ol Chiki letter cards for the lesson detail screen.
class LetterGridContent extends ConsumerWidget {
  final String lessonId;

  const LetterGridContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLetters = ref.read(lettersProvider).value ?? [];
    final letters = allLetters.where((l) => l.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (letters.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No letters available yet',
        isDark: isDark,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
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
            context.push('/letter/$lessonId/${letter.charOlChiki}');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
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
}

/// Grid of Santali number cards for the lesson detail screen.
class NumberGridContent extends ConsumerWidget {
  final String lessonId;

  const NumberGridContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allNumbers = ref.read(numbersProvider).value ?? [];
    final numbers = allNumbers.where((n) => n.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (numbers.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No numbers available yet',
        isDark: isDark,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
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
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
}

/// List of vocabulary word cards for the lesson detail screen.
class VocabularyListContent extends ConsumerWidget {
  final String lessonId;

  const VocabularyListContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allWords = ref.read(wordsProvider).value ?? [];
    final words = allWords.where((w) => w.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (words.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No words available yet',
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
                                color:
                                    isDark ? Colors.white70 : Colors.black54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              word.meaning,
                              style: TextStyle(
                                fontSize: 15,
                                color:
                                    isDark ? Colors.white : Colors.black87,
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
}

/// List of sentence cards for the lesson detail screen.
class SentenceListContent extends ConsumerWidget {
  final String lessonId;

  const SentenceListContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSentences = ref.read(sentencesProvider).value ?? [];
    final sentences = allSentences.where((s) => s.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (sentences.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No sentences available yet',
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
                                color:
                                    isDark ? Colors.white70 : Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              sentence.meaning,
                              style: TextStyle(
                                fontSize: 15,
                                color:
                                    isDark ? Colors.white : Colors.black87,
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
