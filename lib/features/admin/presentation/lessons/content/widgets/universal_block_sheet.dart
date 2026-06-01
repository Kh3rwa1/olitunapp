import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/utils/media_type_resolver.dart';
import '../../../../../../shared/providers/providers.dart';
import '../../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../widgets/admin_form_widgets.dart';

/// One sheet to rule them all. Replaces AddBlockSheet + per-type EditBlockSheet
/// variants. The block "type" is inferred from what the user actually fills in,
/// not picked up front.
///
/// Tracing is only offered when [categorySlug] matches alphabets / numbers slugs.
class UniversalBlockSheet extends ConsumerStatefulWidget {
  final LessonBlockEntity? existing;

  /// Lower-cased slug (or titleLatin.toLowerCase()) of the parent category.
  /// Used only to gate the Tracing toggle — null hides it.
  final String? categorySlug;

  final ValueChanged<LessonBlockEntity> onSubmit;

  const UniversalBlockSheet({
    super.key,
    this.existing,
    required this.categorySlug,
    required this.onSubmit,
  });

  bool get _tracingAllowed {
    final slug = categorySlug?.toLowerCase().trim() ?? '';
    return slug == 'alphabets' ||
        slug == 'alphabet' ||
        slug == 'letters' ||
        slug == 'letter' ||
        slug == 'numbers' ||
        slug == 'number';
  }

  @override
  ConsumerState<UniversalBlockSheet> createState() =>
      _UniversalBlockSheetState();
}

class _UniversalBlockSheetState extends ConsumerState<UniversalBlockSheet> {
  final _olChikiCtrl = TextEditingController();
  final _latinCtrl = TextEditingController();
  final _pronCtrl = TextEditingController();
  final _quizRefCtrl = TextEditingController();

