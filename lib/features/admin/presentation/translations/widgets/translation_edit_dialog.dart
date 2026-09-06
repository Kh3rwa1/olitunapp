import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/languages/indic_translations_dictionary.dart';
import '../../../../../core/languages/ol_chiki_multilingual_helper.dart';
import '../../../../../core/languages/translation_override_service.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/lessons/domain/entities/lesson_entity.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/multilingual_preview_box.dart';
import '../models/translation_entry.dart';
import '../providers/translation_entries_provider.dart';

part 'translation_edit_dialog_inputs.dart';

class TranslationEditDialog extends ConsumerStatefulWidget {
  final TranslationEntry entry;
  final String activeLang;
  final bool isDark;

  const TranslationEditDialog({
    super.key,
    required this.entry,
    required this.activeLang,
    required this.isDark,
  });

  static void show(
    BuildContext context,
    TranslationEntry entry,
    String activeLang,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (_) => TranslationEditDialog(
        entry: entry,
        activeLang: activeLang,
        isDark: isDark,
      ),
    );
  }

  @override
  ConsumerState<TranslationEditDialog> createState() =>
      _TranslationEditDialogState();
}

class _TranslationEditDialogState extends ConsumerState<TranslationEditDialog> {
  late final TextEditingController _olChikiCtrl;
  late final TextEditingController _latinCtrl;
  late final TextEditingController _meaningEnCtrl;
  late final TextEditingController _meaningBnCtrl;
  late final TextEditingController _meaningHiCtrl;
  late final TextEditingController _meaningOrCtrl;
  late final TextEditingController _textBengaliCtrl;
  late final TextEditingController _textHindiCtrl;
  late final TextEditingController _textOdiaCtrl;

  late String _currentLang;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.activeLang == 'sat' ? 'bn' : widget.activeLang;

    _olChikiCtrl = TextEditingController(text: widget.entry.textOlChiki);
    _latinCtrl = TextEditingController(text: widget.entry.textLatin);

    _meaningBnCtrl = TextEditingController(text: widget.entry.meaningFor('bn'));
    _meaningHiCtrl = TextEditingController(text: widget.entry.meaningFor('hi'));
    _meaningOrCtrl = TextEditingController(text: widget.entry.meaningFor('or'));
    _meaningEnCtrl = TextEditingController(text: widget.entry.meaningFor('en'));

