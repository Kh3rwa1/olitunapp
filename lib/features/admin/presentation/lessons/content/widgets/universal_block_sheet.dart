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
part 'universal_block_sheet_advanced.dart';

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

      final parsed = OlChikiMultilingualHelper.parseCompositeLatin(
        b.textLatin ?? '',
      );
      _meaningEnCtrl.text =
          (data['meaning_en'] as String?) ??
          (data['meaning'] as String?) ??
          parsed.meaningEnglish;
      _meaningBnCtrl.text = (data['meaning_bn'] as String?) ?? '';
      _meaningHiCtrl.text = (data['meaning_hi'] as String?) ?? '';
      _meaningOrCtrl.text = (data['meaning_or'] as String?) ?? '';

      _textBengaliCtrl.text =
          b.textBengali ?? (data['textBengali'] as String?) ?? '';
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
                  _BlockTranslationLangTabs(
                    currentLang: _translationLang,
                    isDark: isDark,
                    onSelect: (code) => setState(() => _translationLang = code),
                    hasCustomMap: {
                      'bn':
                          _meaningBnCtrl.text.trim().isNotEmpty ||
                          _textBengaliCtrl.text.trim().isNotEmpty,
                      'hi':
                          _meaningHiCtrl.text.trim().isNotEmpty ||
                          _textHindiCtrl.text.trim().isNotEmpty,
                      'or':
                          _meaningOrCtrl.text.trim().isNotEmpty ||
                          _textOdiaCtrl.text.trim().isNotEmpty,
                      'en': _meaningEnCtrl.text.trim().isNotEmpty,
                    },
                  ),
                  _BlockActiveTranslationInputs(
                    isDark: isDark,
                    currentLang: _translationLang,
                    olChiki: _olChikiCtrl.text,
                    baseEnglish: _meaningEnCtrl.text.trim().isNotEmpty
                        ? _meaningEnCtrl.text.trim()
                        : _latinCtrl.text.trim(),
                    latinText: _latinCtrl.text,
                    meaningBnCtrl: _meaningBnCtrl,
                    textBengaliCtrl: _textBengaliCtrl,
                    meaningHiCtrl: _meaningHiCtrl,
                    textHindiCtrl: _textHindiCtrl,
                    meaningOrCtrl: _meaningOrCtrl,
                    textOdiaCtrl: _textOdiaCtrl,
                    meaningEnCtrl: _meaningEnCtrl,
                    pronCtrl: _pronCtrl,
                    onStateChange: () => setState(() {}),
                  ),

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
                      accent: AppColors.accentCyan,
                      currentUrl: _posterUrl,
                      uploadFolder: 'lesson-media',
                      fileType: FileType.custom,
                      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
                      onUploaded: (url) => setState(() => _posterUrl = url),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Advanced ──────────────────────────────────────────────
                  _BlockAdvancedSection(
                    open: _advancedOpen,
                    onToggleOpen: () =>
                        setState(() => _advancedOpen = !_advancedOpen),
                    isDark: isDark,
                    audioUrl: _audioUrl,
                    onAudioUploaded: (url) => setState(() => _audioUrl = url),
                    pronCtrl: _pronCtrl,
                    quizzesAsync: quizzesAsync,
                    quizRefCtrl: _quizRefCtrl,
                    showCustomQuizIdInput: _showCustomQuizIdInput,
                    onCustomQuizIdToggled: (show) =>
                        setState(() => _showCustomQuizIdInput = show),
                    calloutVariant: _calloutVariant,
                    onCalloutChanged: (v) =>
                        setState(() => _calloutVariant = v),
                    tracingAllowed: widget._tracingAllowed,
                    tracingEnabled: _tracingEnabled,
                    onTracingToggled: (v) =>
                        setState(() => _tracingEnabled = v),
                    themeColor: _themeColor,
                    onThemeColorChanged: (c) => setState(() => _themeColor = c),
                    onStateChange: () => setState(() {}),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
            _SheetFooter(
              isDark: isDark,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}
