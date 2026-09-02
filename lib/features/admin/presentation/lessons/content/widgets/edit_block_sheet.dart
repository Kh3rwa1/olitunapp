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

part 'edit_block_sheet_sections.dart';

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

  String? _mediaUrl; // canonical media URL for image/svg/video/audio/lottie
  MediaKind? _mediaKind; // resolved kind, not inferred from field name
  String? _posterUrl; // video poster only
  String?
  _audioUrl; // optional secondary audio (e.g. for text/glyph pronunciation)
  bool isTranslating = false;

  /// Forwards to [setState] so extracted section builders (extensions on this
  /// State) can trigger rebuilds without touching protected members directly.
  void _setState(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    olChikiCtrl = TextEditingController(text: block.textOlChiki ?? '');
    latinCtrl = TextEditingController(text: block.textLatin ?? '');

    // Canonical resolution: prefer data.media.url, then legacy fallbacks
    final dataMedia = (block.data?['media'] is Map)
        ? (block.data!['media'] as Map).cast<String, dynamic>()
        : null;

    final candidate =
        dataMedia?['url'] as String? ??
        block.data?['heroMediaUrl'] as String? ??
        block.data?['mediaUrl'] as String? ??
        block.data?['videoUrl'] as String? ??
        block.data?['animationUrl'] as String? ??
        block.data?['imageUrl'] as String? ??
        (block.type == 'video' ? block.audioUrl : null) ??
        block.imageUrl;

    if (candidate != null && candidate.trim().isNotEmpty) {
      _mediaUrl = candidate.trim();
      final declaredKind =
          dataMedia?['kind'] as String? ?? block.data?['mediaType'] as String?;
      _mediaKind = declaredKind != null
          ? MediaTypeResolver.resolveFromType(declaredKind)
          : MediaTypeResolver.resolve(_mediaUrl);
      // For text blocks with type==text, kind stays null
      if (_mediaKind == MediaKind.unknown) {
        _mediaKind = _inferKindFromBlockType(block.type);
      }
    }

    _posterUrl =
        block.data?['posterUrl'] as String? ??
        (block.type == 'video' ? block.imageUrl : null);

    // Audio: only used when block.type=='audio' OR as pronunciation aid
    _audioUrl = block.type == 'video' ? null : block.audioUrl;

    quizRefCtrl = TextEditingController(
      text: (block.data?['quizId'] ?? block.data?['quizRefId'] ?? '') as String,
    );
    _pronCtrl = TextEditingController(
      text: block.data?['pronunciation'] as String? ?? '',
    );
    _themeColorCtrl = TextEditingController(
      text: block.data?['themeColor'] as String? ?? '',
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
    final cleanedMediaUrl = _mediaUrl?.trim().isNotEmpty == true
        ? _mediaUrl!.trim()
        : null;
    final cleanedPoster = _posterUrl?.trim().isNotEmpty == true
        ? _posterUrl!.trim()
        : null;
    final cleanedAudio = _audioUrl?.trim().isNotEmpty == true
        ? _audioUrl!.trim()
        : null;
    final resolvedKind = cleanedMediaUrl != null
        ? (_mediaKind ?? MediaTypeResolver.resolve(cleanedMediaUrl))
        : null;

    // Build the canonical media map ONCE.
    final mediaMap = cleanedMediaUrl == null
        ? null
        : {
            'url': cleanedMediaUrl,
            'kind': (resolvedKind ?? MediaKind.unknown).name,
            // fileId could be threaded through from upload widget; leave empty for now
            'fileId': '',
          };

    // Preserve any unknown keys from original data so we don't drop user edits made elsewhere
    final preservedData = <String, dynamic>{...?widget.block.data};

    // Strip legacy keys we now own canonically
    for (final k in const [
      'heroMediaUrl',
      'mediaUrl',
      'videoUrl',
      'animationUrl',
      'imageUrl',
      'mediaType',
      'quizRefId',
    ]) {
      preservedData.remove(k);
    }

    final newData = <String, dynamic>{
      ...preservedData,
      'media': ?mediaMap,
      'posterUrl': ?cleanedPoster,
      if (quizRefCtrl.text.trim().isNotEmpty) 'quizId': quizRefCtrl.text.trim(),
      if (_pronCtrl.text.trim().isNotEmpty)
        'pronunciation': _pronCtrl.text.trim(),
      if (_themeColorCtrl.text.trim().isNotEmpty)
        'themeColor': _themeColorCtrl.text.trim(),
      // Stable block id — only generate once
      'id':
          (preservedData['id'] as String?) ??
          'blk_${widget.block.type}_${DateTime.now().microsecondsSinceEpoch}',
    };

    final updated = LessonBlockEntity(
      type: widget.block.type,
      textOlChiki: olChikiCtrl.text.trim().isEmpty
          ? null
          : olChikiCtrl.text.trim(),
      textLatin: latinCtrl.text.trim().isEmpty ? null : latinCtrl.text.trim(),
      // Keep legacy fields populated for any old read paths still hanging around,
      // but mobile/admin should now read from data.media.
      imageUrl: widget.block.type == 'video' ? cleanedPoster : cleanedMediaUrl,
      audioUrl: widget.block.type == 'video' ? cleanedMediaUrl : cleanedAudio,
      data: newData,
    );

    widget.onUpdate(updated);
    Navigator.pop(context);
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
        iconColor = AppColors.brandBlue;
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
      case 'glyph':
        icon = Icons.abc_rounded;
        iconColor = const Color(0xFFEC4899);
        typeLabel = 'Glyph Block';
        break;
      case 'callout':
        icon = Icons.lightbulb_rounded;
        iconColor = const Color(0xFFF59E0B);
        typeLabel = 'Callout Block';
        break;
      case 'tracing':
        icon = Icons.gesture_rounded;
        iconColor = const Color(0xFF14B8A6);
        typeLabel = 'Tracing Block';
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
                    // === MEDIA SECTION ===
                    if (widget.block.type != 'text' &&
                        widget.block.type != 'quiz') ...[
                      AdminMediaField(
                        label: _mediaFieldLabel(widget.block.type),
                        subtitle: _mediaFieldSubtitle(widget.block.type),
                        icon: Icons.perm_media_rounded,
                        accent: const Color(0xFF6366F1),
                        currentUrl: _mediaUrl,
                        uploadFolder: _uploadFolderFor(widget.block.type),
                        fileType: _filePickerTypeFor(widget.block.type),
                        allowedExtensions: _allowedExtsFor(widget.block.type),
                        onUploaded: (url) {
                          setState(() {
                            _mediaUrl = url;
                            _mediaKind = url == null
                                ? null
                                : MediaTypeResolver.resolve(url);
                          });
                        },
                      ),
                      if (widget.block.type == 'video') ...[
                        const SizedBox(height: 24),
                        AdminMediaField(
                          label: 'Poster Image (Optional)',
                          subtitle: 'Shown before video plays. PNG/JPG/WebP.',
                          icon: Icons.image_rounded,
                          accent: const Color(0xFF8B5CF6),
                          currentUrl: _posterUrl,
                          uploadFolder: 'lesson-posters',
                          fileType: FileType.image,
                          onUploaded: (url) => setState(() => _posterUrl = url),
                        ),
                      ],
                    ],
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
