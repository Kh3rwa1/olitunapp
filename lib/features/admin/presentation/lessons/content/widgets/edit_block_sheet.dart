import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../../../core/api/ai_service.dart';
import '../../../../../../shared/providers/providers.dart';
import '../../../../../../shared/utils/media_type_resolver.dart';
import '../../../widgets/admin_form_widgets.dart';
import '../../../letters/widgets/letter_form_sheet.dart';
import '../../../numbers/widgets/number_form_sheet.dart';
import '../../../sentences/widgets/sentence_form_sheet.dart';
import '../../../words/widgets/word_form_sheet.dart';

class EditBlockSheet extends ConsumerStatefulWidget {
  final LessonBlockEntity block;
  final ValueChanged<LessonBlockEntity> onUpdate;

  const EditBlockSheet({
    super.key,
    required this.block,
    required this.onUpdate,
  });

  static void show({
    required BuildContext context,
    required LessonBlockEntity block,
    required ValueChanged<LessonBlockEntity> onUpdate,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: EditBlockSheet(block: block, onUpdate: onUpdate),
            ),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<EditBlockSheet> createState() => _EditBlockSheetState();
}

class _EditBlockSheetState extends ConsumerState<EditBlockSheet> {
  late final TextEditingController olChikiCtrl;
  late final TextEditingController latinCtrl;
  late final TextEditingController quizRefCtrl;
  late final TextEditingController _pronCtrl;
  late final TextEditingController _themeColorCtrl;
  String? _imageUrl;
  String? _audioUrl;
  String? _animationUrl;
  bool isTranslating = false;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    olChikiCtrl = TextEditingController(text: block.textOlChiki ?? '');
    latinCtrl = TextEditingController(text: block.textLatin ?? '');

