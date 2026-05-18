import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../shared/models/content_models.dart' hide CategoryModel;
import '../../../../../categories/domain/entities/category_entity.dart';
import '../../../../../../shared/providers/providers.dart';
import 'quiz_form_header.dart';
import 'quiz_basic_info_section.dart';
import 'quiz_questions_section.dart';
import 'quiz_form_actions.dart';
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
        ref.watch(categoryNotifierProvider).value ?? const <CategoryEntity>[];

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
          QuizFormHeader(
            isEditing: _isEditing,
            onClose: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              children: [
                QuizBasicInfoSection(
                  titleCtrl: _titleCtrl,
                  orderCtrl: _orderCtrl,
                  passingScoreCtrl: _passingScoreCtrl,
                  selectedCategoryId: _selectedCategoryId,
                  level: _level,
                  isActive: _isActive,
                  categories: categories,
                  onCategoryChanged: (v) =>
                      setState(() => _selectedCategoryId = v),
                  onLevelChanged: (v) => setState(() => _level = v),
                  onActiveChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 20),
                QuizQuestionsSection(
                  questions: _questions,
                  onAddQuestion: _addQuestion,
                  onEditQuestion: _editQuestion,
                  onDeleteQuestion: _deleteQuestion,
                ),
              ],
            ),
          ),
          QuizFormActions(
            isEditing: _isEditing,
            isSaveEnabled: _selectedCategoryId != null,
            onCancel: () => Navigator.pop(context),
            onSave: () async {
              final newQuiz = QuizModel(
                id: widget.quiz?.id ?? const Uuid().v4(),
                categoryId: _selectedCategoryId!,
                title: _titleCtrl.text.trim().isEmpty
                    ? null
                    : _titleCtrl.text.trim(),
                order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
                passingScore: int.tryParse(_passingScoreCtrl.text.trim()) ?? 70,
                level: _level,
                isActive: _isActive,
                questions: _questions,
              );
              try {
                if (_isEditing) {
                  await ref.read(quizzesProvider.notifier).updateQuiz(newQuiz);
                } else {
                  await ref.read(quizzesProvider.notifier).addQuiz(newQuiz);
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not save quiz: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
