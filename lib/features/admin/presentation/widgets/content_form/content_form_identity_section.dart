import 'package:flutter/material.dart';

import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/shared/models/content_item.dart';
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
    return ContentFormCard(
      isDark: isDark,
      title: 'Identity Details',
      child: Column(
        children: [
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title (Latin)*'),
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
              decoration: const InputDecoration(labelText: 'Title (Ol Chiki)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: olChikiController,
              decoration: const InputDecoration(
                labelText: 'Single Character Glyph (e.g. ᱚ)',
              ),
            ),
          ],

          if (_supportsSubtitle) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: subtitleController,
              decoration: const InputDecoration(
                labelText: 'Subtitle / Translation / Summary',
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
                initialValue: categories.any((c) => c.id == selectedCategoryId)
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
                      activeTrackColor: const Color(0xFF10B981),
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
                      activeTrackColor: const Color(0xFFF59E0B),
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
              icon: const Icon(Icons.add_box_rounded, color: Color(0xFF10B981)),
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
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
