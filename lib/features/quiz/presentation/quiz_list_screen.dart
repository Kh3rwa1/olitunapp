import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/bento_grid.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import 'widgets/quiz_list_cards.dart';

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      bottomNavigationBar: const BannerAdWidget(placement: 'quiz_list_bottom'),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Content
            Expanded(
              child: quizzesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => _QuizListErrorState(
                  isDark: isDark,
                  onRetry: () => ref.invalidate(quizzesProvider),
                ),
                data: (quizzes) {
                  final statsAsync = ref.watch(userStatsProvider);
                  final stats = statsAsync.value;

                  final activeQuizzes = quizzes.where((q) {
                    if (!q.isActive || q.questions.isEmpty) return false;
                    final currentMastery =
                        stats?.categoryMastery[q.categoryId] ?? 0;
                    final quizLevelValue = _getLevelValue(q.level);
                    return quizLevelValue <= currentMastery;
                  }).toList();

                  activeQuizzes.sort(
                    (a, b) => _getLevelValue(
                      a.level,
                    ).compareTo(_getLevelValue(b.level)),
                  );

                  if (activeQuizzes.isEmpty) {
                    return _buildEmptyState(context, isDark);
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 32 : 20,
                      20,
                      isTablet ? 32 : 20,
                      120,
                    ),
                    child: ResponsivePageContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Quiz Card (first quiz)
                          if (activeQuizzes.isNotEmpty)
                            AnimatedBentoChild(
                              index: 0,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push(
                                    '/quiz/${activeQuizzes.first.id}',
                                  );
                                },
                                child: HeroQuizCard(
                                  quiz: activeQuizzes.first,
                                  isDark: isDark,
                                ),
                              ),
                            ),

                          if (activeQuizzes.length > 1) ...[
                            const SizedBox(height: 16),
                            const RepaintBoundary(
                              child: NativeAdWidget(
                                placement: 'quiz_list_native',
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                                  'MORE QUIZZES',
                                  style: AppTypography.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideX(begin: -0.05),
                            const SizedBox(height: 16),

                            // Bento Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        ResponsiveLayout.gridColumns(context),
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: isDesktop
                                        ? 1.1
                                        : (isTablet ? 1.0 : 0.88),
                                  ),
                              itemCount: activeQuizzes.length - 1,
                              itemBuilder: (context, index) {
                                final quiz = activeQuizzes[index + 1];
                                return AnimatedBentoChild(
                                  index: index + 1,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      context.push('/quiz/${quiz.id}');
                                    },
                                    child: BentoQuizCard(
                                      quiz: quiz,
                                      index: index,
                                      isDark: isDark,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.glass(context, opacity: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.glass(context, opacity: 0.08),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHALLENGE YOURSELF',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: isDark
                        ? AppColors.accentOchre.withValues(alpha: 0.8)
                        : AppColors.accentOchreDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a Quiz',
                  style: AppTypography.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Mascot
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.premiumOrange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentOchre.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
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
              gradient: AppColors.premiumOrange,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentOchre.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.quiz_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No quizzes yet!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some lessons first',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _QuizListErrorState extends StatelessWidget {
  const _QuizListErrorState({required this.isDark, required this.onRetry});

  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Could not load quizzes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
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
