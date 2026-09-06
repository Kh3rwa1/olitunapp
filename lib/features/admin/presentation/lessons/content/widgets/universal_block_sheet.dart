import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/utils/media_type_resolver.dart';
import '../../../../../../shared/providers/providers.dart';
import '../../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../widgets/admin_form_widgets.dart';
import '../../../widgets/multilingual_preview_box.dart';
import '../../../../../../core/languages/ol_chiki_multilingual_helper.dart';
part 'universal_block_sheet_sections.dart';

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
  final _meaningEnCtrl = TextEditingController();
  final _meaningBnCtrl = TextEditingController();
  final _meaningHiCtrl = TextEditingController();
  final _meaningOrCtrl = TextEditingController();
  final _textBengaliCtrl = TextEditingController();
  final _textHindiCtrl = TextEditingController();
  final _textOdiaCtrl = TextEditingController();
  final _pronCtrl = TextEditingController();
  final _quizRefCtrl = TextEditingController();

  String _translationLang = 'bn';
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

      final parsed = OlChikiMultilingualHelper.parseCompositeLatin(b.textLatin ?? '');
      _meaningEnCtrl.text = (data['meaning_en'] as String?) ??
          (data['meaning'] as String?) ??
          parsed.meaningEnglish;
      _meaningBnCtrl.text = (data['meaning_bn'] as String?) ?? '';
      _meaningHiCtrl.text = (data['meaning_hi'] as String?) ?? '';
      _meaningOrCtrl.text = (data['meaning_or'] as String?) ?? '';

      _textBengaliCtrl.text = b.textBengali ?? (data['textBengali'] as String?) ?? '';
      _textHindiCtrl.text = b.textHindi ?? (data['textHindi'] as String?) ?? '';
      _textOdiaCtrl.text = b.textOdia ?? (data['textOdia'] as String?) ?? '';

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
    _meaningEnCtrl.dispose();
    _meaningBnCtrl.dispose();
    _meaningHiCtrl.dispose();
    _meaningOrCtrl.dispose();
    _textBengaliCtrl.dispose();
    _textHindiCtrl.dispose();
    _textOdiaCtrl.dispose();
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
      if (_meaningEnCtrl.text.trim().isNotEmpty) ...{
        'meaning': _meaningEnCtrl.text.trim(),
        'meaning_en': _meaningEnCtrl.text.trim(),
      },
      if (_meaningBnCtrl.text.trim().isNotEmpty)
        'meaning_bn': _meaningBnCtrl.text.trim(),
      if (_meaningHiCtrl.text.trim().isNotEmpty)
        'meaning_hi': _meaningHiCtrl.text.trim(),
      if (_meaningOrCtrl.text.trim().isNotEmpty)
        'meaning_or': _meaningOrCtrl.text.trim(),
      if (_textBengaliCtrl.text.trim().isNotEmpty)
        'textBengali': _textBengaliCtrl.text.trim(),
      if (_textHindiCtrl.text.trim().isNotEmpty)
        'textHindi': _textHindiCtrl.text.trim(),
      if (_textOdiaCtrl.text.trim().isNotEmpty)
        'textOdia': _textOdiaCtrl.text.trim(),
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
      textBengali: _textBengaliCtrl.text.trim().isEmpty
          ? null
          : _textBengaliCtrl.text.trim(),
      textHindi: _textHindiCtrl.text.trim().isEmpty
          ? null
          : _textHindiCtrl.text.trim(),
      textOdia: _textOdiaCtrl.text.trim().isEmpty
          ? null
          : _textOdiaCtrl.text.trim(),
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
                  // ── Headline & Script ────────────────────────────────────
                  _SectionLabel(
                    'Headline & Script',
                    subtitle: 'Ol Chiki target text and Romanized Santali',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: 'Ol Chiki Script',
                    controller: _olChikiCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: 'Latin / Romanized Santali',
                    controller: _latinCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: 'English / Base Meaning',
                    controller: _meaningEnCtrl,
                    hint: 'e.g. What is this?',
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // ── Multilingual Translations ───────────────────────────
                  _SectionLabel(
                    'Language Translations & Pronunciations',
                    subtitle:
                        'Edit translated meaning and pronunciation guide per language',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTranslationLangTabs(isDark),
                  const SizedBox(height: 12),
                  _buildActiveTranslationInputs(isDark),

                  if (_olChikiCtrl.text.isNotEmpty ||
                      _latinCtrl.text.isNotEmpty ||
                      _meaningEnCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    MultilingualPreviewBox(
                      textOlChiki: _olChikiCtrl.text,
                      textLatin: _latinCtrl.text,
                      meaningsByLang: {
                        'bn': _meaningBnCtrl.text,
                        'hi': _meaningHiCtrl.text,
                        'or': _meaningOrCtrl.text,
                        'en': _meaningEnCtrl.text,
                      },
                      transliterationsByLang: {
                        'bn': _textBengaliCtrl.text,
                        'hi': _textHindiCtrl.text,
                        'or': _textOdiaCtrl.text,
                        'en': _pronCtrl.text,
                      },
                      textBengali: _textBengaliCtrl.text,
                      textHindi: _textHindiCtrl.text,
                      textOdia: _textOdiaCtrl.text,
                      explicitMeaning: _meaningEnCtrl.text,
                      explicitPronunciation: _pronCtrl.text,
                      isDark: isDark,
                      initialLang: _translationLang,
                      onLanguageChanged: (lang) {
                        if (_translationLang != lang) {
                          setState(() => _translationLang = lang);
                        }
                      },
                    ),
                  ],

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

  static const _transLangs = [
    {'code': 'bn', 'label': 'বাংলা', 'flag': '🇧🇩', 'name': 'Bengali'},
    {'code': 'hi', 'label': 'हिन्दी', 'flag': '🇮🇳', 'name': 'Hindi'},
    {'code': 'or', 'label': 'ଓଡ଼ିଆ', 'flag': '🇮🇳', 'name': 'Odia'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧', 'name': 'English'},
  ];

  Widget _buildTranslationLangTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _transLangs.map((lang) {
          final isSelected = lang['code'] == _translationLang;
          final hasCustom = switch (lang['code']) {
            'bn' =>
              _meaningBnCtrl.text.trim().isNotEmpty ||
                  _textBengaliCtrl.text.trim().isNotEmpty,
            'hi' =>
              _meaningHiCtrl.text.trim().isNotEmpty ||
                  _textHindiCtrl.text.trim().isNotEmpty,
            'or' =>
              _meaningOrCtrl.text.trim().isNotEmpty ||
                  _textOdiaCtrl.text.trim().isNotEmpty,
            'en' => _meaningEnCtrl.text.trim().isNotEmpty,
            _ => false,
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _translationLang = lang['code']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AdminTokens.raised(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AdminTokens.border(isDark),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      lang['label']!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AdminTokens.textPrimary(isDark),
                      ),
                    ),
                    if (hasCustom) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveTranslationInputs(bool isDark) {
    final baseEnglish = _meaningEnCtrl.text.trim().isNotEmpty
        ? _meaningEnCtrl.text.trim()
        : _latinCtrl.text.trim();

    final (
      TextEditingController meaningCtrl,
      TextEditingController pronCtrl,
      String meaningLabel,
      String pronLabel,
      String suggestedMeaning,
      String suggestedPron,
    ) = switch (_translationLang) {
      'bn' => (
        _meaningBnCtrl,
        _textBengaliCtrl,
        'Translated Meaning (বাংলা অর্থ)',
        'Pronunciation Guide / Transliteration (বাংলা উচ্চারণ)',
        OlChikiMultilingualHelper.translateMeaning(baseEnglish, 'bn'),
        OlChikiMultilingualHelper.transliterateOlChiki(_olChikiCtrl.text, 'bn'),
      ),
      'hi' => (
        _meaningHiCtrl,
        _textHindiCtrl,
        'Translated Meaning (हिन्दी अर्थ)',
        'Pronunciation Guide / Transliteration (हिन्दी उच्चारण)',
        OlChikiMultilingualHelper.translateMeaning(baseEnglish, 'hi'),
        OlChikiMultilingualHelper.transliterateOlChiki(_olChikiCtrl.text, 'hi'),
      ),
      'or' => (
        _meaningOrCtrl,
        _textOdiaCtrl,
        'Translated Meaning (ଓଡ଼ିଆ ଅର୍ଥ)',
        'Pronunciation Guide / Transliteration (ଓଡ଼ିଆ ଉଚ୍ଚାରଣ)',
        OlChikiMultilingualHelper.translateMeaning(baseEnglish, 'or'),
        OlChikiMultilingualHelper.transliterateOlChiki(_olChikiCtrl.text, 'or'),
      ),
      _ => (
        _meaningEnCtrl,
        _pronCtrl,
        'Translated Meaning (English Meaning)',
        'Pronunciation Guide (Romanized Santali)',
        baseEnglish,
        _latinCtrl.text,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AdminTextField(
                  label: meaningLabel,
                  controller: meaningCtrl,
                  hint: suggestedMeaning.isNotEmpty
                      ? 'e.g. $suggestedMeaning'
                      : 'Enter translation',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (suggestedMeaning.isNotEmpty &&
                  meaningCtrl.text.trim() != suggestedMeaning) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: IconButton(
                    tooltip: 'Fill suggested: $suggestedMeaning',
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        meaningCtrl.text = suggestedMeaning;
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AdminTextField(
                  label: pronLabel,
                  controller: pronCtrl,
                  hint: suggestedPron.isNotEmpty
                      ? 'e.g. $suggestedPron'
                      : 'Enter pronunciation guide',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (suggestedPron.isNotEmpty &&
                  pronCtrl.text.trim() != suggestedPron) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: IconButton(
                      tooltip: 'Fill auto-transliteration: $suggestedPron',
                      icon: const Icon(
                        Icons.spellcheck_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          pronCtrl.text = suggestedPron;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
  }
