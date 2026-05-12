import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart' hide CategoryModel;
import '../../../../categories/domain/entities/category_entity.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_form_widgets.dart';

class QuizFormSheet extends ConsumerStatefulWidget {
  final QuizModel? quiz;
  const QuizFormSheet({super.key, this.quiz});

  static void show(BuildContext context, WidgetRef ref, QuizModel? quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuizFormSheet(quiz: quiz),
    );
  }

  @override
  ConsumerState<QuizFormSheet> createState() => _QuizFormSheetState();
}

class _QuizFormSheetState extends ConsumerState<QuizFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _passingScoreCtrl;
  String? _selectedCategoryId;
  String _level = 'beginner';
  bool _isActive = true;
  late List<QuizQuestion> _questions;

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    final categories =
        ref.read(categoryNotifierProvider).value ?? const <CategoryEntity>[];
    _selectedCategoryId =
        quiz?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    _titleCtrl = TextEditingController(text: quiz?.title ?? '');
    _orderCtrl = TextEditingController(text: (quiz?.order ?? 0).toString());
    _passingScoreCtrl = TextEditingController(
      text: (quiz?.passingScore ?? 70).toString(),
    );
    _level = quiz?.level ?? 'beginner';
    _isActive = quiz?.isActive ?? true;
    _questions = List<QuizQuestion>.from(quiz?.questions ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orderCtrl.dispose();
    _passingScoreCtrl.dispose();
    super.dispose();
  }

  void _addQuestion() {
    _showQuestionEditor(null, null);
  }

  void _editQuestion(int index) {
    _showQuestionEditor(_questions[index], index);
  }

  void _deleteQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  void _showQuestionEditor(QuizQuestion? existing, int? index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionEditorSheet(
        question: existing,
        onSave: (q) {
          setState(() {
            if (index != null) {
              _questions[index] = q;
            } else {
              _questions.add(q);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories =
        ref.read(categoryNotifierProvider).value ?? const <CategoryEntity>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit Quiz' : 'Create Quiz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              children: [
                AdminTextField(
                  controller: _titleCtrl,
                  label: 'Title',
                  hint: 'Enter quiz title',
                ),
                const SizedBox(height: 14),
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.titleLatin),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AdminTextField(
                        controller: _orderCtrl,
                        label: 'Order',
                        hint: '0',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminTextField(
                        controller: _passingScoreCtrl,
                        label: 'Passing Score',
                        hint: '70',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Level',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _level,
                  items: const [
                    DropdownMenuItem(
                      value: 'beginner',
                      child: Text('Beginner'),
                    ),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('Intermediate'),
                    ),
                    DropdownMenuItem(
                      value: 'advanced',
                      child: Text('Advanced'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _level = v);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                // Questions section
                Row(
                  children: [
                    Icon(
                      Icons.quiz_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Questions (${_questions.length})',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_questions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AdminTokens.sunken(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 40,
                          color: AdminTokens.textTertiary(isDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No questions yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AdminTokens.textSecondary(isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add" to create MCQ or Fill-in-the-blank questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminTokens.textTertiary(isDark),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ...List.generate(_questions.length, (i) {
                  final q = _questions[i];
                  final isFillBlank = q.type == 'fill_blank';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminTokens.raised(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isFillBlank
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isFillBlank
                                    ? const Color(0xFF10B981)
                                    : AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFillBlank
                                          ? const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(
                                              alpha: 0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isFillBlank ? 'FILL BLANK' : 'MCQ',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: isFillBlank
                                            ? const Color(0xFF10B981)
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                q.promptOlChiki.isNotEmpty
                                    ? q.promptOlChiki
                                    : (q.blankSentenceOlChiki ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AdminTokens.bodyStrong(
                                  isDark,
                                ).copyWith(fontSize: 13),
                              ),
                              if (q.promptLatin != null ||
                                  q.blankSentenceLatin != null)
                                Text(
                                  q.promptLatin ?? q.blankSentenceLatin ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AdminTokens.textTertiary(isDark),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          onPressed: () => _editQuestion(i),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          onPressed: () => _deleteQuestion(i),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedCategoryId == null
                        ? null
                        : () async {
                            final newQuiz = QuizModel(
                              id: widget.quiz?.id ?? const Uuid().v4(),
                              categoryId: _selectedCategoryId!,
                              title: _titleCtrl.text.trim().isEmpty
                                  ? null
                                  : _titleCtrl.text.trim(),
                              order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
                              passingScore:
                                  int.tryParse(_passingScoreCtrl.text.trim()) ??
                                  70,
                              level: _level,
                              isActive: _isActive,
                              questions: _questions,
                            );
                            try {
                              if (_isEditing) {
                                await ref
                                    .read(quizzesProvider.notifier)
                                    .updateQuiz(newQuiz);
                              } else {
                                await ref
                                    .read(quizzesProvider.notifier)
                                    .addQuiz(newQuiz);
                              }
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not save quiz: $e'),
                                ),
                              );
                            }
                          },
                    child: Text(_isEditing ? 'Save Changes' : 'Create Quiz'),
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

/// Full question editor supporting MCQ and Fill-in-the-blank
class _QuestionEditorSheet extends StatefulWidget {
  final QuizQuestion? question;
  final ValueChanged<QuizQuestion> onSave;
  const _QuestionEditorSheet({this.question, required this.onSave});

  @override
  State<_QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<_QuestionEditorSheet> {
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
          type: 'mcq',
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
                      child: _TypeChip(
                        label: 'Multiple Choice',
                        icon: Icons.radio_button_checked_rounded,
                        selected: _type == 'mcq',
                        onTap: () => setState(() => _type = 'mcq'),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeChip(
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
                  ..._buildMCQFields(isDark)
                else
                  ..._buildFillBlankFields(isDark),
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

  List<Widget> _buildMCQFields(bool isDark) {
    return [
      Text('Options (4 choices)', style: AdminTokens.label(isDark)),
      const SizedBox(height: 10),
      ...List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Radio<int>(
                value: i,
                groupValue: _correctIndex,
                onChanged: (v) => setState(() => _correctIndex = v!),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: TextField(
                  controller: _optOlChikiCtrls[i],
                  decoration: InputDecoration(
                    hintText: 'Option ${i + 1} (Ol Chiki)',
                    filled: true,
                    fillColor: AdminTokens.sunken(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _correctIndex == i
                            ? AppColors.primary
                            : AdminTokens.border(isDark),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _optLatinCtrls[i],
                  decoration: InputDecoration(
                    hintText: 'Option ${i + 1} (Latin)',
                    filled: true,
                    fillColor: AdminTokens.sunken(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _correctIndex == i
                            ? AppColors.primary
                            : AdminTokens.border(isDark),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
      Text(
        '● Radio = correct answer',
        style: TextStyle(
          fontSize: 11,
          color: AdminTokens.textTertiary(isDark),
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }

  List<Widget> _buildFillBlankFields(bool isDark) {
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Text(
                  'Use ___ (three underscores) as the blank placeholder',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      AdminTextField(
        controller: _blankOlChiki,
        label: 'Sentence with blank (Ol Chiki)',
        hint: 'e.g., ᱤᱧ ᱫᱚ ___ ᱠᱟᱱᱟ',
        maxLines: 2,
      ),
      const SizedBox(height: 14),
      AdminTextField(
        controller: _blankLatin,
        label: 'Sentence with blank (Latin)',
        hint: 'e.g., Ing do ___ kana',
        maxLines: 2,
      ),
      const SizedBox(height: 14),
      AdminTextField(
        controller: _correctAnswer,
        label: 'Correct Answer',
        hint: 'The word that fills the blank',
        prefixIcon: Icons.check_circle_outline_rounded,
      ),
      const SizedBox(height: 14),
      Text('Distractors (wrong choices)', style: AdminTokens.label(isDark)),
      const SizedBox(height: 8),
      ...List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: _distractorCtrls[i],
            decoration: InputDecoration(
              hintText: 'Wrong option ${i + 1}',
              filled: true,
              fillColor: AdminTokens.sunken(isDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AdminTokens.border(isDark)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            style: AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13),
          ),
        ),
      ),
    ];
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _TypeChip({
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
