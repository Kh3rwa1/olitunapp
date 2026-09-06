part of 'translation_edit_dialog.dart';

void _suggestTranslationMeaning({
  required BuildContext context,
  required String query,
  required String lang,
  required ValueChanged<String> onMatch,
}) {
  if (query.isEmpty) return;
  final match = IndicTranslationsDictionary.lookup(query, lang);
  if (match != null && match.isNotEmpty) {
    onMatch(match);
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

void _autoTransliterateOlChiki({
  required BuildContext context,
  required String olChiki,
  required String lang,
  required ValueChanged<String> onTransliterated,
}) {
  if (olChiki.isEmpty) return;
  final transliterated = OlChikiMultilingualHelper.transliterateOlChiki(
    olChiki,
    lang,
  );
  if (transliterated.isNotEmpty) {
    onTransliterated(transliterated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-transliterated: $transliterated'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _TranslationEditLangTabs extends StatelessWidget {
  final String currentLang;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _TranslationEditLangTabs({
    required this.currentLang,
    required this.isDark,
    required this.onSelect,
  });

  static const _transLangs = [
    {'code': 'bn', 'label': 'বাংলা', 'flag': '🇧🇩'},
    {'code': 'hi', 'label': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'or', 'label': 'ଓଡ଼ିଆ', 'flag': '🇮🇳'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Row(
        children: _transLangs.map((lang) {
          final isSelected = lang['code'] == currentLang;
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(lang['code']!),
              borderRadius: BorderRadius.circular(AdminTokens.radiusSm - 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm - 2),
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
}

class _TranslationEditActiveInputs extends StatelessWidget {
  final bool isDark;
  final String currentLang;
  final TextEditingController meaningCtrl;
  final TextEditingController? pronCtrl;
  final String langName;
  final VoidCallback onAutoSuggest;
  final VoidCallback? onAutoTransliterate;
  final VoidCallback onStateChange;

  const _TranslationEditActiveInputs({
    required this.isDark,
    required this.currentLang,
    required this.meaningCtrl,
    required this.pronCtrl,
    required this.langName,
    required this.onAutoSuggest,
    required this.onAutoTransliterate,
    required this.onStateChange,
  });

  @override
  Widget build(BuildContext context) {
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
                    onPressed: onAutoSuggest,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                    label: const Text(
                      'Auto-suggest meaning',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  if (onAutoTransliterate != null)
                    TextButton.icon(
                      onPressed: onAutoTransliterate,
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
            onChanged: (_) => onStateChange(),
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
              onChanged: (_) => onStateChange(),
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

Future<void> _saveTranslationEntry({
  required WidgetRef ref,
  required TranslationEntry entry,
  required String bnMeaning,
  required String hiMeaning,
  required String orMeaning,
  required String enMeaning,
  required String bnPron,
  required String hiPron,
  required String orPron,
}) async {
  // 1. Save to TranslationOverrideService for immediate local effect & fast fallback
  final keysToOverride = <String>{
    entry.textOlChiki.trim(),
    entry.textLatin.trim(),
    entry.englishMeaning.trim(),
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
  final blockMatch = RegExp(r'^(.+)_block_(\d+)$').firstMatch(entry.id);

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
  } else if (entry.kind == TranslationKind.lesson) {
    final res = await repo.get(ContentKind.lesson, entry.id);
    await res.fold((_) async {}, (item) async {
      final updatedItem = item.copyWith(
        subtitle: enMeaning.isNotEmpty ? enMeaning : item.subtitle,
        updatedAt: DateTime.now(),
      );
      await repo.upsert(updatedItem);
    });
    ref.invalidate(contentListProvider((ContentKind.lesson, null)));
    ref.invalidate(lessonNotifierProvider);
  } else if (entry.kind == TranslationKind.word) {
    final res = await repo.get(ContentKind.word, entry.id);
    await res.fold((_) async {}, (item) async {
      final updatedItem = item.copyWith(
        subtitle: enMeaning.isNotEmpty ? enMeaning : item.subtitle,
        updatedAt: DateTime.now(),
      );
      await repo.upsert(updatedItem);
    });
    ref.invalidate(contentListProvider((ContentKind.word, null)));
    ref.invalidate(wordsProvider);
  } else if (entry.kind == TranslationKind.sentence) {
    final res = await repo.get(ContentKind.sentence, entry.id);
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
}
