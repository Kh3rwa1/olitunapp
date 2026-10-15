import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class TranslationEditLangTabs extends StatelessWidget {
  final String currentLang;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const TranslationEditLangTabs({
    super.key,
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

class TranslationEditActiveInputs extends StatelessWidget {
  final bool isDark;
  final String currentLang;
  final TextEditingController meaningCtrl;
  final TextEditingController? pronCtrl;
  final String langName;
  final VoidCallback onAutoSuggest;
  final VoidCallback? onAutoTransliterate;
  final VoidCallback onStateChange;

  const TranslationEditActiveInputs({
    super.key,
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
