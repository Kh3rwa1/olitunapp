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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final streak = ref.watch(userStreakProvider);
    final stars = ref.watch(userStarsProvider);
    final lessonsCompleted = ref.watch(lessonsCompletedProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background Mesh/Glow
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
                                  'Daily Progress: 85%',
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

                  // Bento Stats Grid
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
                                  value: '24m',
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
                                index: 1, // 1st tier
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
                                index: 2, // 2nd tier
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
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
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
                              value: '24m',
                              label: 'Learning Time',
                              color: AppColors.duoBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Main Journey Card - Glassmorphism Bento
                  FadeInSlide(
                    index: 5,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
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
                                onPressed: () => context.go('/lessons'),
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
                        ),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: isTablet ? 1.05 : 0.9,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return FadeInSlide(
                          index:
                              6 + index, // Stagger categories after stats/hero
                          child: _ModernCategoryCard(
                            category: category,
                            index: index,
                          ),
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                  const SizedBox(height: 100),
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
      onTap: () => context.go('/lessons/category/${category.id}'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.glass(context, opacity: 0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.glass(context, opacity: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_getIcon(), color: AppColors.primary, size: 28),
            ),
            const Spacer(),
            Text(
              category.titleLatin,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              category.titleOlChiki,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
