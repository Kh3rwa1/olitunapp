import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/accessibility/learning_semantics.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../core/presentation/animations/scale_button.dart';
import '../../../../shared/utils/media_type_resolver.dart';
import '../../domain/entities/lesson_entity.dart';
import 'full_bleed_hero_media.dart';

/// Robust fuzzy matching for Ol Chiki text against entity labels.
bool _isFuzzyMatch(String target, String entityText) {
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

/// Renders a single dynamic content block (text, image, quiz, lottie).
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
        final mediaUrl = _blockVisualMediaUrl(block);

        final textBlock = hasText
            ? _TextBlock(
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
            _UniversalMediaBlock(
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
        return _AudioBlock(
          block: block,
          isDark: isDark,
          accentColor: accentColor,
        );
      case 'quiz':
        return _QuizBlock(
          block: block,
          accentColor: accentColor,
          brandGradient: brandGradient,
        );
      case 'html':
        return _HtmlBlock(
          block: block,
          isDark: isDark,
          accentColor: accentColor,
        );
      default:
        final mediaUrl = _blockVisualMediaUrl(block);
        if (mediaUrl != null) {
          return _UniversalMediaBlock(
            lessonId: lessonId,
            block: block,
            isDark: isDark,
            accentColor: accentColor,
            isSvg: block.type == 'svg',
          );
        }
        return const SizedBox.shrink();
    }
  }
}

/// Text block with fuzzy-match navigation to letters/numbers/words/sentences.
class _TextBlock extends ConsumerWidget {
  final String lessonId;
  final LessonBlockEntity block;
  final bool isDark;
  final Color accentColor;

  const _TextBlock({
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

    final lessons = ref.watch(lessonNotifierProvider).value ?? [];
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
    final letters = ref.read(lettersProvider).value ?? [];
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
      if (matched != null) {
        return '/number/$lessonId/${matched.id}';
      }
    }

    // 3. Words exact match
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
      if (matched != null) {
        return '/word/$lessonId/${matched.id}';
      }
    }

    // 4. Sentences exact match
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
      if (matched != null) {
        return '/sentence/$lessonId/${matched.id}';
      }
    }

    // --- PHASE 2: FUZZY MATCHES (Fallback for backward compatibility) ---

    // Check Letters
    final matchedLetterFuzzy = letters
        .where(
          (l) =>
              _isFuzzyMatch(t, l.charOlChiki) ||
              _isFuzzyMatch(t, l.transliterationLatin),
        )
        .firstOrNull;
    if (matchedLetterFuzzy != null) {
      return '/letter/$lessonId/${matchedLetterFuzzy.charOlChiki}';
    }

    // Check Numbers
    final matchedNumberFuzzy = numbers.where((n) {
      return _isFuzzyMatch(t, n.numeral) ||
          _isFuzzyMatch(t, n.value.toString()) ||
          _isFuzzyMatch(t, n.nameOlChiki) ||
          _isFuzzyMatch(t, n.nameLatin);
    }).firstOrNull;
    if (matchedNumberFuzzy != null) {
      return '/number/$lessonId/${matchedNumberFuzzy.id}';
    }

    // Check Words
    final matchedWordFuzzy = words
        .where(
          (w) =>
              _isFuzzyMatch(t, w.wordOlChiki) ||
              _isFuzzyMatch(t, w.wordLatin) ||
              _isFuzzyMatch(t, w.meaning),
        )
        .firstOrNull;
    if (matchedWordFuzzy != null) {
      return '/word/$lessonId/${matchedWordFuzzy.id}';
    }

    // Check Sentences
    final matchedSentenceFuzzy = sentences
        .where(
          (s) =>
              _isFuzzyMatch(t, s.sentenceOlChiki) ||
              _isFuzzyMatch(t, s.sentenceLatin) ||
              _isFuzzyMatch(t, s.meaning),
        )
        .firstOrNull;
    if (matchedSentenceFuzzy != null) {
      return '/sentence/$lessonId/${matchedSentenceFuzzy.id}';
    }

    return null;
  }
}

String? _blockVisualMediaUrl(LessonBlockEntity block) {
  final data = block.data;
  final candidates = [
    data?['heroMediaUrl'],
    data?['mediaUrl'],
    data?['videoUrl'],
    data?['animationUrl'],
    data?['htmlUrl'],
    data?['imageUrl'],
    block.imageUrl,
    if (block.type == 'video') block.audioUrl,
  ];

  for (final candidate in candidates) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      final value = candidate.trim();
      if (MediaTypeResolver.isRenderableHero(value)) return value;
    }
  }
  return null;
}

