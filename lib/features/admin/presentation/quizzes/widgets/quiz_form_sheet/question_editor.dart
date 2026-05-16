import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/models/content_models.dart' hide CategoryModel;
import '../../../widgets/admin_form_widgets.dart';
import 'option_editor.dart';

/// Full question editor supporting MCQ and Fill-in-the-blank
class QuestionEditorSheet extends StatefulWidget {
  final QuizQuestion? question;
  final ValueChanged<QuizQuestion> onSave;
  const QuestionEditorSheet({super.key, this.question, required this.onSave});

  @override
  State<QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<QuestionEditorSheet> {
  String _type = 'mcq';

  // MCQ fields
  late final TextEditingController _promptOlChiki;
  late final TextEditingController _promptLatin;
  late final TextEditingController _explanation;
  late final List<TextEditingController> _optOlChikiCtrls;
  late final List<TextEditingController> _optLatinCtrls;
  int _correctIndex = 0;

  // Fill-in-blank fields
  late final TextEditingController _blankOlChiki;
  late final TextEditingController _blankLatin;
  late final TextEditingController _correctAnswer;
  late final List<TextEditingController> _distractorCtrls;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _type = q?.type ?? 'mcq';
    _promptOlChiki = TextEditingController(text: q?.promptOlChiki ?? '');
    _promptLatin = TextEditingController(text: q?.promptLatin ?? '');
    _explanation = TextEditingController(text: q?.explanation ?? '');
    _correctIndex = q?.correctIndex ?? 0;

    _optOlChikiCtrls = List.generate(
      4,
      (i) => TextEditingController(
        text: i < (q?.optionsOlChiki.length ?? 0) ? q!.optionsOlChiki[i] : '',
      ),
    );
    _optLatinCtrls = List.generate(
      4,
      (i) => TextEditingController(
        text: i < (q?.optionsLatin.length ?? 0) ? q!.optionsLatin[i] : '',
      ),
    );

    _blankOlChiki = TextEditingController(text: q?.blankSentenceOlChiki ?? '');
    _blankLatin = TextEditingController(text: q?.blankSentenceLatin ?? '');
    _correctAnswer = TextEditingController(text: q?.correctAnswer ?? '');
    _distractorCtrls = List.generate(
      3,
      (i) => TextEditingController(
        text: i < (q?.distractors.length ?? 0) ? q!.distractors[i] : '',
      ),
    );
  }

  @override
  void dispose() {
    _promptOlChiki.dispose();
    _promptLatin.dispose();
    _explanation.dispose();
    for (final c in _optOlChikiCtrls) {
      c.dispose();
    }
    for (final c in _optLatinCtrls) {
      c.dispose();
    }
    _blankOlChiki.dispose();
    _blankLatin.dispose();
    _correctAnswer.dispose();
    for (final c in _distractorCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    if (_type == 'fill_blank') {
      widget.onSave(
        QuizQuestion(
          type: 'fill_blank',
          promptOlChiki: _promptOlChiki.text.trim(),
          promptLatin: _promptLatin.text.trim().isNotEmpty
              ? _promptLatin.text.trim()
              : null,
          blankSentenceOlChiki: _blankOlChiki.text.trim(),
          blankSentenceLatin: _blankLatin.text.trim(),
          correctAnswer: _correctAnswer.text.trim(),
          distractors: _distractorCtrls
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          explanation: _explanation.text.trim().isNotEmpty
              ? _explanation.text.trim()
              : null,
        ),
      );
    } else {
      widget.onSave(
        QuizQuestion(
          promptOlChiki: _promptOlChiki.text.trim(),
          promptLatin: _promptLatin.text.trim().isNotEmpty
              ? _promptLatin.text.trim()
              : null,
          optionsOlChiki: _optOlChikiCtrls.map((c) => c.text.trim()).toList(),
          optionsLatin: _optLatinCtrls.map((c) => c.text.trim()).toList(),
          correctIndex: _correctIndex,
          explanation: _explanation.text.trim().isNotEmpty
              ? _explanation.text.trim()
              : null,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AdminTokens.radius2xl),
        ),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumCyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  widget.question != null ? 'Edit Question' : 'Add Question',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AdminTokens.divider(isDark)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Type selector
                Text('Question Type', style: AdminTokens.label(isDark)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TypeChip(
                        label: 'Multiple Choice',
                        icon: Icons.radio_button_checked_rounded,
                        selected: _type == 'mcq',
                        onTap: () => setState(() => _type = 'mcq'),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TypeChip(
                        label: 'Fill in Blank',
                        icon: Icons.text_fields_rounded,
                        selected: _type == 'fill_blank',
                        onTap: () => setState(() => _type = 'fill_blank'),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AdminTextField(
                  controller: _promptOlChiki,
                  label: _type == 'fill_blank'
                      ? 'Instruction (Ol Chiki)'
                      : 'Prompt (Ol Chiki)',
                  hint: _type == 'fill_blank'
                      ? 'e.g., Fill the blank:'
                      : 'e.g., ᱚ',
                ),
                const SizedBox(height: 14),
                AdminTextField(
                  controller: _promptLatin,
                  label: _type == 'fill_blank'
                      ? 'Instruction (Latin)'
                      : 'Prompt (Latin)',
                  hint: _type == 'fill_blank'
                      ? 'e.g., Complete the sentence:'
                      : 'Which sound does this letter make?',
                ),
                const SizedBox(height: 20),
                if (_type == 'mcq')
                  McqOptionEditor(
                    isDark: isDark,
                    correctIndex: _correctIndex,
                    onCorrectIndexChanged: (i) =>
                        setState(() => _correctIndex = i),
                    optOlChikiCtrls: _optOlChikiCtrls,
                    optLatinCtrls: _optLatinCtrls,
                  )
                else
                  FillBlankOptionEditor(
                    isDark: isDark,
                    blankOlChiki: _blankOlChiki,
                    blankLatin: _blankLatin,
                    correctAnswer: _correctAnswer,
                    distractorCtrls: _distractorCtrls,
                  ),
                const SizedBox(height: 14),
                AdminTextField(
                  controller: _explanation,
                  label: 'Explanation (optional)',
                  hint: 'Why this is correct',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: AdminTokens.baseTint(isDark),
              border: Border(
                top: BorderSide(color: AdminTokens.divider(isDark)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: AdminSecondaryButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AdminPrimaryButton(
                      label: 'Save Question',
                      icon: Icons.check_rounded,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const TypeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AdminTokens.sunken(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AdminTokens.border(isDark),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.primary
                  : AdminTokens.textTertiary(isDark),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : AdminTokens.textSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
