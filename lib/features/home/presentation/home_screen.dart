import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/widgets/bento_grid.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../categories/domain/entities/category_entity.dart';
import '../../categories/presentation/providers/category_notifier.dart';
import '../../lessons/presentation/providers/lesson_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Providers initialize with seed data synchronously.
    // Network refresh happens automatically in the background via provider init.
  }

  Future<void> _onRefresh() async {
    await ref.read(categoryNotifierProvider.notifier).refresh();
    await ref.read(lessonNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final stars = ref.watch(userStarsProvider);
    final lessonsCompleted = ref.watch(lessonsCompletedProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    final stats = statsAsync.value;
    final streak = stats?.currentStreak ?? 0;
    final learningTime = stats?.totalLearningMinutes ?? 0;
    final dailyProgress = stats != null
        ? ((stats.alphabetProgress + stats.numbersProgress + stats.vocabularyProgress) / 3 * 100).round()
        : 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);


    return Scaffold(
      backgroundColor: isDesktop
          ? Colors.transparent
          : isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: Stack(
          children: [
            // Background Mesh/Glow — skip on desktop (shell already provides it)
            if (!isDesktop) ...[
              Positioned.fill(
                child: EnchantedVisualizer(
                  isPlaying: true,
                  color: AppColors.primary,
                  showWaves: false,
                  showParticles: true,
                  height: 300,
                ),
              ),
              Positioned(
                top: -100,
                right: -100,
                child:
                    Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 1200.ms)
                        .scale(begin: const Offset(0.5, 0.5)),
              ),
            ],

            SafeArea(
              child: SingleChildScrollView(
                child: ResponsivePageContainer(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 8 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Johar, $userName!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.glass(
                                      context,
                                      opacity: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.glass(
                                        context,
                                        opacity: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Daily Progress: $dailyProgress%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Hide bell on desktop — stats are in right panel
                            if (!isDesktop)
                              CircleIconButton(
                                icon: Icons.notifications_none_rounded,
                                onPressed: () {},
                                size: 52,
                                backgroundColor: AppColors.glass(
                                  context,
                                  opacity: 0.05,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ═══════════════════════════════════════
                        //  BENTO GRID LAYOUT
                        // ═══════════════════════════════════════

                        // Row 1: Stats Bento Grid (mobile/tablet only)
                        if (!isDesktop) ...[
                          _buildStatsBentoGrid(
                            streak: streak,
                            stars: stars,
                            lessonsCompleted: lessonsCompleted,
                            learningTime: learningTime,
                            isDark: isDark,
                            isTablet: isTablet,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Row 2: Hero Journey + Quiz Banner (side-by-side on tablet/desktop)
                        if (isTablet || isDesktop)
                          _buildHeroBentoRow(context, isDark)
                        else ...[
                          _buildHeroJourneyCard(context, isDark, 0),
                          const SizedBox(height: 16),
                          _buildQuizBannerCard(context, isDark, 1),
                        ],

                        const SizedBox(height: 20),

                        // Row 3: AI Tools + Categories (true bento grid)
                        _buildContentBentoGrid(
                          context: context,
                          categoriesAsync: categoriesAsync,
                          isDark: isDark,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                        ),

                        // Extra bottom padding on mobile for the bottom nav bar
                        SizedBox(height: isDesktop ? 32 : 120),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BENTO: Stats Grid ─────────────────────────────────
  Widget _buildStatsBentoGrid({
    required int streak,
    required int stars,
    required int lessonsCompleted,
    required int learningTime,
    required bool isDark,
    required bool isTablet,
  }) {
    if (isTablet) {
      // 4-column bento on tablet
      return Row(
        children: [
          Expanded(child: _BentoStatCard(icon: Icons.local_fire_department_rounded, value: '$streak', label: 'Day Streak', color: AppColors.duoOrange, index: 0)),
          const SizedBox(width: 12),
          Expanded(child: _BentoStatCard(icon: Icons.star_rounded, value: '$stars', label: 'Stars', color: AppColors.duoYellow, index: 1)),
          const SizedBox(width: 12),
          Expanded(child: _BentoStatCard(icon: Icons.emoji_events_rounded, value: '$lessonsCompleted', label: 'Milestones', color: AppColors.primary, index: 2)),
          const SizedBox(width: 12),
          Expanded(child: _BentoStatCard(icon: Icons.timer_rounded, value: '${learningTime}m', label: 'Time', color: AppColors.duoBlue, index: 3)),
        ],
      );
    }

    // Mobile: 2x2 bento grid with streak spanning 2 cols
    return Column(
      children: [
        // Top row: Streak (wide) + Stars
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _BentoStatCard(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: 'Day Streak',
                color: AppColors.duoOrange,
                index: 0,
                isHero: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _BentoStatCard(
                icon: Icons.star_rounded,
                value: '$stars',
                label: 'Stars',
                color: AppColors.duoYellow,
                index: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row: Milestones + Time (wide)
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _BentoStatCard(
                icon: Icons.emoji_events_rounded,
                value: '$lessonsCompleted',
                label: 'Milestones',
                color: AppColors.primary,
                index: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _BentoStatCard(
                icon: Icons.timer_rounded,
                value: '${learningTime}m',
                label: 'Learning Time',
                color: AppColors.duoBlue,
                index: 3,
                isHero: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── BENTO: Hero + Quiz side-by-side (tablet/desktop) ──
  Widget _buildHeroBentoRow(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildHeroJourneyCard(context, isDark, 4),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildQuizBannerCard(context, isDark, 5),
        ),
      ],
    );
  }

  // ─── BENTO: Hero Journey Card ──────────────────────────
  Widget _buildHeroJourneyCard(BuildContext context, bool isDark, int index) {
    return AnimatedBentoChild(
      index: index,
      child: GestureDetector(
        onTap: () => context.push('/lessons'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.fluidShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 120,
                      color: Colors.white.withValues(alpha: 0.15),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -10, duration: 2.seconds),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CONTINUE LEARNING',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Master the\nVowels',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DuoButton(
                    text: 'RESUME JOURNEY',
                    color: Colors.white,
                    onPressed: () => context.push('/lessons'),
                    width: double.infinity,
                    height: 52,
                    borderRadius: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BENTO: Quiz Banner Card ───────────────────────────
  Widget _buildQuizBannerCard(BuildContext context, bool isDark, int index) {
    return AnimatedBentoChild(
      index: index,
      child: GestureDetector(
        onTap: () => context.push('/quizzes'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                      Icons.quiz_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.2),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -8, duration: 1800.ms, curve: Curves.easeInOut),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'DAILY QUIZ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Test Your\nKnowledge!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '3 Quizzes Available',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'START',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BENTO: Content Grid (AI Tools + Categories) ───────
  Widget _buildContentBentoGrid({
    required BuildContext context,
    required AsyncValue<List<CategoryEntity>> categoriesAsync,
    required bool isDark,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final cols = isDesktop ? 4 : (isTablet ? 3 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DISCOVER',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDark ? AppColors.primary : AppColors.primaryDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cols == 2 ? 'SWIPE' : 'EXPLORE',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bento grid: AI Translate tool (2-col span) + Category cards
        categoriesAsync.when(
          data: (categories) {
            // Build the bento items list: AI tool first, then categories
            return _BentoContentGrid(
              isDark: isDark,
              cols: cols,
              categories: categories,
            );
          },
          loading: () => _buildContentSkeleton(cols),
          error: (e, st) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.withValues(alpha: 0.08)
                  : Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.red.withValues(alpha: 0.6), size: 32),
                const SizedBox(height: 12),
                Text(
                  'Could not load learning paths',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSkeleton(int cols) {
    const gap = 14.0;
    return Column(
      children: [
        // AI tool skeleton
        const Skeleton(width: double.infinity, height: 80, borderRadius: 24),
        const SizedBox(height: gap),
        // Category grid skeletons
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: 140,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const Skeleton(borderRadius: 24),
        ),
      ],
    );
  }

}

// ═══════════════════════════════════════════════════════════
// BENTO STAT CARD — glassmorphism stat tile with hover
// ═══════════════════════════════════════════════════════════
class _BentoStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final int index;
  final bool isHero;

  const _BentoStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.index,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBentoChild(
      index: index,
      child: BentoCell(
        padding: EdgeInsets.all(isHero ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: isHero ? 22 : 18),
                ),
                if (isHero) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.trending_up_rounded, color: color, size: 14),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: isHero ? 28 : 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BENTO CONTENT GRID — AI Translate + Category cards
// Uses explicit Row+Expanded for perfect alignment
// ═══════════════════════════════════════════════════════════
class _BentoContentGrid extends StatelessWidget {
  final bool isDark;
  final int cols;
  final List<CategoryEntity> categories;

  const _BentoContentGrid({
    required this.isDark,
    required this.cols,
    required this.categories,
  });

  static const _categoryGradients = [
    [Color(0xFF6366F1), Color(0xFF4F46E5)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFEF4444), Color(0xFFDC2626)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  ];

  Widget _buildAITranslateCard(BuildContext context) {
    return AnimatedBentoChild(
      index: 6,
      child: GestureDetector(
        onTap: () => context.push('/translate'),
        child: BentoCell(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Instant Translate',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Any Language → Ol Chiki',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryEntity cat, int catIndex) {
    final grad = _categoryGradients[catIndex % _categoryGradients.length];
    return AnimatedBentoChild(
      index: 7 + catIndex,
      child: _BentoCategoryCard(
        category: cat,
        gradientColors: grad,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;

    final catCards = List.generate(
      categories.length,
      (i) => _buildCategoryCard(categories[i], i),
    );

    if (cols >= 3) {
      // Desktop / Tablet: Row 1 = AI Translate (flex 2) + first categories
      final firstRowCats = catCards.take(cols - 2).toList();
      final remainingCats = catCards.skip(cols - 2).toList();

      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildAITranslateCard(context),
                ),
                ...firstRowCats.map((card) => Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: gap),
                    child: card,
                  ),
                )),
              ],
            ),
          ),
          if (remainingCats.isNotEmpty) ...[
            const SizedBox(height: gap),
            _buildCategoryRows(remainingCats, cols, gap),
          ],
        ],
      );
    } else {
      // Mobile: AI Translate full width + categories in 2-col rows
      return Column(
        children: [
          _buildAITranslateCard(context),
          const SizedBox(height: gap),
          _buildCategoryRows(catCards, 2, gap),
        ],
      );
    }
  }

  Widget _buildCategoryRows(List<Widget> cards, int cols, double gap) {
    final rows = <Widget>[];

    for (var i = 0; i < cards.length; i += cols) {
      final rowItems = cards.skip(i).take(cols).toList();
      rows.add(
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(
                  child: j < rowItems.length
                      ? rowItems[j]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      if (i + cols < cards.length) {
        rows.add(SizedBox(height: gap));
      }
    }

    return Column(children: rows);
  }
}

// ═══════════════════════════════════════════════════════════
// BENTO CATEGORY CARD — individual learning path tile
// ═══════════════════════════════════════════════════════════
class _BentoCategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final List<Color> gradientColors;

  const _BentoCategoryCard({
    required this.category,
    required this.gradientColors,
  });

  IconData _getIcon() {
    switch (category.iconName) {
      case 'alphabet':
        return Icons.translate_rounded;
      case 'numbers':
        return Icons.calculate_rounded;
      case 'words':
        return Icons.forum_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/lessons/category/${category.id}'),
      child: BentoCell(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors[0].withValues(alpha: 0.15),
                    gradientColors[1].withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getIcon(), color: gradientColors[0], size: 22),
            ),
            const Spacer(),
            Text(
              category.titleLatin,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              category.titleOlChiki,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'OlChiki',
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
