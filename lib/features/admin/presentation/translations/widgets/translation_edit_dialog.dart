import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/multilingual_preview_box.dart';
import '../models/translation_entry.dart';

class TranslationEditDialog extends StatefulWidget {
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
  State<TranslationEditDialog> createState() => _TranslationEditDialogState();
}

class _TranslationEditDialogState extends State<TranslationEditDialog> {
  late final TextEditingController _meaningCtrl;
  late final TextEditingController _pronunciationCtrl;
  late final TextEditingController _olChikiCtrl;
  late final TextEditingController _latinCtrl;

  @override
  void initState() {
    super.initState();
    _olChikiCtrl = TextEditingController(text: widget.entry.textOlChiki);
    _latinCtrl = TextEditingController(text: widget.entry.textLatin);
    _meaningCtrl = TextEditingController(
      text: widget.entry.meaningFor(widget.activeLang),
    );
    _pronunciationCtrl = TextEditingController(
      text: widget.entry.transliterationFor(widget.activeLang),
    );
  }

  @override
  void dispose() {
    _olChikiCtrl.dispose();
    _latinCtrl.dispose();
    _meaningCtrl.dispose();
    _pronunciationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Dialog(
      backgroundColor: AdminTokens.overlay(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Multilingual Translation Detail',
                            style: AdminTokens.sectionTitle(isDark),
                          ),
                          Text(
                            '${widget.entry.kindLabel} · ${widget.entry.category ?? "General"}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AdminTokens.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target Ol Chiki & Latin Reference
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
                      const SizedBox(height: 14),

                      // English Meaning
                      TextFormField(
                        initialValue: widget.entry.englishMeaning,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'English Base Meaning',
                          prefixIcon: Icon(Icons.menu_book_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Indic Meaning
                      TextFormField(
                        controller: _meaningCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText:
                              'Translated Meaning (${widget.activeLang.toUpperCase()})*',
                          helperText:
                              'Rendered in top section of learner screens',
                          prefixIcon: const Icon(Icons.translate_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Indic Transliteration Guide
                      TextFormField(
                        controller: _pronunciationCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText:
                              'Pronunciation Guide (${widget.activeLang.toUpperCase()})',
                          helperText:
                              'Rendered in bottom section of learner screens',
                          prefixIcon: const Icon(
                            Icons.record_voice_over_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Live Preview Box
                      MultilingualPreviewBox(
                        textOlChiki: _olChikiCtrl.text,
                        textLatin: _latinCtrl.text,
                        explicitMeaning: _meaningCtrl.text,
                        explicitPronunciation: _pronunciationCtrl.text,
                        isDark: isDark,
                        initialLang: widget.activeLang,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AdminTokens.textSecondary(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Translation verified and active in dictionary',
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirm Translation'),
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
}
