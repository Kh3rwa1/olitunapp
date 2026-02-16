import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);

    return Scaffold(
      backgroundColor: AppColors.quizBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: quizzesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
                data: (quizzes) {
                  final progress = ref.watch(progressProvider);

                  final activeQuizzes = quizzes.where((q) {
                    if (!q.isActive || q.questions.isEmpty) return false;

                    final currentMastery =
                        progress.categoryMastery[q.categoryId] ?? 0;
                    final quizLevelValue = _getLevelValue(q.level);

                    return quizLevelValue <= currentMastery;
                  }).toList();

                  activeQuizzes.sort(
                    (a, b) => _getLevelValue(
                      a.level,
                    ).compareTo(_getLevelValue(b.level)),
                  );

                  if (activeQuizzes.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: activeQuizzes.length,
                    itemBuilder: (context, index) {
                      return _QuizCard(
                        quiz: activeQuizzes[index],
                        index: index,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/quiz/${activeQuizzes[index].id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a Quiz',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Test your Ol Chiki knowledge!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Mascot placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.premiumOrange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.premiumOrange,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.quiz_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'No quizzes yet!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Quizzes will appear here once created',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final int index;
  final VoidCallback onTap;

  const _QuizCard({
    required this.quiz,
    required this.index,
    required this.onTap,
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFFFFF9E6), Color(0xFFFFF3CD)], // Yellow
    [Color(0xFFFFECD6), Color(0xFFFFE0C2)], // Orange
    [Color(0xFFF0E6FF), Color(0xFFE6D9FF)], // Purple
    [Color(0xFFE6F9E6), Color(0xFFD4F5D4)], // Green
  ];

  static const List<Color> _badgeColors = [
    AppColors.quizBadgeA,
    AppColors.quizBadgeB,
    AppColors.quizBadgeC,
    AppColors.quizBadgeD,
  ];

  static const List<IconData> _icons = [
    Icons.abc_rounded,
    Icons.numbers_rounded,
    Icons.spellcheck_rounded,
    Icons.quiz_rounded,
  ];

  String _getLevelEmoji(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return '⭐';
      case 'intermediate':
        return '⭐⭐';
      case 'advanced':
        return '⭐⭐⭐';
      default:
        return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[index % 4];
    final badgeColor = _badgeColors[index % 4];
    final icon = _icons[index % 4];

    return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 18),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title ?? 'Quiz ${index + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${quiz.questions.length} questions',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getLevelEmoji(quiz.level),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Play Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: badgeColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 100).ms, duration: 400.ms)
        .slideX(begin: 0.1);
  }
}

int _getLevelValue(String level) {
  switch (level.toLowerCase()) {
    case 'beginner':
      return 0;
    case 'intermediate':
      return 1;
    case 'advanced':
      return 2;
    default:
      return 0;
  }
}
