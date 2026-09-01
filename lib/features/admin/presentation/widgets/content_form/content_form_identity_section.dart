import 'package:flutter/material.dart';
import 'package:itun/core/languages/ol_chiki_multilingual_helper.dart';
import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/shared/models/content_item.dart';
import '../multilingual_preview_box.dart';
import 'content_form_card.dart';

class ContentFormIdentitySection extends StatelessWidget {
  final bool isDark;
  final ContentKind kind;
  final TextEditingController titleController;
  final TextEditingController titleOlChikiController;
  final TextEditingController subtitleController;
  final TextEditingController olChikiController;
  final TextEditingController orderController;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final bool isPublished;
  final ValueChanged<bool> onPublishedChanged;
  final bool isPremium;
  final ValueChanged<bool> onPremiumChanged;
  final List<String> tags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final List<CategoryEntity> categories;

  const ContentFormIdentitySection({
    super.key,
    required this.isDark,
    required this.kind,
    required this.titleController,
    required this.titleOlChikiController,
    required this.subtitleController,
    required this.olChikiController,
    required this.orderController,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.isPublished,
    required this.onPublishedChanged,
    required this.isPremium,
    required this.onPremiumChanged,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.categories,
  });

  bool get _requiresCategory =>
      kind != ContentKind.letter && kind != ContentKind.number;
  bool get _supportsPublished => kind != ContentKind.rhyme;
  bool get _supportsPremium =>
      kind == ContentKind.lesson || kind == ContentKind.rhyme;
  bool get _supportsSubtitle => kind != ContentKind.number;
  bool get _supportsOrder => kind != ContentKind.rhyme;
  bool get _supportsTags => kind == ContentKind.rhyme;

  @override
  Widget build(BuildContext context) {
    final olChikiValue = olChikiController.text.isNotEmpty
        ? olChikiController.text
        : titleOlChikiController.text;
    final latinValue = titleController.text;
    final meaningValue = subtitleController.text;

    final bengaliMeaning = OlChikiMultilingualHelper.translateMeaning(
      meaningValue.isNotEmpty ? meaningValue : latinValue,
      'bn',
    );
    final bengaliPron = OlChikiMultilingualHelper.transliterateOlChiki(
      olChikiValue,
      'bn',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContentFormCard(
          isDark: isDark,
          title: 'Identity Details',
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title / Romanized Santali (Latin)*',
                  hintText: 'e.g. Baba, Johar, In do kamiyedanj',
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Latin title is required'
                    : null,
              ),
              const SizedBox(height: 12),

              if (kind == ContentKind.lesson) ...[
                ExpansionTile(
                  title: const Text(
                    'Advanced Titles (Ol Chiki, Glyphs)',
                    style: TextStyle(fontSize: 14),
                  ),
                  children: [
                    TextFormField(
                      controller: titleOlChikiController,
                      decoration: const InputDecoration(
                        labelText: 'Title (Ol Chiki)',
                        hintText: 'e.g. ᱵᱟᱵᱟ, ᱡᱚᱦᱟᱨ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: olChikiController,
                      decoration: const InputDecoration(
                        labelText: 'Single Character Glyph (e.g. ᱚ)',
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: titleOlChikiController,
                  decoration: const InputDecoration(
                    labelText: 'Title (Ol Chiki)',
                    hintText: 'e.g. ᱵᱟᱵᱟ, ᱡᱚᱦᱟᱨ',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: olChikiController,
                  decoration: const InputDecoration(
                    labelText: 'Ol Chiki Text / Glyph (e.g. ᱵᱟᱵᱟ, ᱚ)',
                  ),
                ),
              ],

              if (_supportsSubtitle) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'English Meaning / Base Summary',
                    hintText: 'e.g. Father, Hello, I am working',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],

              if (_requiresCategory) ...[
                if (categories.isEmpty && selectedCategoryId != null)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Category*',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      'Category set: $selectedCategoryId',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue:
                        categories.any((c) => c.id == selectedCategoryId)
                            ? selectedCategoryId
                            : null,
                    items: categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.titleLatin),
                      );
                    }).toList(),
                    onChanged: onCategoryChanged,
                    decoration: const InputDecoration(labelText: 'Category*'),
                    validator: (val) {
                      final effective = val ?? selectedCategoryId;
                      if (effective == null || effective.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
              ],

              if (_supportsPublished || _supportsPremium)
                Row(
                  children: [
                    if (_supportsPublished)
                      Expanded(
                        child: SwitchListTile(
                          title: const Text(
                            'Published',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: isPublished,
                          activeTrackColor: AppColors.primary,
                          onChanged: onPublishedChanged,
                        ),
                      ),
                    if (_supportsPremium)
                      Expanded(
                        child: SwitchListTile(
                          title: const Text(
                            'Premium',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: isPremium,
                          activeTrackColor: AppColors.accentGold,
                          onChanged: onPremiumChanged,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),

              if (_supportsOrder) ...[
                TextFormField(
                  controller: orderController,
                  decoration: const InputDecoration(labelText: 'Sort Order Index'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],

              if (_supportsTags) _buildTagsField(isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dedicated Multilingual & Bengali Section
        ContentFormCard(
          isDark: isDark,
          title: '🇧🇩 বাংলা ও বহুভাষিক অনুবাদ (Multilingual Translations)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'বাংলা, হিন্দি, ওড়িয়া ও ইংরেজি অর্থ স্বয়ংক্রিয়ভাবে অভিধানের সাথে সিঙ্ক হয়।',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AdminTokens.textPrimary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bengali Quick Info Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminTokens.sunken(isDark),
                        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                        border: Border.all(color: AdminTokens.border(isDark)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'বাংলা অর্থ (Meaning)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bengaliMeaning.isNotEmpty ? bengaliMeaning : '—',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AdminTokens.textPrimary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminTokens.sunken(isDark),
                        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                        border: Border.all(color: AdminTokens.border(isDark)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'বাংলা উচ্চারণ (Pronunciation)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bengaliPron.isNotEmpty ? bengaliPron : '—',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AdminTokens.textPrimary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live 3-Section Preview
              MultilingualPreviewBox(
                textOlChiki: olChikiValue,
                textLatin: latinValue,
                explicitMeaning: meaningValue,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField(bool isDark) {
    final tagInputController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: tagInputController,
                decoration: const InputDecoration(
                  labelText: 'Add Tag',
                  hintText: 'e.g. Traditional, Alphabet',
                ),
                onFieldSubmitted: (val) {
                  onAddTag(val);
                  tagInputController.clear();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_box_rounded, color: AppColors.primary),
              onPressed: () {
                onAddTag(tagInputController.text);
                tagInputController.clear();
              },
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                onDeleted: () => onRemoveTag(tag),
                backgroundColor: AdminTokens.sunken(isDark),
                side: BorderSide(color: AdminTokens.border(isDark)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
