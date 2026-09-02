import 'package:flutter/material.dart';
import '../../../domain/entities/lesson_entity.dart';

/// Dynamic HTML rendering block. Parses standard block and inline HTML tags natively in pure Flutter.
class DynamicHtmlBlock extends StatelessWidget {
  final LessonBlockEntity block;
  final bool isDark;
  final Color accentColor;

  const DynamicHtmlBlock({
    super.key,
    required this.block,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final rawHtml =
        (block.data?['content'] ??
                block.data?['body'] ??
                block.data?['html'] ??
                block.textOlChiki ??
                block.textLatin)
            as String?;

    if (rawHtml == null || rawHtml.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parseHtmlBlocks(rawHtml.trim(), isDark, accentColor),
      ),
    );
  }

  List<Widget> _parseHtmlBlocks(String html, bool isDark, Color accentColor) {
    final List<Widget> widgets = [];

    // Normalize break lines and trim
    final cleanText = html.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final RegExp blockRegExp = RegExp(
      r'<(h1|h2|h3|p|li|pre|div|br)[^>]*>([\s\S]*?)<\/\1>|<br\s*\/?>',
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
              } catch (_) {
                // Malformed hex color — keep the base color.
              }
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
