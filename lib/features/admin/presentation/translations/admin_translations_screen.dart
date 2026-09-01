import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_page_header.dart';
import 'models/translation_entry.dart';
import 'providers/translation_entries_provider.dart';
import 'widgets/translation_edit_dialog.dart';
import 'widgets/translation_stats_card.dart';

class AdminTranslationsScreen extends ConsumerStatefulWidget {
  const AdminTranslationsScreen({super.key});

  @override
  ConsumerState<AdminTranslationsScreen> createState() =>
      _AdminTranslationsScreenState();
}

class _AdminTranslationsScreenState
    extends ConsumerState<AdminTranslationsScreen> {
  String _selectedLang = 'bn';
  TranslationKind? _selectedKind;

  static const _languages = [
    {'code': 'bn', 'label': 'বাংলা (Bengali)', 'flag': '🇧🇩'},
    {'code': 'hi', 'label': 'हिन्दी (Hindi)', 'flag': '🇮🇳'},
    {'code': 'or', 'label': 'ଓଡ଼ିଆ (Odia)', 'flag': '🇮🇳'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
    {'code': 'sat', 'label': 'ᱥᱟᱱᱛᱟᱲᱤ (Santali)', 'flag': '🔤'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;
    final allEntries = ref.watch(translationEntriesProvider);

    final currentLangInfo = _languages.firstWhere(
      (l) => l['code'] == _selectedLang,
      orElse: () => _languages.first,
    );

    final filteredByKind = _selectedKind == null
        ? allEntries
        : allEntries.where((e) => e.kind == _selectedKind).toList();

    final translatedCount = filteredByKind
        .where((e) => e.isTranslatedFor(_selectedLang))
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 32 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminPageHeader(
                title: 'Languages & Translations',
                subtitle:
                    'Manage Bengali, Hindi, Odia, English and Santali dictionary meanings, pronunciations, and transliterations',
                eyebrow: 'CONTENT · MULTILINGUAL CMS',
              ),
              const SizedBox(height: 20),

              // Language Selector Tabs
              _buildLanguageSelector(isDark),
              const SizedBox(height: 16),

              // Coverage Stats Card
              TranslationStatsCard(
                selectedLang: _selectedLang,
                langName: currentLangInfo['label']!,
                langFlag: currentLangInfo['flag']!,
                totalCount: filteredByKind.length,
                translatedCount: translatedCount,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Content Kind Filter Chips
              _buildKindFilters(isDark),
              const SizedBox(height: 20),

              // Interactive Data Table
              AdminDataTable<TranslationEntry>(
                items: filteredByKind,
                searchHint: 'Search Ol Chiki, Latin, English, or translated meaning…',
                searchPredicate: (entry, query) {
                  final q = query.toLowerCase();
                  return entry.textOlChiki.toLowerCase().contains(q) ||
                      entry.textLatin.toLowerCase().contains(q) ||
                      entry.englishMeaning.toLowerCase().contains(q) ||
                      entry.meaningFor(_selectedLang).toLowerCase().contains(q) ||
                      entry.transliterationFor(_selectedLang).toLowerCase().contains(q);
                },
                columns: [
                  AdminColumn<TranslationEntry>(
                    label: 'Type',
                    cellBuilder: (entry) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _kindColor(entry.kind).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.kindLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kindColor(entry.kind),
                        ),
                      ),
                    ),
                  ),
                  AdminColumn<TranslationEntry>(
                    label: 'Ol Chiki Script',
                    flex: 2,
                    cellBuilder: (entry) => Text(
                      entry.textOlChiki.isNotEmpty ? entry.textOlChiki : '—',
                      style: const TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  AdminColumn<TranslationEntry>(
                    label: 'Romanized',
                    flex: 2,
                    cellBuilder: (entry) => Text(
                      entry.textLatin.isNotEmpty ? entry.textLatin : '—',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AdminTokens.textPrimary(isDark),
                      ),
                    ),
                  ),
                  AdminColumn<TranslationEntry>(
                    label: 'English Base',
                    flex: 2,
                    cellBuilder: (entry) => Text(
                      entry.englishMeaning.isNotEmpty ? entry.englishMeaning : '—',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AdminTokens.textSecondary(isDark),
                      ),
                    ),
                  ),
                  AdminColumn<TranslationEntry>(
                    label: '${currentLangInfo["label"]!.split(" ").first} Meaning',
                    flex: 3,
                    cellBuilder: (entry) {
                      final m = entry.meaningFor(_selectedLang);
                      return Row(
                        children: [
                          Icon(
                            m.isNotEmpty
                                ? Icons.check_circle_rounded
                                : Icons.help_outline_rounded,
                            size: 14,
                            color: m.isNotEmpty ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              m.isNotEmpty ? m : '—',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: m.isNotEmpty
                                    ? AdminTokens.textPrimary(isDark)
                                    : Colors.orange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  AdminColumn<TranslationEntry>(
                    label: '${currentLangInfo["label"]!.split(" ").first} Pronunciation',
                    flex: 2,
                    cellBuilder: (entry) => Text(
                      entry.transliterationFor(_selectedLang),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AdminTokens.textSecondary(isDark),
                      ),
                    ),
                  ),
                ],
                trailingBuilder: (entry) => IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  color: AppColors.primary,
                  tooltip: 'View & Edit Translation',
                  onPressed: () => TranslationEditDialog.show(
                    context,
                    entry,
                    _selectedLang,
                    isDark,
                  ),
                ),
                onRowTap: (entry) => TranslationEditDialog.show(
                  context,
                  entry,
                  _selectedLang,
                  isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _languages.map((lang) {
            final isSelected = lang['code'] == _selectedLang;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                showCheckmark: false,
                avatar: Text(lang['flag']!, style: const TextStyle(fontSize: 13)),
                label: Text(
                  lang['label']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AdminTokens.textPrimary(isDark),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedLang = lang['code']!),
                selectedColor: AppColors.primary,
                backgroundColor: Colors.transparent,
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKindFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _kindFilterChip(isDark, null, 'All Content'),
          const SizedBox(width: 8),
          _kindFilterChip(isDark, TranslationKind.word, 'Words'),
          const SizedBox(width: 8),
          _kindFilterChip(isDark, TranslationKind.sentence, 'Sentences'),
          const SizedBox(width: 8),
          _kindFilterChip(isDark, TranslationKind.lesson, 'Lessons & Blocks'),
          const SizedBox(width: 8),
          _kindFilterChip(isDark, TranslationKind.category, 'Categories'),
          const SizedBox(width: 8),
          _kindFilterChip(isDark, TranslationKind.rhyme, 'Rhymes & Stories'),
        ],
      ),
    );
  }

  Widget _kindFilterChip(bool isDark, TranslationKind? kind, String label) {
    final isSelected = _selectedKind == kind;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AdminTokens.textPrimary(isDark),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedKind = kind),
      selectedColor: AppColors.primary,
      backgroundColor: AdminTokens.sunken(isDark),
      side: BorderSide(color: AdminTokens.border(isDark)),
    );
  }

  Color _kindColor(TranslationKind kind) => switch (kind) {
    TranslationKind.word => Colors.amber.shade700,
    TranslationKind.sentence => Colors.blue.shade600,
    TranslationKind.lesson => Colors.green.shade600,
    TranslationKind.category => Colors.purple.shade600,
    TranslationKind.rhyme => Colors.pink.shade600,
  };
}
