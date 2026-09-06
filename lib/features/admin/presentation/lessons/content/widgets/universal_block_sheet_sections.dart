part of 'universal_block_sheet.dart';

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
          tooltip: 'Close block editor',
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

class _SheetFooter extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _SheetFooter({
    required this.isDark,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: AdminTokens.divider(isDark)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AdminTokens.borderStrong(isDark)),
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
                  onPressed: onSave,
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
    );
  }
}

class _BlockTranslationLangTabs extends StatelessWidget {
  final String currentLang;
  final bool isDark;
  final ValueChanged<String> onSelect;
  final Map<String, bool> hasCustomMap;

  const _BlockTranslationLangTabs({
    required this.currentLang,
    required this.isDark,
    required this.onSelect,
    required this.hasCustomMap,
  });

  static const _transLangs = [
    {'code': 'bn', 'label': 'বাংলা', 'flag': '🇧🇩', 'name': 'Bengali'},
    {'code': 'hi', 'label': 'हिन्दी', 'flag': '🇮🇳', 'name': 'Hindi'},
    {'code': 'or', 'label': 'ଓଡ଼ିଆ', 'flag': '🇮🇳', 'name': 'Odia'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧', 'name': 'English'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _transLangs.map((lang) {
          final isSelected = lang['code'] == currentLang;
          final hasCustom = hasCustomMap[lang['code']] ?? false;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelect(lang['code']!),
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
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
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
}

class _BlockActiveTranslationInputs extends StatelessWidget {
  final bool isDark;
  final String currentLang;
  final String olChiki;
  final String baseEnglish;
  final String latinText;
  final TextEditingController meaningBnCtrl;
  final TextEditingController textBengaliCtrl;
  final TextEditingController meaningHiCtrl;
  final TextEditingController textHindiCtrl;
  final TextEditingController meaningOrCtrl;
  final TextEditingController textOdiaCtrl;
  final TextEditingController meaningEnCtrl;
  final TextEditingController pronCtrl;
  final VoidCallback onStateChange;

  const _BlockActiveTranslationInputs({
    required this.isDark,
    required this.currentLang,
    required this.olChiki,
    required this.baseEnglish,
    required this.latinText,
    required this.meaningBnCtrl,
    required this.textBengaliCtrl,
    required this.meaningHiCtrl,
    required this.textHindiCtrl,
    required this.meaningOrCtrl,
    required this.textOdiaCtrl,
    required this.meaningEnCtrl,
    required this.pronCtrl,
    required this.onStateChange,
  });

  @override
  Widget build(BuildContext context) {
    final (
      TextEditingController meaningCtrl,
      TextEditingController activePronCtrl,
      String meaningLabel,
      String pronLabel,
      String suggestedMeaning,
      String suggestedPron,
    ) = switch (currentLang) {
      'bn' => (
        meaningBnCtrl,
        textBengaliCtrl,
        'Translated Meaning (বাংলা অর্থ)',
        'Pronunciation Guide / Transliteration (বাংলা উচ্চারণ)',
        OlChikiMultilingualHelper.translateMeaning(baseEnglish, 'bn'),
        OlChikiMultilingualHelper.transliterateOlChiki(olChiki, 'bn'),
      ),
      'hi' => (
        meaningHiCtrl,
        textHindiCtrl,
        'Translated Meaning (हिन्दी अर्थ)',
        'Pronunciation Guide / Transliteration (हिन्दी উচ্চারণ)',
        OlChikiMultilingualHelper.translateMeaning(baseEnglish, 'hi'),
        OlChikiMultilingualHelper.transliterateOlChiki(olChiki, 'hi'),
      ),
      'or' => (
        meaningOrCtrl,
        textOdiaCtrl,
        'Translated Meaning (ଓଡ଼ିଆ ଅର୍ଥ)',
        'Pronunciation Guide / Transliteration (ଓଡ଼ିଆ ଉଚ୍ଚାରଣ)',
        OlChikiMultilingualHelper.translateMeaning(baseEnglish, 'or'),
        OlChikiMultilingualHelper.transliterateOlChiki(olChiki, 'or'),
      ),
      _ => (
        meaningEnCtrl,
        pronCtrl,
        'Translated Meaning (English Meaning)',
        'Pronunciation Guide (Romanized Santali)',
        baseEnglish,
        latinText,
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
                  onChanged: (_) => onStateChange(),
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
                      meaningCtrl.text = suggestedMeaning;
                      onStateChange();
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
                  controller: activePronCtrl,
                  hint: suggestedPron.isNotEmpty
                      ? 'e.g. $suggestedPron'
                      : 'Enter pronunciation guide',
                  onChanged: (_) => onStateChange(),
                ),
              ),
              if (suggestedPron.isNotEmpty &&
                  activePronCtrl.text.trim() != suggestedPron) ...[
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
                      activePronCtrl.text = suggestedPron;
                      onStateChange();
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
