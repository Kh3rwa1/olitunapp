import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/bento_grid.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Content
            Expanded(
              child: quizzesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
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
                                child: _HeroQuizCard(
                                  quiz: activeQuizzes.first,
                                  isDark: isDark,
                                ),
                              ),
                            ),

                          if (activeQuizzes.length > 1) ...[
                            const SizedBox(height: 28),

                            Text(
                                  'MORE QUIZZES',
                                  style: GoogleFonts.inter(
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
                                    child: _BentoQuizCard(
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
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: isDark
                        ? AppColors.duoOrange.withValues(alpha: 0.8)
                        : AppColors.duoOrangeDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a Quiz',
                  style: GoogleFonts.inter(
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
                  color: AppColors.duoOrange.withValues(alpha: 0.3),
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
                  color: AppColors.duoOrange.withValues(alpha: 0.3),
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

// ═══════════════ HERO QUIZ CARD ═══════════════

class _HeroQuizCard extends StatelessWidget {
  final QuizModel quiz;
  final bool isDark;

  const _HeroQuizCard({required this.quiz, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BentoCell(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.duoOrange, AppColors.duoOrangeDark],
      ),
      borderRadius: 32,
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      boxShadow: [
        BoxShadow(
          color: AppColors.duoOrange.withValues(alpha: 0.35),
          blurRadius: 30,
          offset: const Offset(0, 12),
          spreadRadius: -4,
        ),
      ],
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child:
                Icon(
                      Icons.quiz_rounded,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.15),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -8, duration: 1800.ms)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 1800.ms,
                    ),
          ),
          Positioned(
            right: 60,
            top: 8,
            child:
                Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 600.ms)
                    .then()
                    .fadeOut(duration: 600.ms),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getLevelEmoji(quiz.level),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                quiz.title ?? 'Quiz Challenge',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${quiz.questions.length} questions • ${quiz.level}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.duoOrangeDark,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'START QUIZ',
                          style: TextStyle(
                            color: AppColors.duoOrangeDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    delay: 2.seconds,
                    duration: 1500.ms,
                    color: AppColors.duoOrange.withValues(alpha: 0.3),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════ BENTO QUIZ CARD ═══════════════

class _BentoQuizCard extends StatelessWidget {
  final QuizModel quiz;
  final int index;
  final bool isDark;

  const _BentoQuizCard({
    required this.quiz,
    required this.index,
    required this.isDark,
  });

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

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColors[index % 4];
    final icon = _icons[index % 4];

    return BentoCell(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: badgeColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),

          // Title
          Flexible(
            child: Text(
              quiz.title ?? 'Quiz ${index + 2}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // Meta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : badgeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${quiz.questions.length} questions',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : badgeColor,
              ),
            ),
          ),

          const Spacer(),

          // Level + Arrow
          Row(
            children: [
              Text(
                _getLevelEmoji(quiz.level),
                style: const TextStyle(fontSize: 14),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : badgeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