    _textBengaliCtrl = TextEditingController(
      text: widget.entry.transliterationFor('bn'),
    );
    _textHindiCtrl = TextEditingController(
      text: widget.entry.transliterationFor('hi'),
    );
    _textOdiaCtrl = TextEditingController(
      text: widget.entry.transliterationFor('or'),
    );
  }

  @override
  void dispose() {
    _olChikiCtrl.dispose();
    _latinCtrl.dispose();
    _meaningBnCtrl.dispose();
    _meaningHiCtrl.dispose();
    _meaningOrCtrl.dispose();
    _meaningEnCtrl.dispose();
    _textBengaliCtrl.dispose();
    _textHindiCtrl.dispose();
    _textOdiaCtrl.dispose();
    super.dispose();
  }

  void _suggestMeaning(String lang) {
    final query = _meaningEnCtrl.text.trim().isNotEmpty
        ? _meaningEnCtrl.text.trim()
        : _latinCtrl.text.trim();
    _suggestTranslationMeaning(
      context: context,
      query: query,
      lang: lang,
      onMatch: (match) {
        setState(() {
          switch (lang) {
            case 'bn':
              _meaningBnCtrl.text = match;
              break;
            case 'hi':
              _meaningHiCtrl.text = match;
              break;
            case 'or':
              _meaningOrCtrl.text = match;
              break;
            case 'en':
              _meaningEnCtrl.text = match;
              break;
          }
        });
      },
    );
  }

  void _transliterateScript(String lang) {
    _autoTransliterateOlChiki(
      context: context,
      olChiki: _olChikiCtrl.text.trim(),
      lang: lang,
      onTransliterated: (transliterated) {
        setState(() {
          switch (lang) {
            case 'bn':
              _textBengaliCtrl.text = transliterated;
              break;
            case 'hi':
              _textHindiCtrl.text = transliterated;
              break;
            case 'or':
              _textOdiaCtrl.text = transliterated;
              break;
          }
        });
      },
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      await _saveTranslationEntry(
        ref: ref,
        entry: widget.entry,
        bnMeaning: _meaningBnCtrl.text.trim(),
        hiMeaning: _meaningHiCtrl.text.trim(),
        orMeaning: _meaningOrCtrl.text.trim(),
        enMeaning: _meaningEnCtrl.text.trim(),
        bnPron: _textBengaliCtrl.text.trim(),
        hiPron: _textHindiCtrl.text.trim(),
        orPron: _textOdiaCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Translation saved and verified across the app'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save translation: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Dialog(
      backgroundColor: AdminTokens.overlay(isDark),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.translate_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Multilingual Translation Detail',
                                overflow: TextOverflow.ellipsis,
                                style: AdminTokens.sectionTitle(
                                  isDark,
                                ).copyWith(fontSize: isMobile ? 16 : 18),
                              ),
                              Text(
                                '${widget.entry.kindLabel} · ${widget.entry.category ?? "General"}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AdminTokens.textSecondary(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close dialog',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target Ol Chiki & Latin Reference
                      if (isMobile) ...[
                        TextFormField(
                          controller: _olChikiCtrl,
                          readOnly: true,
                          style: const TextStyle(
                            fontFamily: 'OlChiki',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Ol Chiki Script',
                            prefixIcon: Icon(Icons.text_fields_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _latinCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Romanized Santali',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _olChikiCtrl,
                                readOnly: true,
                                style: const TextStyle(
                                  fontFamily: 'OlChiki',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Ol Chiki Script',
                                  prefixIcon: Icon(Icons.text_fields_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _latinCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Romanized Santali',
                                  prefixIcon: Icon(Icons.edit_note_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // English Base Meaning
                      TextFormField(
                        controller: _meaningEnCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'English Meaning',
                          helperText:
                              'Base meaning used for dictionary translation',
                          prefixIcon: const Icon(Icons.menu_book_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.auto_fix_high_rounded,
                              size: 18,
                            ),
                            tooltip: 'Auto-suggest from English dictionary',
                            onPressed: () => _suggestMeaning('en'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Language Tabs
                      _TranslationEditLangTabs(
                        currentLang: _currentLang,
                        isDark: isDark,
                        onSelect: (lang) => setState(() => _currentLang = lang),
                      ),
                      const SizedBox(height: 14),

                      // Active Language Editor
                      _buildActiveInputs(isDark),
                      const SizedBox(height: 20),

                      // Live Preview Box
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
                        },
                        isDark: isDark,
                        initialLang: _currentLang,
                        onLanguageChanged: (lang) {
                          if (mounted && lang != 'sat') {
                            setState(() => _currentLang = lang);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AdminTokens.textSecondary(isDark),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Confirm Translation',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusSm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveInputs(bool isDark) {
    final TextEditingController meaningCtrl;
    final TextEditingController? pronCtrl;
    final String langName;

    switch (_currentLang) {
      case 'bn':
        meaningCtrl = _meaningBnCtrl;
        pronCtrl = _textBengaliCtrl;
        langName = 'Bengali (বাংলা)';
        break;
      case 'hi':
        meaningCtrl = _meaningHiCtrl;
        pronCtrl = _textHindiCtrl;
        langName = 'Hindi (हिन्दी)';
        break;
      case 'or':
        meaningCtrl = _meaningOrCtrl;
        pronCtrl = _textOdiaCtrl;
        langName = 'Odia (ଓଡ଼ିଆ)';
        break;
      case 'en':
      default:
        meaningCtrl = _meaningEnCtrl;
        pronCtrl = null;
        langName = 'English';
        break;
    }

    return _TranslationEditActiveInputs(
      isDark: isDark,
      currentLang: _currentLang,
      meaningCtrl: meaningCtrl,
      pronCtrl: pronCtrl,
      langName: langName,
      onAutoSuggest: () => _suggestMeaning(_currentLang),
      onAutoTransliterate: pronCtrl != null
          ? () => _transliterateScript(_currentLang)
          : null,
      onStateChange: () => setState(() {}),
    );
  }
}
