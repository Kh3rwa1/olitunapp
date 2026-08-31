import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/presentation/animations/scale_button.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../../../shared/widgets/bento_grid.dart';
import '../../../../content/presentation/providers/audio_playback_providers.dart';
import '../../../domain/entities/lesson_entity.dart';

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

    final lessons = ref.watch(learnerLessonsProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;
    final blocks = lesson?.blocks ?? [];
    final blockIndex = blocks.indexOf(block);
    final fallbackRoute = blockIndex != -1
        ? '/lesson/$lessonId/block/$blockIndex'
        : null;

    final activeRoute = navRoute ?? fallbackRoute;

    return ScaleButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        if (activeRoute != null) {
          context.push(activeRoute);
        } else {
          if (block.audioUrl != null && block.audioUrl!.isNotEmpty) {
            ref
                .read(playbackControllerProvider)
                .playSingle(
                  id: block.audioUrl!,
                  contentKind: 'lesson',
                  contentId: block.textOlChiki ?? block.textLatin ?? block.type,
                  trackType: 'instruction',
                  languageCode: 'sat',
                );
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

                        if (meaning.isEmpty && activeRoute != null) {
                          if (activeRoute.contains('/word/')) {
                            final wordId = activeRoute.split('/').last;
                            final matchedWord =
                                ref.read(learnerWordsProvider).value ?? [];
                            final matchedWordEntity = matchedWord
                                .where((w) => w.id == wordId)
                                .firstOrNull;
                            if (matchedWordEntity != null) {
                              meaning = matchedWordEntity.meaning;
                            }
                          } else if (activeRoute.contains('/sentence/')) {
                            final sentenceId = activeRoute.split('/').last;
                            final matchedSentence =
                                ref.read(learnerSentencesProvider).value ?? [];
                            final matchedSentenceEntity = matchedSentence
                                .where((s) => s.id == sentenceId)
                                .firstOrNull;
                            if (matchedSentenceEntity != null) {
                              meaning = matchedSentenceEntity.meaning;
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
            if (activeRoute != null)
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

    final letters = ref.read(learnerLettersProvider).value ?? [];
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
      if (matched != null) return '/number/$lessonId/${matched.id}';
    }

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
      if (matched != null) return '/word/$lessonId/${matched.id}';
    }

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
      if (matched != null) return '/sentence/$lessonId/${matched.id}';
    }

    return null;
  }
}
