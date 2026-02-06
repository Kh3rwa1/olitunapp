import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/widgets/gamified_card.dart';
import '../../../shared/widgets/animated_buttons.dart';

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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Animation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName!',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                              letterSpacing: -1,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to learn today? 👋',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  CircleIconButton(
                    icon: Icons.settings_rounded,
                    onPressed: () => context.go('/settings'),
                    size: 52,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Stats Row with Gamified Cards
              Row(
                children: [
                  _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '$streak',
                        label: 'Streak',
                        color: AppColors.duoOrange,
                        shadowColor: AppColors.duoOrangeDark,
                        delay: 400,
                      )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scale(curve: Curves.easeOutBack),
                  const SizedBox(width: 12),
                  _StatCard(
                        icon: Icons.star_rounded,
                        value: '$stars',
                        label: 'Stars',
                        color: AppColors.duoYellow,
                        shadowColor: AppColors.duoYellowDark,
                        delay: 500,
                      )
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .scale(curve: Curves.easeOutBack),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.auto_awesome_rounded,
                    value: '$lessonsCompleted',
                    label: 'Level',
                    color: AppColors.primary,
                    shadowColor: AppColors.primaryDark,
                    delay: 600,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Continue Learning Banner - Gamified
              GamifiedCard(
                color: AppColors.primary,
                bottomBorderColor: AppColors.primaryDark,
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UP NEXT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white70,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Continue Journey',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          DuoButton(
                            text: 'START NOW',
                            color: Colors.white,
                            onPressed: () => context.go('/lessons'),
                            width: 160,
                            height: 48,
                            shadowColor: Colors.black12,
                            borderRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Hero(
                          tag: 'journey_icon',
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .moveY(
                          begin: 0,
                          end: -8,
                          duration: 1500.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Section Header
              Text(
                'COLUMBUS PATH',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.primary : AppColors.primaryDark,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Categories Grid or List
              categoriesAsync.when(
                data: (categories) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCard(category: category, index: index);
                  },
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('Error loading categories: $e'),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color shadowColor;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GamifiedCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        borderRadius: 20,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
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
      ).animate().fadeIn(delay: delay.ms).scale(curve: Curves.easeOutBack),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int index;

  const _CategoryCard({required this.category, required this.index});

  Color _getPrimaryColor() {
    switch (category.gradientPreset) {
      case 'peach':
        return AppColors.duoOrange;
      case 'mint':
        return AppColors.duoGreen;
      case 'purple':
        return AppColors.duoPurple;
      case 'skyBlue':
        return AppColors.duoBlue;
      default:
        return AppColors.primary;
    }
  }

  Color _getShadowColor() {
    switch (category.gradientPreset) {
      case 'peach':
        return AppColors.duoOrangeDark;
      case 'mint':
        return AppColors.duoGreenDark;
      case 'purple':
        return AppColors.duoPurpleDark;
      case 'skyBlue':
        return AppColors.duoBlueDark;
      default:
        return AppColors.primaryDark;
    }
  }

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
    final themeColor = _getPrimaryColor();
    final shadowColor = _getShadowColor();

    return GamifiedCard(
      onTap: () => context.go('/lessons/category/${category.id}'),
      color: themeColor,
      bottomBorderColor: shadowColor,
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getIcon(), color: Colors.white, size: 28),
          ),
          const Spacer(),
          Text(
            category.titleLatin,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            category.titleOlChiki,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: shadowColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${category.totalLessons} LESSONS',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
