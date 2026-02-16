import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';

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
    final categoriesAsync = ref.watch(categoriesProvider);

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
        backgroundColor: AppColors
            .accentPink, // Fixed: use primary color not gradient preset

        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create Quiz',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0A0E14), const Color(0xFF0D1117)]
              : [const Color(0xFFF8FAFC), Colors.white],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isWideScreen)
          GestureDetector(
            onTap: () => context.go('/admin'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        if (!isWideScreen) const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.premiumPink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quizzes',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and manage assessments',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.premiumPink,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'No quizzes found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Create your first quiz to get started',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9));
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
    final categories = ref.read(categoriesProvider).value ?? const <CategoryModel>[];
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
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
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
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.04),
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
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.04),
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

  void _showDeleteDialog(BuildContext context, QuizModel quiz) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete quiz?'),
        content: Text('This will permanently delete "${quiz.title ?? 'Untitled Quiz'}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(quizzesProvider.notifier).deleteQuiz(quiz.id);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.premiumPink.colors.first
              : (isDark
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white10 : Colors.black12),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.premiumPink.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.premiumPink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title ?? 'Untitled Quiz', // Fixed: title is nullable
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${quiz.questions.length} questions',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 20),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
