import 'package:flutter/material.dart';
import '../../../../core/languages/ol_chiki_multilingual_helper.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive live 3-section preview component that renders how content
/// appears to learners in Bengali, Hindi, Odia, English, and Santali.
class MultilingualPreviewBox extends StatefulWidget {
  final String textOlChiki;
  final String textLatin;
  final String explicitMeaning;
  final String explicitPronunciation;
  final Map<String, String>? meaningsByLang;
  final Map<String, String>? transliterationsByLang;
  final String? textBengali;
  final String? textHindi;
  final String? textOdia;
  final bool isDark;
  final String initialLang;
  final ValueChanged<String>? onLanguageChanged;

  const MultilingualPreviewBox({
    super.key,
    required this.textOlChiki,
    required this.textLatin,
    this.explicitMeaning = '',
    this.explicitPronunciation = '',
    this.meaningsByLang,
    this.transliterationsByLang,
    this.textBengali,
    this.textHindi,
    this.textOdia,
    required this.isDark,
    this.initialLang = 'bn',
    this.onLanguageChanged,
  });

  @override
  State<MultilingualPreviewBox> createState() => _MultilingualPreviewBoxState();
}

class _MultilingualPreviewBoxState extends State<MultilingualPreviewBox> {
  late String _selectedLang;

  static const _languages = [
    {'code': 'bn', 'label': 'বাংলা', 'flag': '🇧🇩'},
    {'code': 'hi', 'label': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'or', 'label': 'ଓଡ଼ିଆ', 'flag': '🇮🇳'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
    {'code': 'sat', 'label': 'ᱥᱟᱱᱛᱟᱲᱤ', 'flag': '🔤'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.initialLang;
  }

  @override
  void didUpdateWidget(covariant MultilingualPreviewBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLang != oldWidget.initialLang &&
        widget.initialLang != _selectedLang) {
      setState(() {
        _selectedLang = widget.initialLang;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final customMeaning = widget.meaningsByLang?[_selectedLang];
    final activeMeaning =
        (customMeaning != null && customMeaning.trim().isNotEmpty)
            ? customMeaning.trim()
            : (widget.explicitMeaning.isNotEmpty ? widget.explicitMeaning : '');

    final customTransliteration = widget.transliterationsByLang?[_selectedLang];
    final activePron =
        (customTransliteration != null && customTransliteration.trim().isNotEmpty)
            ? customTransliteration.trim()
            : widget.explicitPronunciation;

    final resolvedTextBengali =
        widget.transliterationsByLang?['bn'] ?? widget.textBengali;
    final resolvedTextHindi =
        widget.transliterationsByLang?['hi'] ?? widget.textHindi;
    final resolvedTextOdia =
        widget.transliterationsByLang?['or'] ?? widget.textOdia;

    final resolved = OlChikiMultilingualHelper.resolveBlockDisplay(
      textOlChiki: widget.textOlChiki.isNotEmpty ? widget.textOlChiki : 'ᱚ',
      textLatin: widget.textLatin.isNotEmpty ? widget.textLatin : 'ol',
      textBengali: resolvedTextBengali,
      textHindi: resolvedTextHindi,
      textOdia: resolvedTextOdia,
      explicitMeaning: activeMeaning,
      explicitPronunciation: activePron,
      teachingLanguage: _selectedLang,
      scriptMode: 'both',
    );

    return Container(
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Learner Preview',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminTokens.textPrimary(isDark),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _languages.firstWhere(
                    (l) => l['code'] == _selectedLang,
                    orElse: () => _languages.first,
                  )['label']!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Language Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _languages.map((lang) {
                final isSelected = lang['code'] == _selectedLang;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() => _selectedLang = lang['code']!);
                      widget.onLanguageChanged?.call(lang['code']!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AdminTokens.raised(isDark),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AdminTokens.border(isDark),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 4),
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
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 3-Section Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AdminTokens.raised(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(color: AdminTokens.border(isDark)),
              boxShadow: AdminTokens.raisedShadow(isDark),
            ),
            child: Column(
              children: [
                // Top Section: Translated Meaning
                Text(
                  resolved.title.isNotEmpty ? resolved.title : '—',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AdminTokens.textPrimary(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Middle Section: Pure Ol Chiki Script
                Text(
                  resolved.scriptText.isNotEmpty ? resolved.scriptText : '—',
                  style: const TextStyle(
                    fontFamily: 'OlChiki',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Bottom Section: Centered Transliteration Guide
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resolved.subtitle.isNotEmpty ? resolved.subtitle : '—',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminTokens.textSecondary(isDark),
                    ),
                    textAlign: TextAlign.center,
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
