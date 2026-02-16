import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../core/presentation/animations/fade_in_slide.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../rhymes/presentation/widgets/enchanted_visualizer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final progressData = ref.watch(progressProvider);
    final streak = progressData.currentStreak;
    final stars = ref.watch(userStarsProvider);
    final lessonsCompleted = ref.watch(lessonsCompletedProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    // Real computed values
    final learningTime = progressData.totalLearningMinutes;
    final dailyProgress =
        ((progressData.alphabetProgress +
                    progressData.numbersProgress +
                    progressData.vocabularyProgress) /
                3 *
                100)
            .round();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop
          ? Colors.transparent
          : isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Stack(
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
                          color: AppColors.primary.withOpacity(0.15),
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
                              'Hello, $userName!',
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
                                color: AppColors.glass(context, opacity: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.glass(context, opacity: 0.1),
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
                    const SizedBox(height: 32),

                    // Bento Stats Grid — hidden on desktop (shown in right sidebar)
                    if (!isDesktop) ...[
                      isTablet
                          ? Row(
                              children: [
                                Expanded(
                                  child: FadeInSlide(
                                    index: 1,
                                    child: _ModernStatCard(
                                      icon: Icons.local_fire_department_rounded,
                                      value: '$streak',
                                      label: 'Day Streak',
                                      color: AppColors.duoOrange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FadeInSlide(
                                    index: 2,
                                    child: _ModernStatCard(
                                      icon: Icons.star_rounded,
                                      value: '$stars',
                                      label: 'Stars',
                                      color: AppColors.duoYellow,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FadeInSlide(
                                    index: 3,
                                    child: _ModernStatCard(
                                      icon: Icons.emoji_events_rounded,
                                      value: '$lessonsCompleted',
                                      label: 'Milestones',
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FadeInSlide(
                                    index: 4,
                                    child: _ModernStatCard(
                                      icon: Icons.timer_rounded,
                                      value: '${learningTime}m',
                                      label: 'Learning Time',
                                      color: AppColors.duoBlue,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: FadeInSlide(
                                    index: 1,
                                    child: _ModernStatCard(
                                      icon: Icons.local_fire_department_rounded,
                                      value: '$streak',
                                      label: 'Day Streak',
                                      color: AppColors.duoOrange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FadeInSlide(
                                    index: 2,
                                    child: _ModernStatCard(
                                      icon: Icons.star_rounded,
                                      value: '$stars',
                                      label: 'Stars',
                                      color: AppColors.duoYellow,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      if (!isTablet) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FadeInSlide(
                                index: 3,
                                child: _ModernStatCard(
                                  icon: Icons.emoji_events_rounded,
                                  value: '$lessonsCompleted',
                                  label: 'Milestones',
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FadeInSlide(
                                index: 4,
                                child: _ModernStatCard(
                                  icon: Icons.timer_rounded,
                                  value: '${learningTime}m',
                                  label: 'Learning Time',
                                  color: AppColors.duoBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),

                    // Main Journey Card - Glassmorphism Bento
                    FadeInSlide(
                      index: 5,
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
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: AppColors.fluidShadow,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child:
                                  Icon(
                                        Icons.rocket_launch_rounded,
                                        size: 120,
                                        color: Colors.white.withOpacity(0.15),
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .moveY(
                                        begin: 0,
                                        end: -10,
                                        duration: 2.seconds,
                                      ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CONTINUE LEARNING',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Master the Vowels',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                DuoButton(
                                  text: 'RESUME JOURNEY',
                                  color: Colors.white,
                                  onPressed: () => context.push('/lessons'),

                                  width: double.infinity,
                                  height: 56,
                                  borderRadius: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Categories Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LEARNING PATHS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isDark
                                ? AppColors.primary
                                : AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Categories Grid
                    categoriesAsync.when(
                      data: (categories) => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ResponsiveLayout.gridColumns(
                            context,
                            mobile: 2,
                            tablet: 3,
                            desktop: 3,
                          ),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: isDesktop
                              ? 1.1
                              : (isTablet ? 1.05 : 1.0),
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return FadeInSlide(
                            index:
                                6 +
                                index, // Stagger categories after stats/hero
                            child: _ModernCategoryCard(
                              category: category,
                              index: index,
                            ),
                          );
                        },
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red.withValues(alpha: 0.08)
                              : Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.red.withValues(alpha: 0.6),
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Could not load learning paths',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check your connection and try again',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quiz Banner - Primary Green (Bottom Section)
                    FadeInSlide(
                      index: 10,
                      child: GestureDetector(
                        onTap: () => context.push('/quizzes'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryLight,
                                AppColors.primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Floating Quiz Icon
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child:
                                    Icon(
                                          Icons.quiz_rounded,
                                          size: 100,
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .moveY(
                                          begin: 0,
                                          end: -8,
                                          duration: 1800.ms,
                                          curve: Curves.easeInOut,
                                        )
                                        .scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.05, 1.05),
                                          duration: 1800.ms,
                                        ),
                              ),
                              // Sparkle decoration
                              Positioned(
                                right: 60,
                                top: 10,
                                child:
                                    Icon(
                                          Icons.auto_awesome,
                                          size: 20,
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
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
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.emoji_events_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'DAILY QUIZ',
                                              style: TextStyle(
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
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Test Your Knowledge!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '3 Quizzes Available',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.play_arrow_rounded,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'START QUIZ',
                                              style: TextStyle(
                                                color: AppColors.primaryDark,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .shimmer(
                                        delay: 2.seconds,
                                        duration: 1500.ms,
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Extra bottom padding on mobile for the bottom nav bar
                    SizedBox(height: isDesktop ? 32 : 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ModernStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glass(context, opacity: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glass(context, opacity: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int index;

  const _ModernCategoryCard({required this.category, required this.index});

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

    return InkWell(
      onTap: () => context.push('/lessons/category/${category.id}'),

      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glass(context, opacity: 0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.glass(context, opacity: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getIcon(), color: AppColors.primary, size: 24),
            ),
            const Spacer(),
            Flexible(
              child: Text(
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
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
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
            ),
          ],
        ),
      ),
    );
  }
}
