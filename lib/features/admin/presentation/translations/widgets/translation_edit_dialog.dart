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

  static const _transLangs = [
    {'code': 'bn', 'label': 'Bengali (বাংলা)', 'flag': '🇧🇩'},
    {'code': 'hi', 'label': 'Hindi (हिन्दी)', 'flag': '🇮🇳'},
    {'code': 'or', 'label': 'Odia (ଓଡ଼ିଆ)', 'flag': '🇮🇳'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _currentLang = widget.activeLang == 'sat' ? 'bn' : widget.activeLang;

    _olChikiCtrl = TextEditingController(text: widget.entry.textOlChiki);
    _latinCtrl = TextEditingController(text: widget.entry.textLatin);

    _meaningBnCtrl = TextEditingController(
      text: widget.entry.meaningFor('bn'),
    );
    _meaningHiCtrl = TextEditingController(
      text: widget.entry.meaningFor('hi'),
    );
    _meaningOrCtrl = TextEditingController(
      text: widget.entry.meaningFor('or'),
    );
    _meaningEnCtrl = TextEditingController(
      text: widget.entry.meaningFor('en'),
    );

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

  void _autoSuggestMeaning(String lang) {
    final query = _meaningEnCtrl.text.trim().isNotEmpty
        ? _meaningEnCtrl.text.trim()
        : _latinCtrl.text.trim();
    if (query.isEmpty) return;

    final match = IndicTranslationsDictionary.lookup(query, lang);
    if (match != null && match.isNotEmpty) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-suggested meaning: $match'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No dictionary entry found for "$query" in $lang'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _autoTransliterate(String lang) {
    final olChiki = _olChikiCtrl.text.trim();
    if (olChiki.isEmpty) return;

    final transliterated = OlChikiMultilingualHelper.transliterateOlChiki(
      olChiki,
      lang,
    );
    if (transliterated.isNotEmpty) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-transliterated: $transliterated'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final bnMeaning = _meaningBnCtrl.text.trim();
      final hiMeaning = _meaningHiCtrl.text.trim();
      final orMeaning = _meaningOrCtrl.text.trim();
      final enMeaning = _meaningEnCtrl.text.trim();

      final bnPron = _textBengaliCtrl.text.trim();
      final hiPron = _textHindiCtrl.text.trim();
      final orPron = _textOdiaCtrl.text.trim();

      // 1. Save to TranslationOverrideService for immediate local effect & fast fallback
      final keysToOverride = <String>{
        widget.entry.textOlChiki.trim(),
        widget.entry.textLatin.trim(),
        widget.entry.englishMeaning.trim(),
      }..removeWhere((k) => k.isEmpty);

      for (final key in keysToOverride) {
        if (bnMeaning.isNotEmpty || bnPron.isNotEmpty) {
          await TranslationOverrideService.instance.setOverride(
            key: key,
            langCode: 'bn',
            meaning: bnMeaning.isNotEmpty ? bnMeaning : null,
            pronunciation: bnPron.isNotEmpty ? bnPron : null,
          );
        }
        if (hiMeaning.isNotEmpty || hiPron.isNotEmpty) {
          await TranslationOverrideService.instance.setOverride(
            key: key,
            langCode: 'hi',
            meaning: hiMeaning.isNotEmpty ? hiMeaning : null,
            pronunciation: hiPron.isNotEmpty ? hiPron : null,
          );
        }
        if (orMeaning.isNotEmpty || orPron.isNotEmpty) {
          await TranslationOverrideService.instance.setOverride(
            key: key,
            langCode: 'or',
            meaning: orMeaning.isNotEmpty ? orMeaning : null,
            pronunciation: orPron.isNotEmpty ? orPron : null,
          );
        }
        if (enMeaning.isNotEmpty) {
          await TranslationOverrideService.instance.setOverride(
            key: key,
            langCode: 'en',
            meaning: enMeaning,
          );
        }
      }

      // 2. Dual persistence to ContentRepository if it corresponds to an entity
      final repo = ref.read(contentRepositoryProvider);
      final blockMatch = RegExp(r'^(.+)_block_(\d+)$').firstMatch(widget.entry.id);

      if (blockMatch != null) {
        final lessonId = blockMatch.group(1)!;
        final blockIdx = int.tryParse(blockMatch.group(2)!) ?? 0;
        final res = await repo.get(ContentKind.lesson, lessonId);
        await res.fold((_) async {}, (item) async {
          final lesson = item.toLessonEntity();
          if (blockIdx < lesson.blocks.length) {
            final blocks = List<LessonBlockEntity>.from(lesson.blocks);
            final currentBlock = blocks[blockIdx];
            final blockData = Map<String, dynamic>.from(currentBlock.data ?? {});
            blockData['meaning_bn'] = bnMeaning;
            blockData['meaning_hi'] = hiMeaning;
            blockData['meaning_or'] = orMeaning;
            blockData['meaning_en'] = enMeaning;
            if (enMeaning.isNotEmpty) {
              blockData['meaning'] = enMeaning;
            }

            blocks[blockIdx] = LessonBlockEntity(
              type: currentBlock.type,
              textOlChiki: currentBlock.textOlChiki,
              textLatin: currentBlock.textLatin,
              textBengali: bnPron.isNotEmpty ? bnPron : null,
              textHindi: hiPron.isNotEmpty ? hiPron : null,
              textOdia: orPron.isNotEmpty ? orPron : null,
              imageUrl: currentBlock.imageUrl,
              audioUrl: currentBlock.audioUrl,
              data: blockData,
            );

            final contentBlocks = blocks
                .asMap()
                .entries
                .map((e) => e.value.toContentBlock(e.key))
                .toList();

            final updatedItem = item.copyWith(
              blocks: contentBlocks,
              updatedAt: DateTime.now(),
            );
            await repo.upsert(updatedItem);
          }
        });
        ref.invalidate(contentListProvider((ContentKind.lesson, null)));
        ref.invalidate(lessonNotifierProvider);
      } else if (widget.entry.kind == TranslationKind.lesson) {
        final res = await repo.get(ContentKind.lesson, widget.entry.id);
        await res.fold((_) async {}, (item) async {
          final updatedItem = item.copyWith(
            subtitle: enMeaning.isNotEmpty ? enMeaning : item.subtitle,
            updatedAt: DateTime.now(),
          );
          await repo.upsert(updatedItem);
        });
        ref.invalidate(contentListProvider((ContentKind.lesson, null)));
        ref.invalidate(lessonNotifierProvider);
      } else if (widget.entry.kind == TranslationKind.word) {
        final res = await repo.get(ContentKind.word, widget.entry.id);
        await res.fold((_) async {}, (item) async {
          final updatedItem = item.copyWith(
            subtitle: enMeaning.isNotEmpty ? enMeaning : item.subtitle,
            updatedAt: DateTime.now(),
          );
          await repo.upsert(updatedItem);
        });
        ref.invalidate(contentListProvider((ContentKind.word, null)));
        ref.invalidate(wordsProvider);
      } else if (widget.entry.kind == TranslationKind.sentence) {
        final res = await repo.get(ContentKind.sentence, widget.entry.id);
        await res.fold((_) async {}, (item) async {
          final updatedItem = item.copyWith(
            subtitle: enMeaning.isNotEmpty ? enMeaning : item.subtitle,
            updatedAt: DateTime.now(),
          );
          await repo.upsert(updatedItem);
        });
        ref.invalidate(contentListProvider((ContentKind.sentence, null)));
        ref.invalidate(sentencesProvider);
      }

      ref.invalidate(translationEntriesProvider);

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
                          helperText: 'Base meaning used for dictionary translation',
                          prefixIcon: const Icon(Icons.menu_book_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                            tooltip: 'Auto-suggest from English dictionary',
                            onPressed: () => _autoSuggestMeaning('en'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Language Tabs
                      _buildTranslationLangTabs(isDark),
                      const SizedBox(height: 14),

                      // Active Language Editor
                      _buildActiveTranslationInputs(isDark),
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
                    label: Text(_isSaving ? 'Saving...' : 'Confirm Translation'),
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

  Widget _buildTranslationLangTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Row(
        children: _transLangs.map((lang) {
          final isSelected = lang['code'] == _currentLang;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentLang = lang['code']!),
              borderRadius: BorderRadius.circular(AdminTokens.radiusSm - 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AdminTokens.radiusSm - 2),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      lang['label']!.split(' ').first,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AdminTokens.textSecondary(isDark),
                      ),
                    ),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                '$langName Fields',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AdminTokens.textPrimary(isDark),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  TextButton.icon(
                    onPressed: () => _autoSuggestMeaning(_currentLang),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                    label: const Text(
                      'Auto-suggest meaning',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  if (pronCtrl != null)
                    TextButton.icon(
                      onPressed: () => _autoTransliterate(_currentLang),
                      icon: const Icon(Icons.transform_rounded, size: 14),
                      label: const Text(
                        'Auto-transliterate',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: meaningCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Meaning ($langName)*',
              helperText: 'Displayed as translation meaning for learners',
              prefixIcon: const Icon(Icons.translate_rounded),
            ),
          ),
          if (pronCtrl != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: pronCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Pronunciation Guide ($langName script)',
                helperText: 'Brahmic transliteration guide for pronunciation',
                prefixIcon: const Icon(Icons.record_voice_over_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
