import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/models/catalog/lesson_entity.dart';
import '../../../widgets/admin_form_widgets.dart';
import '../../../widgets/multilingual_preview_box.dart';
import 'package:itun/features/quiz/data/quizzes_provider.dart';
import 'universal_block_form.dart';
import 'universal_block_sheet_advanced.dart';
import 'universal_block_sheet_sections.dart';

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
  final _form = UniversalBlockForm();

  String _translationLang = 'bn';
  bool _advancedOpen = false;
  bool _showCustomQuizIdInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentValue = _form.quizRefCtrl.text.trim();
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
    if (b != null) _form.load(b);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSubmit(
      _form.toEntity(
        existing: widget.existing,
        tracingAllowed: widget._tracingAllowed,
      ),
    );
    Navigator.of(context).pop();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inferred = _form.resolveType(tracingAllowed: widget._tracingAllowed);
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
            BlockSheetDragHandle(isDark: isDark),
            BlockSheetHeader(
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
                  BlockSheetSectionLabel(
                    'Headline & Script',
                    subtitle: 'Ol Chiki target text and Romanized Santali',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: 'Ol Chiki Script',
                    controller: _form.olChikiCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: 'Latin / Romanized Santali',
                    controller: _form.latinCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: 'English / Base Meaning',
                    controller: _form.meaningEnCtrl,
                    hint: 'e.g. What is this?',
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // ── Multilingual Translations ───────────────────────────
                  BlockSheetSectionLabel(
                    'Language Translations & Pronunciations',
                    subtitle:
                        'Edit translated meaning and pronunciation guide per language',
                    isDark: isDark,
                  ),
                  BlockSheetTranslationLangTabs(
                    currentLang: _translationLang,
                    isDark: isDark,
                    onSelect: (code) => setState(() => _translationLang = code),
                    hasCustomMap: {
                      'bn':
                          _form.meaningBnCtrl.text.trim().isNotEmpty ||
                          _form.textBengaliCtrl.text.trim().isNotEmpty,
                      'hi':
                          _form.meaningHiCtrl.text.trim().isNotEmpty ||
                          _form.textHindiCtrl.text.trim().isNotEmpty,
                      'or':
                          _form.meaningOrCtrl.text.trim().isNotEmpty ||
                          _form.textOdiaCtrl.text.trim().isNotEmpty,
                      'en': _form.meaningEnCtrl.text.trim().isNotEmpty,
                    },
                  ),
                  BlockSheetActiveTranslationInputs(
                    isDark: isDark,
                    currentLang: _translationLang,
                    olChiki: _form.olChikiCtrl.text,
                    baseEnglish: _form.meaningEnCtrl.text.trim().isNotEmpty
                        ? _form.meaningEnCtrl.text.trim()
                        : _form.latinCtrl.text.trim(),
                    latinText: _form.latinCtrl.text,
                    meaningBnCtrl: _form.meaningBnCtrl,
                    textBengaliCtrl: _form.textBengaliCtrl,
                    meaningHiCtrl: _form.meaningHiCtrl,
                    textHindiCtrl: _form.textHindiCtrl,
                    meaningOrCtrl: _form.meaningOrCtrl,
                    textOdiaCtrl: _form.textOdiaCtrl,
                    meaningEnCtrl: _form.meaningEnCtrl,
                    pronCtrl: _form.pronCtrl,
                    onStateChange: () => setState(() {}),
                  ),

                  if (_form.olChikiCtrl.text.isNotEmpty ||
                      _form.latinCtrl.text.isNotEmpty ||
                      _form.meaningEnCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    MultilingualPreviewBox(
                      textOlChiki: _form.olChikiCtrl.text,
                      textLatin: _form.latinCtrl.text,
                      meaningsByLang: {
                        'bn': _form.meaningBnCtrl.text,
                        'hi': _form.meaningHiCtrl.text,
                        'or': _form.meaningOrCtrl.text,
                        'en': _form.meaningEnCtrl.text,
                      },
                      transliterationsByLang: {
                        'bn': _form.textBengaliCtrl.text,
                        'hi': _form.textHindiCtrl.text,
                        'or': _form.textOdiaCtrl.text,
                        'en': _form.pronCtrl.text,
                      },
                      textBengali: _form.textBengaliCtrl.text,
                      textHindi: _form.textHindiCtrl.text,
                      textOdia: _form.textOdiaCtrl.text,
                      explicitMeaning: _form.meaningEnCtrl.text,
                      explicitPronunciation: _form.pronCtrl.text,
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
                  BlockSheetSectionLabel(
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
                    currentUrl: _form.mediaUrl,
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
                    onUploaded: (url) => setState(() => _form.mediaUrl = url),
                  ),

                  if (_form.mediaIsVideo) ...[
                    const SizedBox(height: 16),
                    AdminMediaField(
                      label: 'Poster image (optional)',
                      subtitle: 'Shown before the video plays',
                      icon: Icons.image_rounded,
                      accent: AppColors.accentCyan,
                      currentUrl: _form.posterUrl,
                      uploadFolder: 'lesson-media',
                      fileType: FileType.custom,
                      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
                      onUploaded: (url) =>
                          setState(() => _form.posterUrl = url),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Advanced ──────────────────────────────────────────────
                  BlockSheetAdvancedSection(
                    open: _advancedOpen,
                    onToggleOpen: () =>
                        setState(() => _advancedOpen = !_advancedOpen),
                    isDark: isDark,
                    audioUrl: _form.audioUrl,
                    onAudioUploaded: (url) =>
                        setState(() => _form.audioUrl = url),
                    pronCtrl: _form.pronCtrl,
                    quizzesAsync: quizzesAsync,
                    quizRefCtrl: _form.quizRefCtrl,
                    showCustomQuizIdInput: _showCustomQuizIdInput,
                    onCustomQuizIdToggled: (show) =>
                        setState(() => _showCustomQuizIdInput = show),
                    calloutVariant: _form.calloutVariant,
                    onCalloutChanged: (v) =>
                        setState(() => _form.calloutVariant = v),
                    tracingAllowed: widget._tracingAllowed,
                    tracingEnabled: _form.tracingEnabled,
                    onTracingToggled: (v) =>
                        setState(() => _form.tracingEnabled = v),
                    themeColor: _form.themeColor,
                    onThemeColorChanged: (c) =>
                        setState(() => _form.themeColor = c),
                    onStateChange: () => setState(() {}),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
            BlockSheetFooter(
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
