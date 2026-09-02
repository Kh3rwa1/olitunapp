part of 'edit_block_sheet.dart';

// Sections extracted from EditBlockSheet. The extension keeps private access
// with zero import churn (pattern: admin_settings_sections.dart).
extension _EditBlockSheetSections on _EditBlockSheetState {
  MediaKind? _inferKindFromBlockType(String t) {
    switch (t) {
      case 'image':
        return MediaKind.image;
      case 'svg':
        return MediaKind.svg;
      case 'video':
        return MediaKind.video;
      case 'audio':
        return MediaKind.audio;
      case 'lottie':
        return MediaKind.lottie;
      default:
        return null;
    }
  }

  _LinkedContentMatch? _resolveLinkedContent() {
    if (widget.block.type != 'text') return null;

    final textCandidates = [
      widget.block.textOlChiki?.trim() ?? '',
      widget.block.textLatin?.trim() ?? '',
    ].where((text) => text.isNotEmpty).toList();
    if (textCandidates.isEmpty) return null;

    bool matches(String text, String value) {
      final cleanText = text.toLowerCase().trim();
      final cleanValue = value.toLowerCase().trim();
      if (cleanText.isEmpty || cleanValue.isEmpty) return false;
      return cleanText == cleanValue ||
          cleanText.contains(cleanValue) ||
          cleanValue.contains(cleanText);
    }

    bool anyCandidateMatches(List<String> values) {
      return textCandidates.any(
        (text) => values.any((value) => matches(text, value)),
      );
    }

    for (final letter in ref.read(lettersProvider).value ?? []) {
      if (anyCandidateMatches([
        letter.charOlChiki,
        letter.transliterationLatin,
      ])) {
        return _LinkedContentMatch(
          icon: Icons.text_fields_rounded,
          title: 'Linked Letter',
          subtitle: '${letter.charOlChiki} - ${letter.transliterationLatin}',
          actionLabel: 'Edit Letter Details',
          onOpen: () => LetterFormSheet.show(context, ref, letter),
        );
      }
    }

    for (final number in ref.read(numbersProvider).value ?? []) {
      if (anyCandidateMatches([
        number.numeral,
        number.value.toString(),
        number.nameOlChiki,
        number.nameLatin,
      ])) {
        return _LinkedContentMatch(
          icon: Icons.pin_rounded,
          title: 'Linked Number',
          subtitle: '${number.numeral} - ${number.nameLatin}',
          actionLabel: 'Edit Number Details',
          onOpen: () => NumberFormSheet.show(context, ref, number),
        );
      }
    }

    for (final word in ref.read(wordsProvider).value ?? []) {
      if (anyCandidateMatches([
        word.wordOlChiki,
        word.wordLatin,
        word.meaning,
      ])) {
        return _LinkedContentMatch(
          icon: Icons.menu_book_rounded,
          title: 'Linked Word',
          subtitle: '${word.wordLatin} - ${word.meaning}',
          actionLabel: 'Edit Word Details',
          onOpen: () => WordFormSheet.show(context, ref, word),
        );
      }
    }

    for (final sentence in ref.read(sentencesProvider).value ?? []) {
      if (anyCandidateMatches([
        sentence.sentenceOlChiki,
        sentence.sentenceLatin,
        sentence.meaning,
      ])) {
        return _LinkedContentMatch(
          icon: Icons.format_quote_rounded,
          title: 'Linked Sentence',
          subtitle: sentence.sentenceLatin,
          actionLabel: 'Edit Sentence Details',
          onOpen: () => SentenceFormSheet.show(context, ref, sentence),
        );
      }
    }

    return null;
  }

  Widget _buildLinkedContentPanel(_LinkedContentMatch match, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(match.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: match.onOpen,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(
              match.actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeColorSelector(bool isDark) {
    // Avoid purple/violet per Purple Ban.
    final presets = [
      {'name': 'Mint', 'hex': '#10B981'},
      {'name': 'Teal', 'hex': '#14B8A6'},
      {'name': 'Sky', 'hex': '#0EA5E9'},
      {'name': 'Rose', 'hex': '#F43F5E'},
      {'name': 'Amber', 'hex': '#F59E0B'},
      {'name': 'Charcoal', 'hex': '#1E293B'},
      {'name': 'White', 'hex': '#FFFFFF'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Color (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final p in presets)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _setState(() => _themeColorCtrl.text = p['hex']!);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(p['hex']!.replaceFirst('#', '0xFF')),
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _themeColorCtrl.text.toUpperCase() == p['hex']
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white24 : Colors.black12),
                        width: _themeColorCtrl.text.toUpperCase() == p['hex']
                            ? 2
                            : 1,
                      ),
                      boxShadow: [
                        if (_themeColorCtrl.text.toUpperCase() == p['hex'])
                          BoxShadow(
                            color: Color(
                              int.parse(p['hex']!.replaceFirst('#', '0xFF')),
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _setState(() => _themeColorCtrl.clear());
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _themeColorCtrl.text.isEmpty
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.format_color_reset_rounded,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminTextField(
          controller: _themeColorCtrl,
          label: 'Custom HEX Code',
          hint: 'e.g., #FF5722',
          prefixIcon: Icons.color_lens_rounded,
        ),
      ],
    );
  }

  String _mediaFieldLabel(String t) => switch (t) {
    'image' => 'Image',
    'svg' => 'SVG Vector',
    'video' => 'Video File',
    'audio' => 'Audio File',
    'lottie' => 'Lottie Animation (.json)',
    _ => 'Media',
  };

  String _mediaFieldSubtitle(String t) => switch (t) {
    'image' => 'Supports PNG, JPG, WebP, GIF.',
    'svg' => 'Supports SVG vector file.',
    'video' => 'Supports MP4, WebM, MOV.',
    'audio' => 'Supports MP3, WAV, M4A.',
    'lottie' => 'Supports JSON Lottie animations.',
    _ => 'Supports web-compatible formats.',
  };

  List<String> _allowedExtsFor(String t) => switch (t) {
    'image' => const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    'svg' => const ['svg'],
    'video' => const ['mp4', 'webm', 'mov', 'm4v'],
    'audio' => const ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
    'lottie' => const ['json', 'lottie'],
    _ => const [],
  };

  FileType _filePickerTypeFor(String t) => switch (t) {
    'image' || 'svg' => FileType.image,
    'video' => FileType.video,
    'audio' => FileType.audio,
    _ => FileType.custom,
  };

  String _uploadFolderFor(String t) => switch (t) {
    'video' => 'lesson-videos',
    'audio' => 'lesson-audio',
    'lottie' => 'lesson-animations',
    'svg' => 'lesson-svgs',
    _ => 'lesson-images',
  };
}

class _LinkedContentMatch {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onOpen;

  const _LinkedContentMatch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onOpen,
  });
}
