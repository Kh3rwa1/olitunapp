import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/models/content_models.dart' hide CategoryModel;
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_form_widgets.dart';
import 'widgets/quiz_card.dart';
import 'widgets/quiz_form_sheet.dart';

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
                          AdminFilterChip(
                            label: 'All Quizzes',
                            selected: _selectedCategoryId == null,
                            onTap: () =>
                                setState(() => _selectedCategoryId = null),
                          ),
                          ...categories.map(
                            (img) => Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: AdminFilterChip(
                                label: img.titleLatin,
                                selected: _selectedCategoryId == img.id,
                                onTap: () => setState(
                                  () => _selectedCategoryId = img.id,
                                ),
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
                    error: (error, _) => Center(
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
        onPressed: () => QuizFormSheet.show(context, ref, null),
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
        const Expanded(
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
          message:
              'Create your first quiz to assess what learners have mastered.',
          actionLabel: 'Add Quiz',
          onAction: () => QuizFormSheet.show(context, ref, null),
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
        return QuizCard(
          quiz: quiz,
          isDark: isDark,
          onEdit: () => QuizFormSheet.show(context, ref, quiz),
          onDelete: () => _showDeleteDialog(context, quiz),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, QuizModel quiz) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Quiz',
      message:
          'This will permanently delete "${quiz.title ?? 'Untitled Quiz'}". This action cannot be undone.',
    );
    if (ok == true) {
      try {
        await ref.read(quizzesProvider.notifier).deleteQuiz(quiz.id);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete quiz: $e')));
      }
    }
  }
}