  String? _mediaUrl;
  String? _posterUrl;
  String? _audioUrl;
  String? _calloutVariant;
  bool _tracingEnabled = false;
  String? _themeColor;
  bool _advancedOpen = false;
  bool _showCustomQuizIdInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentValue = _quizRefCtrl.text.trim();
      if (currentValue.isNotEmpty) {
        final quizzes = ref.read(quizzesProvider).valueOrNull ?? [];
        if (!quizzes.any((q) => q.id == currentValue)) {
          setState(() {
            _showCustomQuizIdInput = true;
          });
        }
      }
    });
    final b = widget.existing;
    if (b != null) {
      _olChikiCtrl.text = b.textOlChiki ?? '';
      _latinCtrl.text = b.textLatin ?? '';
      _audioUrl = b.audioUrl;
      final data = b.data ?? const {};
      _pronCtrl.text = (data['pronunciation'] as String?) ?? '';
      _quizRefCtrl.text =
          (data['quizId'] as String?) ?? (data['quizRefId'] as String?) ?? '';
      _posterUrl = data['posterUrl'] as String?;
      _calloutVariant = data['calloutVariant'] as String?;
      _tracingEnabled = b.type == 'tracing';
      _themeColor = data['themeColor'] as String?;

      // Canonical media URL — prefer nested media map, then legacy fields
      final mediaMap = data['media'];
      if (mediaMap is Map && mediaMap['url'] is String) {
        _mediaUrl = mediaMap['url'] as String;
      } else {
        _mediaUrl =
            b.imageUrl ??
            (data['mediaUrl'] as String?) ??
            (data['videoUrl'] as String?) ??
            (data['animationUrl'] as String?) ??
            (data['heroMediaUrl'] as String?);
      }
    }
  }

  @override
  void dispose() {
    _olChikiCtrl.dispose();
    _latinCtrl.dispose();
    _pronCtrl.dispose();
    _quizRefCtrl.dispose();
    super.dispose();
  }

  // ── Type inference ─────────────────────────────────────────────────────────

  String _resolveType() {
    if (_tracingEnabled && widget._tracingAllowed) return 'tracing';
    if (_quizRefCtrl.text.trim().isNotEmpty) return 'quiz';
    if (_calloutVariant != null) return 'callout';
    if (_mediaUrl != null && _mediaUrl!.isNotEmpty) {
      switch (MediaTypeResolver.resolve(_mediaUrl)) {
        case MediaKind.image:
          return 'image';
        case MediaKind.svg:
          return 'svg';
        case MediaKind.lottie:
          return 'lottie';
        case MediaKind.video:
          return 'video';
        case MediaKind.audio:
          return 'audio';
        case MediaKind.html:
          return 'html';
        case MediaKind.unknown:
          return 'image';
      }
    }
    return 'text';
  }

  MediaKind get _mediaKind => MediaTypeResolver.resolve(_mediaUrl);
  bool get _mediaIsVideo => _mediaKind == MediaKind.video;

  // ── Save ───────────────────────────────────────────────────────────────────

  void _save() {
    final type = _resolveType();

    final media = <String, dynamic>{};
    if (_mediaUrl != null && _mediaUrl!.isNotEmpty) {
      media['url'] = _mediaUrl;
      media['kind'] = _mediaKind.name;
    }

    // Start from existing data so unknown/future keys aren't lost
    final data = <String, dynamic>{
      ...?widget.existing?.data?.cast<String, dynamic>(),
      if (media.isNotEmpty) 'media': media,
      if (_mediaIsVideo && (_posterUrl?.isNotEmpty ?? false))
        'posterUrl': _posterUrl,
      if (_pronCtrl.text.trim().isNotEmpty)
        'pronunciation': _pronCtrl.text.trim(),
      if (_quizRefCtrl.text.trim().isNotEmpty)
        'quizId': _quizRefCtrl.text.trim(),
      if (_calloutVariant != null) 'calloutVariant': _calloutVariant,
      if (_themeColor != null) 'themeColor': _themeColor,
    };
    if (_audioUrl != null && _audioUrl!.isNotEmpty && type != 'audio') {
      data['audioUrl'] = _audioUrl;
    } else {
      data.remove('audioUrl');
    }
    // Remove legacy keys we've now canonicalised
    for (final k in const [
      'mediaUrl',
      'videoUrl',
      'animationUrl',
      'imageUrl',
      'heroMediaUrl',
      'quizRefId',
    ]) {
      data.remove(k);
    }

    final entity = LessonBlockEntity(
      type: type,
      textOlChiki: _olChikiCtrl.text.trim().isEmpty
          ? null
          : _olChikiCtrl.text.trim(),
      textLatin: _latinCtrl.text.trim().isEmpty ? null : _latinCtrl.text.trim(),
      imageUrl: (type == 'image' || type == 'svg' || type == 'lottie')
          ? _mediaUrl
          : (type == 'video' ? _posterUrl : null),
      audioUrl: type == 'audio' ? _mediaUrl : _audioUrl,
      data: data,
    );

    widget.onSubmit(entity);
    Navigator.of(context).pop();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inferred = _resolveType();
    final quizzesAsync = ref.watch(quizzesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: AdminTokens.overlay(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AdminTokens.overlayShadow(isDark),
        ),
        child: Column(
          children: [
            _DragHandle(isDark: isDark),
            _SheetHeader(
              isEditing: widget.existing != null,
              inferredType: inferred,
              onClose: () => Navigator.of(context).pop(),
              isDark: isDark,
            ),
            Divider(height: 1, color: AdminTokens.divider(isDark)),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Headline ─────────────────────────────────────────────
                  _SectionLabel(
                    'Headline',
                    subtitle: 'Both fields optional',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: 'Ol Chiki',
                    controller: _olChikiCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: 'Latin / translation',
                    controller: _latinCtrl,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 28),

                  // ── Media ─────────────────────────────────────────────────
                  _SectionLabel(
                    'Media',
                    subtitle:
                        'Image, video, audio, SVG, or Lottie — type auto-detected',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  AdminMediaField(
                    label: 'Attach media',
                    icon: Icons.attach_file_rounded,
                    accent: AppColors.primary,
                    currentUrl: _mediaUrl,
                    uploadFolder: 'lesson-media',
                    // Always use custom so allowedExtensions is valid
                    fileType: FileType.custom,
                    allowedExtensions: const [
                      'png',
                      'jpg',
                      'jpeg',
                      'webp',
                      'gif',
                      'svg',
                      'json',
                      'mp4',
                      'webm',
                      'mov',
                      'm4v',
                      'mp3',
                      'wav',
                      'ogg',
                      'm4a',
                      'aac',
                      'html',
                    ],
                    onUploaded: (url) => setState(() => _mediaUrl = url),
                  ),

                  if (_mediaIsVideo) ...[
                    const SizedBox(height: 16),
                    AdminMediaField(
                      label: 'Poster image (optional)',
                      subtitle: 'Shown before the video plays',
                      icon: Icons.image_rounded,
                      accent: const Color(0xFF22D3EE),
                      currentUrl: _posterUrl,
                      uploadFolder: 'lesson-media',
                      fileType: FileType.custom,
                      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
                      onUploaded: (url) => setState(() => _posterUrl = url),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Advanced ──────────────────────────────────────────────
                  _AdvancedToggle(
                    open: _advancedOpen,
                    onTap: () => setState(() => _advancedOpen = !_advancedOpen),
                    isDark: isDark,
                  ),
                  if (_advancedOpen) ...[
                    const SizedBox(height: 16),
                    AdminMediaField(
                      label: 'Pronunciation audio (optional)',
                      icon: Icons.mic_rounded,
                      accent: const Color(0xFFF472B6),
                      currentUrl: _audioUrl,
                      uploadFolder: 'lesson-audio',
                      fileType: FileType.custom,
                      allowedExtensions: const [
                        'mp3',
                        'wav',
                        'ogg',
                        'm4a',
                        'aac',
                      ],
                      onUploaded: (url) => setState(() => _audioUrl = url),
                    ),
                    const SizedBox(height: 16),
                    AdminTextField(
                      label: 'Pronunciation guide (text)',
                      controller: _pronCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    quizzesAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (err, _) => Text(
                        'Failed to load quizzes: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                      data: (quizzesList) {
                        final currentValue = _quizRefCtrl.text.trim();
                        final inList = quizzesList.any(
                          (q) => q.id == currentValue,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quiz Invitation (Optional)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _showCustomQuizIdInput
                                  ? '__custom__'
                                  : (inList ? currentValue : ''),
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('None / Clear Quiz'),
                                ),
                                for (final q in quizzesList)
                                  DropdownMenuItem<String>(
                                    value: q.id,
                                    child: Text(
                                      '${q.title ?? 'Untitled Quiz'} (${q.id})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const DropdownMenuItem<String>(
                                  value: '__custom__',
                                  child: Text('Custom ID (Manual Entry)...'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == '__custom__') {
                                  setState(() {
                                    _showCustomQuizIdInput = true;
                                    _quizRefCtrl.clear();
                                  });
                                } else {
                                  setState(() {
                                    _showCustomQuizIdInput = false;
                                    _quizRefCtrl.text = val ?? '';
                                  });
                                }
                              },
                            ),
                            if (_showCustomQuizIdInput) ...[
                              const SizedBox(height: 12),
                              AdminTextField(
                                label: 'Custom Quiz ID',
                                controller: _quizRefCtrl,
                                hint: 'Paste Appwrite Quiz ID here',
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _CalloutPicker(
                      value: _calloutVariant,
                      onChanged: (v) => setState(() => _calloutVariant = v),
                      isDark: isDark,
                    ),
                    if (widget._tracingAllowed) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Enable tracing practice',
                          style: AdminTokens.bodyStrong(isDark),
                        ),
                        subtitle: Text(
                          'Finger-trace strokes — alphabets & numbers only',
                          style: AdminTokens.label(isDark),
                        ),
                        value: _tracingEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _tracingEnabled = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _ThemeColorPicker(
                      value: _themeColor,
                      onChanged: (c) => setState(() => _themeColor = c),
                      isDark: isDark,
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
            Divider(height: 1, color: AdminTokens.divider(isDark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AdminTokens.borderStrong(isDark),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _save,
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  final bool isDark;
  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  final bool isEditing;
  final String inferredType;
  final VoidCallback onClose;
  final bool isDark;

  const _SheetHeader({
    required this.isEditing,
    required this.inferredType,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_box_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit lesson block' : 'Add lesson block',
                style: AdminTokens.sectionTitle(isDark).copyWith(fontSize: 18),
              ),
              Text(
                'Detected type: $inferredType',
                style: AdminTokens.label(isDark),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
          color: AdminTokens.textTertiary(isDark),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;
  final bool isDark;

  const _SectionLabel(this.text, {this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text, style: AdminTokens.bodyStrong(isDark)),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle!, style: AdminTokens.label(isDark)),
        ),
    ],
  );
}

class _AdvancedToggle extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  final bool isDark;

  const _AdvancedToggle({
    required this.open,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: AdminTokens.textSecondary(isDark),
          ),
          const SizedBox(width: 8),
          Text('Advanced', style: AdminTokens.bodyStrong(isDark)),
        ],
      ),
    ),
  );
}

class _CalloutPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _CalloutPicker({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  static const _options = <String?, String>{
    null: 'None',
    'info': 'Info',
    'tip': 'Tip',
    'warning': 'Warning',
    'success': 'Success',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Callout style', style: AdminTokens.bodyStrong(isDark)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _options.entries
            .map(
              (e) => ChoiceChip(
                label: Text(e.value),
                selected: value == e.key,
                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                onSelected: (_) => onChanged(e.key),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _ThemeColorPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _ThemeColorPicker({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  static const _presets = <String, Color>{
    '#34D399': Color(0xFF34D399),
    '#22D3EE': Color(0xFF22D3EE),
    '#60A5FA': Color(0xFF60A5FA),
    '#F472B6': Color(0xFFF472B6),
    '#FBBF24': Color(0xFFFBBF24),
    '#374151': Color(0xFF374151),
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Theme color', style: AdminTokens.bodyStrong(isDark)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _swatch(null, Colors.transparent, isNone: true),
          for (final e in _presets.entries) _swatch(e.key, e.value),
        ],
      ),
    ],
  );

  Widget _swatch(String? key, Color color, {bool isNone = false}) =>
      GestureDetector(
        onTap: () => onChanged(key),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: value == key ? AppColors.primary : Colors.black12,
              width: value == key ? 2.5 : 1,
            ),
          ),
          child: isNone
              ? const Icon(Icons.block_rounded, size: 16, color: Colors.grey)
              : null,
        ),
      );
}