bool _isLottieMedia(String url) {
  return MediaTypeResolver.resolve(url) == MediaKind.lottie;
}

class _UniversalMediaBlock extends ConsumerWidget {
  const _UniversalMediaBlock({
    required this.lessonId,
    required this.block,
    required this.isDark,
    required this.accentColor,
    this.isSvg = false,
  });

  final String lessonId;
  final LessonBlockEntity block;
  final bool isDark;
  final Color accentColor;
  final bool isSvg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = _blockVisualMediaUrl(block);
    if (url == null) return const SizedBox.shrink();

    final lessons = ref.watch(lessonNotifierProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;
    final blockIndex = lesson?.blocks.indexOf(block) ?? -1;
    final route = blockIndex >= 0
        ? '/lesson/$lessonId/block/$blockIndex'
        : null;
    final caption = block.textLatin?.trim() ?? '';

    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: FullBleedHeroMedia(
              animationUrl: _isLottieMedia(url) ? url : null,
              imageUrl: url,
              isSvg: isSvg,
              fallback: Icon(
                Icons.perm_media_rounded,
                size: 52,
                color: accentColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                caption,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );

    if (route == null) return card;
    return ScaleButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      child: card,
    );
  }
}

class _AudioBlock extends ConsumerWidget {
  const _AudioBlock({
    required this.block,
    required this.isDark,
    required this.accentColor,
  });

  final LessonBlockEntity block;
  final bool isDark;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioUrl = block.audioUrl?.trim();
    if (audioUrl == null || audioUrl.isEmpty) return const SizedBox.shrink();
    final label = block.textLatin?.trim().isNotEmpty == true
        ? block.textLatin!.trim()
        : 'Play audio';

    return ScaleButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        ref.read(audioServiceProvider).playUrl(audioUrl);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_fill_rounded, color: accentColor, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiz CTA block that navigates to the quiz screen.
class _QuizBlock extends StatelessWidget {
  final LessonBlockEntity block;
  final Color accentColor;
  final LinearGradient brandGradient;

  const _QuizBlock({
    required this.block,
    required this.accentColor,
    required this.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    final quizRefId = block.data?['quizRefId'] as String?;
    return ScaleButton(
      onPressed: () {
        if (quizRefId != null) {
          context.push('/quiz/$quizRefId');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: brandGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.quiz_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Take a Quiz',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Test your knowledge now!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Dynamic HTML rendering block. Parses standard block and inline HTML tags natively in pure Flutter.
class _HtmlBlock extends StatelessWidget {
  final LessonBlockEntity block;
  final bool isDark;
  final Color accentColor;

  const _HtmlBlock({
    required this.block,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final htmlContent =
        block.data?['htmlContent'] as String? ?? block.textLatin ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parseHtmlToWidgets(htmlContent, isDark, accentColor),
      ),
    );
  }

  List<Widget> _parseHtmlToWidgets(
    String htmlText,
    bool isDark,
    Color accentColor,
  ) {
    final List<Widget> widgets = [];
    final String cleanText = htmlText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final RegExp blockRegExp = RegExp(
      r'(<(h[1-6]|p|ul|li|br|pre|div|a)[^>]*>[\s\S]*?<\/\2>|<br\s*\/?>)',
      caseSensitive: false,
    );

    if (!cleanText.contains('<')) {
      widgets.add(
        Text(
          cleanText,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      );
      return widgets;
    }

    int lastIndex = 0;
    for (final Match match in blockRegExp.allMatches(cleanText)) {
      if (match.start > lastIndex) {
        final plainText = cleanText.substring(lastIndex, match.start).trim();
        if (plainText.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _renderInlineHtml(
                plainText,
                isDark,
                accentColor,
                15,
                FontWeight.normal,
                null,
              ),
            ),
          );
        }
      }

      final blockText = match.group(0)!;
      final tagName = match.group(2)?.toLowerCase();

      if (tagName == 'br') {
        widgets.add(const SizedBox(height: 8));
      } else {
        final contentStartIndex = blockText.indexOf('>') + 1;
        final contentEndIndex = blockText.lastIndexOf('</');
        final content = contentStartIndex < contentEndIndex
            ? blockText.substring(contentStartIndex, contentEndIndex)
            : '';

        if (tagName == 'h1') {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: _renderInlineHtml(
                content,
                isDark,
                accentColor,
                24,
                FontWeight.w800,
                accentColor,
              ),
            ),
          );
        } else if (tagName == 'h2') {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: _renderInlineHtml(
                content,
                isDark,
                accentColor,
                20,
                FontWeight.w700,
                isDark ? Colors.white : Colors.black,
              ),
            ),
          );
        } else if (tagName == 'h3') {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _renderInlineHtml(
                content,
                isDark,
                accentColor,
                18,
                FontWeight.w600,
                isDark ? Colors.white : Colors.black,
              ),
            ),
          );
        } else if (tagName == 'p') {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _renderInlineHtml(
                content,
                isDark,
                accentColor,
                15,
                FontWeight.normal,
                isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          );
        } else if (tagName == 'li') {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: _renderInlineHtml(
                      content,
                      isDark,
                      accentColor,
                      15,
                      FontWeight.normal,
                      isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (tagName == 'pre') {
          widgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black26
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _renderInlineHtml(
                content,
                isDark,
                accentColor,
                14,
                FontWeight.normal,
                isDark ? Colors.white70 : Colors.black87,
                isMonospace: true,
              ),
            ),
          );
        } else if (tagName == 'div') {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _renderInlineHtml(
                content,
                isDark,
                accentColor,
                15,
                FontWeight.normal,
                isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          );
        }
      }

