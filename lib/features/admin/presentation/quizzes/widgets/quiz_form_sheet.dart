import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/admin_tokens.dart';
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

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    final categories = ref.read(categoryNotifierProvider).value ?? const <CategoryEntity>[];
    
    _selectedCategoryId = quiz?.categoryId ?? (categories.isNotEmpty ? categories.first.id : null);
    _titleCtrl = TextEditingController(text: quiz?.title ?? '');
    _orderCtrl = TextEditingController(text: (quiz?.order ?? 0).toString());
    _passingScoreCtrl = TextEditingController(text: (quiz?.passingScore ?? 70).toString());
    _level = quiz?.level ?? 'beginner';
    _isActive = quiz?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orderCtrl.dispose();
    _passingScoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.read(categoryNotifierProvider).value ?? const <CategoryEntity>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
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
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.titleLatin),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
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
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _level = value);
                    }
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
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
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
                              title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
                              order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
                              passingScore: int.tryParse(_passingScoreCtrl.text.trim()) ?? 70,
                              level: _level,
                              isActive: _isActive,
                              questions: widget.quiz?.questions ?? const <QuizQuestion>[],
                            );

                            try {
                              if (_isEditing) {
                                await ref.read(quizzesProvider.notifier).updateQuiz(newQuiz);
                              } else {
                                await ref.read(quizzesProvider.notifier).addQuiz(newQuiz);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not save quiz: $e')),
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