    // Parse visual media universally across candidates
    final candidates = [
      block.data?['heroMediaUrl'],
      block.data?['mediaUrl'],
      block.data?['videoUrl'],
      block.data?['animationUrl'],
      block.data?['htmlUrl'],
      block.data?['imageUrl'],
      block.imageUrl,
      if (block.type == 'video') block.audioUrl,
    ];
    String? matchedUrl;
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) {
        matchedUrl = c.trim();
        break;
      }
    }

    if (matchedUrl != null) {
      if (MediaTypeResolver.resolve(matchedUrl) == MediaKind.lottie) {
        _animationUrl = matchedUrl;
        _imageUrl = null;
      } else {
        _imageUrl = matchedUrl;
        _animationUrl = null;
      }
    } else {
      _imageUrl = null;
      _animationUrl = null;
    }

    _audioUrl = block.audioUrl;
    quizRefCtrl = TextEditingController(text: block.data?['quizRefId'] ?? '');
    _pronCtrl = TextEditingController(text: block.data?['pronunciation'] ?? '');
    _themeColorCtrl = TextEditingController(
      text: block.data?['themeColor'] ?? '',
    );
  }

  @override
  void dispose() {
    olChikiCtrl.dispose();
    latinCtrl.dispose();
    quizRefCtrl.dispose();
    _pronCtrl.dispose();
    _themeColorCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final mediaUrl = (_animationUrl != null && _animationUrl!.trim().isNotEmpty)
        ? _animationUrl!.trim()
        : ((_imageUrl != null && _imageUrl!.trim().isNotEmpty)
              ? _imageUrl!.trim()
              : null);

    final finalAudioUrl = _audioUrl?.trim().isNotEmpty == true
        ? _audioUrl!.trim()
        : null;
    String? finalImageUrl = (_imageUrl != null && _imageUrl!.trim().isNotEmpty)
        ? _imageUrl!.trim()
        : null;
    final finalAnimationUrl =
        (_animationUrl != null && _animationUrl!.trim().isNotEmpty)
        ? _animationUrl!.trim()
        : null;

    // For Lottie animations, we set imageUrl = finalAnimationUrl for compatibility
    if (finalAnimationUrl != null) {
      finalImageUrl = finalAnimationUrl;
    }

    final updatedBlock = LessonBlockEntity(
      type: widget.block.type,
      textOlChiki: olChikiCtrl.text.isEmpty ? null : olChikiCtrl.text,
      textLatin: latinCtrl.text.isEmpty ? null : latinCtrl.text,
      imageUrl: finalImageUrl,
      audioUrl: widget.block.type == 'video'
          ? (finalImageUrl ?? finalAudioUrl)
          : finalAudioUrl,
      data: {
        ...?widget.block.data,
        'animationUrl': finalAnimationUrl,
        'mediaUrl': mediaUrl,
        'heroMediaUrl': mediaUrl,
        'mediaType':
            widget.block.type != 'text' &&
                widget.block.type != 'quiz' &&
                widget.block.type != 'audio'
            ? widget.block.type
            : (mediaUrl != null
                  ? MediaTypeResolver.appwriteHeroMediaType(mediaUrl)
                  : null),
        'quizRefId': quizRefCtrl.text.isNotEmpty ? quizRefCtrl.text : null,
        'pronunciation': _pronCtrl.text.trim().isNotEmpty
            ? _pronCtrl.text.trim()
            : null,
        'themeColor': _themeColorCtrl.text.trim().isNotEmpty
            ? _themeColorCtrl.text.trim()
            : null,
      }..removeWhere((key, value) => value == null),
    );
    widget.onUpdate(updatedBlock);
    Navigator.pop(context);
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
              foregroundColor: Colors.white,
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
                    setState(() => _themeColorCtrl.text = p['hex']!);
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
                  setState(() => _themeColorCtrl.clear());
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final block = widget.block;
    final linkedContent = _resolveLinkedContent();

    IconData icon;
    Color iconColor;
    String typeLabel;

    switch (block.type) {
      case 'text':
        icon = Icons.text_fields_rounded;
        iconColor = Colors.blue;
        typeLabel = 'Text Block';
        break;
      case 'image':
        icon = Icons.image_rounded;
        iconColor = AppColors.duoBlue;
        typeLabel = 'Image Block';
        break;
      case 'svg':
        icon = Icons.polyline_rounded;
        iconColor = const Color(0xFF0EA5E9);
        typeLabel = 'SVG Block';
        break;
      case 'audio':
        icon = Icons.audiotrack_rounded;
        iconColor = Colors.orange;
        typeLabel = 'Audio Block';
        break;
      case 'video':
        icon = Icons.videocam_rounded;
        iconColor = Colors.purple;
        typeLabel = 'Video Block';
        break;
      case 'lottie':
        icon = Icons.animation_rounded;
        iconColor = const Color(0xFF10B981);
        typeLabel = 'Lottie Animation';
        break;
      case 'quiz':
        icon = Icons.quiz_rounded;
        iconColor = Colors.green;
        typeLabel = 'Quiz Block';
        break;
      default:
        icon = Icons.extension;
        iconColor = Colors.grey;
        typeLabel = 'Content Block';
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radius2xl),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit $typeLabel',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Modify this block\'s details & presentation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (linkedContent != null) ...[
                    _buildLinkedContentPanel(linkedContent, isDark),
                    const SizedBox(height: 20),
                  ],
                  if (block.type == 'quiz') ...[
                    AdminTextField(
                      controller: quizRefCtrl,
                      label: 'Quiz Reference ID',
                      hint: 'Start typing quiz ID...',
                    ),
                  ] else ...[
                    AdminTextField(
                      controller: olChikiCtrl,
                      label: 'Ol Chiki Text (Optional)',
                      hint: 'Enter Ol Chiki text',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AdminTextField(
                            controller: latinCtrl,
                            label:
                                'Translation / Latin Text / Caption (Optional)',
                            hint: 'Enter English translation or caption',
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: isTranslating
                              ? null
                              : () async {
                                  if (olChikiCtrl.text.trim().isEmpty) return;
                                  setState(() => isTranslating = true);
                                  try {
                                    final result = await ref
                                        .read(aiServiceProvider)
                                        .translateFromOlChiki(
                                          olChikiCtrl.text.trim(),
                                        );
                                    if (result != null) {
                                      latinCtrl.text = result.translation;
                                    }
                                  } finally {
                                    setState(() => isTranslating = false);
                                  }
                                },
                          icon: isTranslating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 20,
                                ),
                          tooltip: 'Magic Fill (AI Translate)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AdminTextField(
                      controller: _pronCtrl,
                      label: 'Pronunciation Guide (Optional)',
                      hint: 'e.g., pronunciation guide',
                    ),
                    const SizedBox(height: 24),
                    _buildThemeColorSelector(isDark),
                    const SizedBox(height: 24),
                    AdminMediaField(
                      label: 'Audio Pronunciation (Optional)',
                      icon: Icons.audiotrack_rounded,
                      accent: const Color(0xFF8B5CF6),
                      currentUrl: _audioUrl,
                      uploadFolder: 'lesson-audio',
                      fileType: FileType.audio,
                      onUploaded: (url) => setState(() => _audioUrl = url),
                    ),
                    const SizedBox(height: 24),
                    AdminMediaField(
                      label: 'Visual Media (Optional)',
                      subtitle:
                          'Supports PNG, JPG, WebP, GIF, SVG, Lottie JSON, MP4/webm video, or HTML.',
                      icon: Icons.perm_media_rounded,
                      accent: const Color(0xFF6366F1),
                      currentUrl: _animationUrl ?? _imageUrl,
                      uploadFolder: 'lesson-media',
                      fileType: FileType.custom,
                      allowedExtensions: const [
                        'png',
                        'jpg',
                        'jpeg',
                        'webp',
                        'gif',
                        'svg',
                        'json',
                        'lottie',
                        'mp4',
                        'webm',
                        'mov',
                        'm4v',
                        'html',
                        'htm',
                      ],
                      onUploaded: (url) {
                        setState(() {
                          if (url != null &&
                              MediaTypeResolver.resolve(url) ==
                                  MediaKind.lottie) {
                            _animationUrl = url;
                            _imageUrl = null;
                          } else {
                            _imageUrl = url;
                            _animationUrl = null;
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