      lastIndex = match.end;
    }

    if (lastIndex < cleanText.length) {
      final remainingText = cleanText.substring(lastIndex).trim();
      if (remainingText.isNotEmpty) {
        widgets.add(
          _renderInlineHtml(
            remainingText,
            isDark,
            accentColor,
            15,
            FontWeight.normal,
            null,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _renderInlineHtml(
    String text,
    bool isDark,
    Color accentColor,
    double baseFontSize,
    FontWeight baseFontWeight,
    Color? baseColor, {
    bool isMonospace = false,
  }) {
    final List<TextSpan> spans = [];

    final RegExp inlineRegExp = RegExp(
      r'(<(b|strong|i|em|u|span)[^>]*>([\s\S]*?)<\/\2>|([^<]+))',
      caseSensitive: false,
    );

    for (final Match match in inlineRegExp.allMatches(text)) {
      final tagMatch = match.group(2);
      final tagContent = match.group(3);
      final plainText = match.group(4);

      if (plainText != null && plainText.isNotEmpty) {
        spans.add(
          TextSpan(
            text: plainText,
            style: TextStyle(
              fontSize: baseFontSize,
              fontWeight: baseFontWeight,
              color: baseColor ?? (isDark ? Colors.white70 : Colors.black87),
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        );
      } else if (tagContent != null) {
        final String tag = tagMatch!.toLowerCase();
        FontWeight fw = baseFontWeight;
        FontStyle fs = FontStyle.normal;
        TextDecoration dec = TextDecoration.none;
        Color? col = baseColor;

        if (tag == 'b' || tag == 'strong') {
          fw = FontWeight.bold;
        } else if (tag == 'i' || tag == 'em') {
          fs = FontStyle.italic;
        } else if (tag == 'u') {
          dec = TextDecoration.underline;
        } else if (tag == 'span') {
          final fullTag = match.group(1) ?? '';
          final colorMatch = RegExp(
            r'color\s*:\s*([^;"]+)',
            caseSensitive: false,
          ).firstMatch(fullTag);
          if (colorMatch != null) {
            final colorStr = colorMatch.group(1)!.trim().toLowerCase();
            if (colorStr.startsWith('#')) {
              try {
                final hex = colorStr.replaceAll('#', '');
                col = Color(int.parse('FF$hex', radix: 16));
              } catch (_) {}
            } else if (colorStr == 'primary') {
              col = accentColor;
            } else if (colorStr == 'red') {
              col = Colors.red;
            } else if (colorStr == 'green') {
              col = Colors.green;
            } else if (colorStr == 'blue') {
              col = Colors.blue;
            }
          }
        }

        spans.add(
          TextSpan(
            text: tagContent,
            style: TextStyle(
              fontSize: baseFontSize,
              fontWeight: fw,
              fontStyle: fs,
              decoration: dec,
              color: col ?? (isDark ? Colors.white70 : Colors.black87),
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        );
      }
    }

    return RichText(text: TextSpan(children: spans));
  }
}
