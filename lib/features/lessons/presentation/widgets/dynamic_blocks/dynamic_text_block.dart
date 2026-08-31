import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/accessibility/learning_semantics.dart';
import '../../../../../core/presentation/animations/scale_button.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../domain/entities/lesson_entity.dart';

/// Robust fuzzy matching for Ol Chiki text against entity labels.
bool isFuzzyMatch(String target, String entityText) {
  if (entityText.isEmpty) return false;
  final t = target.trim().toLowerCase();
  final e = entityText.trim().toLowerCase();

  if (t == e) return true;

  final separators = [' ', '-', '–', '—', '−', '.', '!', '?', ':', ';'];
  for (final s in separators) {
    if (t.startsWith('$e$s')) return true;
  }

  final tokens = t.split(RegExp(r'[\s\-\–\—\−\.\!\?\:\;]'));
  if (tokens.isNotEmpty && tokens.first == e) return true;

  final tClean = t.replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '').trim();
  final eClean = e.replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '').trim();
  if (tClean == eClean && tClean.isNotEmpty) return true;

  return false;
}

/// Renders a dynamic text block with optional navigation linking.
class DynamicTextBlock extends ConsumerWidget {
  final String lessonId;
  final LessonBlockEntity block;
  final bool isDark;
  final Color accentColor;

  const DynamicTextBlock({
    super.key,
    required this.lessonId,
    required this.block,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textOlChiki = block.textOlChiki?.trim() ?? '';
    final textLatin = block.textLatin?.trim() ?? '';

    if (textOlChiki.isEmpty && textLatin.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayText = textOlChiki.isNotEmpty ? textOlChiki : textLatin;

    final navRoute = _resolveNavRoute(ref, lessonId, displayText);

    final lessons = ref.watch(learnerLessonsProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;
    final blocks = lesson?.blocks ?? [];
    final blockIndex = blocks.indexOf(block);
    final fallbackRoute = blockIndex != -1
        ? '/lesson/$lessonId/block/$blockIndex'
        : null;

    final activeRoute = navRoute ?? fallbackRoute;

    final content = Semantics(
      label: LearningSemantics.olChikiText(
        text: displayText,
        latin: textOlChiki.isNotEmpty && textLatin.isNotEmpty
            ? textLatin
            : null,
      ),
      button: activeRoute != null,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activeRoute != null
                  ? accentColor.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.1),
              width: activeRoute != null ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: displayText.length < 5 ? 36 : 22,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        height: 1.2,
                      ),
                    ),
                    if (textOlChiki.isNotEmpty && textLatin.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        textLatin,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (activeRoute != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (activeRoute != null) {
      final route = activeRoute;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ScaleButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(route);
          },
          child: content,
        ),
      );
    }
    return content;
  }

  String? _resolveNavRoute(WidgetRef ref, String lessonId, String text) {
    final t = text.trim();
    if (t.isEmpty) return null;

    // Check if the text has a dash to split it for composite exact matches
    final dashRegex = RegExp(r'\s*[\-–—−]\s*');
    final List<String> parts = t.contains(dashRegex)
        ? t
              .split(dashRegex)
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList()
        : [t];

    // --- PHASE 1: EXACT MATCHES (to prevent fuzzy hijacking) ---

    // 1. Letters exact match
    final letters = ref.read(learnerLettersProvider).value ?? [];
    for (final part in parts) {
      final matched = letters
          .where(
            (l) =>
                l.charOlChiki.toLowerCase() == part.toLowerCase() ||
                l.transliterationLatin.toLowerCase() == part.toLowerCase(),
          )
          .firstOrNull;
      if (matched != null) {
        return '/letter/$lessonId/${matched.charOlChiki}';
      }
    }

    // 2. Numbers exact match
    final numbers = ref.read(learnerNumbersProvider).value ?? [];
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
      if (matched != null) {
        return '/number/$lessonId/${matched.id}';
      }
    }

    // 3. Words exact match
    final words = ref.read(learnerWordsProvider).value ?? [];
    for (final part in parts) {
      final matched = words
          .where(
            (w) =>
                w.wordOlChiki.toLowerCase() == part.toLowerCase() ||
                w.wordLatin.toLowerCase() == part.toLowerCase() ||
                w.meaning.toLowerCase() == part.toLowerCase(),
          )
          .firstOrNull;
      if (matched != null) {
        return '/word/$lessonId/${matched.id}';
      }
    }

    // 4. Sentences exact match
    final sentences = ref.read(learnerSentencesProvider).value ?? [];
    for (final part in parts) {
      final matched = sentences
          .where(
            (s) =>
                s.sentenceOlChiki.toLowerCase() == part.toLowerCase() ||
                s.sentenceLatin.toLowerCase() == part.toLowerCase() ||
                s.meaning.toLowerCase() == part.toLowerCase(),
          )
          .firstOrNull;
      if (matched != null) {
        return '/sentence/$lessonId/${matched.id}';
      }
    }

    // --- PHASE 2: FUZZY MATCHES (Fallback for backward compatibility) ---

    // Check Letters
    final matchedLetterFuzzy = letters
        .where(
          (l) =>
              isFuzzyMatch(t, l.charOlChiki) ||
              isFuzzyMatch(t, l.transliterationLatin),
        )
        .firstOrNull;
    if (matchedLetterFuzzy != null) {
      return '/letter/$lessonId/${matchedLetterFuzzy.charOlChiki}';
    }

    // Check Numbers
    final matchedNumberFuzzy = numbers.where((n) {
      return isFuzzyMatch(t, n.numeral) ||
          isFuzzyMatch(t, n.value.toString()) ||
          isFuzzyMatch(t, n.nameOlChiki) ||
          isFuzzyMatch(t, n.nameLatin);
    }).firstOrNull;
    if (matchedNumberFuzzy != null) {
      return '/number/$lessonId/${matchedNumberFuzzy.id}';
    }

    // Check Words
    final matchedWordFuzzy = words
        .where(
          (w) =>
              isFuzzyMatch(t, w.wordOlChiki) ||
              isFuzzyMatch(t, w.wordLatin) ||
              isFuzzyMatch(t, w.meaning),
        )
        .firstOrNull;
    if (matchedWordFuzzy != null) {
      return '/word/$lessonId/${matchedWordFuzzy.id}';
    }

    // Check Sentences
    final matchedSentenceFuzzy = sentences
        .where(
          (s) =>
              isFuzzyMatch(t, s.sentenceOlChiki) ||
              isFuzzyMatch(t, s.sentenceLatin) ||
              isFuzzyMatch(t, s.meaning),
        )
        .firstOrNull;
    if (matchedSentenceFuzzy != null) {
      return '/sentence/$lessonId/${matchedSentenceFuzzy.id}';
    }

    return null;
  }
}
