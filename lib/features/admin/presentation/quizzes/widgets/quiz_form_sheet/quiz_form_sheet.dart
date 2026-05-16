import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/models/content_models.dart' hide CategoryModel;
import '../../../../../categories/domain/entities/category_entity.dart';
import '../../../../../../shared/providers/providers.dart';
import '../../../widgets/admin_form_widgets.dart';
import 'question_editor.dart';

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
      builder: (_) => QuestionEditorSheet(
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
                  initialValue: _selectedCategoryId,
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
                  initialValue: _level,
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
                    const Icon(
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
                          icon: const Icon(
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
