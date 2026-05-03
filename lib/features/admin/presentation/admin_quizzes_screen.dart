import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/admin_tokens.dart';
import 'widgets/admin_form_widgets.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_page_header.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart' hide CategoryModel;
import '../../categories/domain/entities/category_entity.dart';

class AdminQuizzesScreen extends ConsumerStatefulWidget {
  const AdminQuizzesScreen({super.key});

  @override
  ConsumerState<AdminQuizzesScreen> createState() => _AdminQuizzesScreenState();
}

class _AdminQuizzesScreenState extends ConsumerState<AdminQuizzesScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(quizzesProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackground(isDark),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isWideScreen ? 32 : 20),
                  child: _buildHeader(context, isDark, isWideScreen),
                ),

                // Category Filter
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 20,
                  ),
                  child: categoriesAsync.when(
                    data: (categories) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All Quizzes',
                            isSelected: _selectedCategoryId == null,
                            onTap: () =>
                                setState(() => _selectedCategoryId = null),
                            isDark: isDark,
                          ),
                          ...categories.map(
                            (img) => Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _FilterChip(
                                label: img.titleLatin,
                                isSelected: _selectedCategoryId == img.id,
                                onTap: () => setState(
                                  () => _selectedCategoryId = img.id,
                                ),
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: quizzesAsync.when(
                    data: (quizzes) {
                      final filteredQuizzes = _selectedCategoryId == null
                          ? quizzes
                          : quizzes
                                .where(
                                  (q) => q.categoryId == _selectedCategoryId,
                                )
                                .toList();

                      return filteredQuizzes.isEmpty
                          ? _buildEmptyState(context, isDark)
                          : _buildQuizzesList(
                              filteredQuizzes,
                              isDark,
                              isWideScreen,
                            );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuizDialog(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create Quiz',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(color: AdminTokens.base(isDark));
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isWideScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isWideScreen) ...[
          GestureDetector(
            onTap: () => context.go('/admin'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminTokens.sunken(isDark),
                borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                border: Border.all(color: AdminTokens.border(isDark)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AdminTokens.textPrimary(isDark),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: AdminPageHeader(
            title: 'Quizzes',
            subtitle: 'Create and manage assessments',
            eyebrow: 'CONTENT · QUIZZES',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return AdminEmptyState(
      icon: Icons.quiz_outlined,
      title: 'No quizzes found',
      message: 'Create your first quiz to assess what learners have mastered.',
      actionLabel: 'Add Quiz',
      onAction: () => _showQuizDialog(context, null),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildQuizzesList(
    List<QuizModel> quizzes,
    bool isDark,
    bool isWideScreen,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return _QuizCard(
          quiz: quiz,
          isDark: isDark,
          onEdit: () => _showQuizDialog(context, quiz),
          onDelete: () => _showDeleteDialog(context, quiz),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
      },
    );
  }

  void _showQuizDialog(BuildContext context, QuizModel? quiz) {
    final isEditing = quiz != null;
    final categories = ref.read(categoryNotifierProvider).value ?? const <CategoryEntity>[];
    var selectedCategoryId = quiz?.categoryId ?? (categories.isNotEmpty ? categories.first.id : null);
    final titleController = TextEditingController(text: quiz?.title ?? '');
    final orderController = TextEditingController(text: (quiz?.order ?? 0).toString());
    final passingScoreController = TextEditingController(text: (quiz?.passingScore ?? 70).toString());
    var level = quiz?.level ?? 'beginner';
    var isActive = quiz?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) => Container(
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
                          isEditing ? 'Edit Quiz' : 'Create Quiz',
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
                      _dialogTextField(
                        controller: titleController,
                        label: 'Title',
                        hint: 'Enter quiz title',
                        isDark: isDark,
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
                        initialValue: selectedCategoryId,
                        items: categories
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.titleLatin)))
                            .toList(),
                        onChanged: (value) => setDialogState(() => selectedCategoryId = value),
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
                            child: _dialogTextField(
                              controller: orderController,
                              label: 'Order',
                              hint: '0',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dialogTextField(
                              controller: passingScoreController,
                              label: 'Passing Score',
                              hint: '70',
                              isDark: isDark,
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
                        initialValue: level,
                        items: const [
                          DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                          DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                          DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                        ],
                        onChanged: (value) {
                          if (value != null) setDialogState(() => level = value);
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
                        value: isActive,
                        onChanged: (value) => setDialogState(() => isActive = value),
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
                          onPressed: selectedCategoryId == null
                              ? null
                              : () async {
                                  final newQuiz = QuizModel(
                                    id: quiz?.id ?? const Uuid().v4(),
                                    categoryId: selectedCategoryId,
                                    title: titleController.text.trim().isEmpty ? null : titleController.text.trim(),
                                    order: int.tryParse(orderController.text.trim()) ?? 0,
                                    passingScore: int.tryParse(passingScoreController.text.trim()) ?? 70,
                                    level: level,
                                    isActive: isActive,
                                    questions: quiz?.questions ?? const <QuizQuestion>[],
                                  );

                                  if (isEditing) {
                                    await ref.read(quizzesProvider.notifier).updateQuiz(newQuiz);
                                  } else {
                                    await ref.read(quizzesProvider.notifier).addQuiz(newQuiz);
                                  }

                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: Text(isEditing ? 'Save Changes' : 'Create Quiz'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    QuizModel quiz,
  ) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Quiz',
      message:
          'This will permanently delete "${quiz.title ?? 'Untitled Quiz'}". This action cannot be undone.',
    );
    if (ok == true) {
      await ref.read(quizzesProvider.notifier).deleteQuiz(quiz.id);
    }
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return AdminTextField(
      controller: controller,
      label: label,
      hint: hint,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AdminFilterChip(
      label: label,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuizCard({
    required this.quiz,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminTokens.raised(isDark),
          borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
          border: Border.all(color: AdminTokens.border(isDark)),
          boxShadow: AdminTokens.raisedShadow(isDark),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AdminTokens.accentSoft(isDark),
                borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                border: Border.all(color: AdminTokens.accentBorder(isDark)),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: AdminTokens.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title ?? 'Untitled Quiz',
                    style: AdminTokens.cardTitle(isDark).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${quiz.questions.length} questions',
                    style: AdminTokens.label(isDark),
                  ),
                ],
              ),
            ),
            AdminIconAction(
              icon: Icons.edit_rounded,
              tooltip: 'Edit',
              onTap: onEdit,
            ),
            const SizedBox(width: 6),
            AdminIconAction(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              destructive: true,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
