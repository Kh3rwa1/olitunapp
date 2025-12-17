import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BubbleBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.settings_outlined,
                    onPressed: () => context.pushNamed('settings'),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Profile card
              user.when(
                data: (userData) => _buildProfileCard(context, userData),
                loading: () => const ShimmerCard(height: 200),
                error: (_, __) => const Text('Failed to load profile'),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Stats grid
              user.when(
                data: (userData) => _buildStatsGrid(context, userData),
                loading: () => const ShimmerCard(height: 120),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Achievements section
              _buildSectionTitle(context, 'Achievements'),
              const SizedBox(height: AppConstants.spacingM),
              _buildAchievements(context),
              const SizedBox(height: AppConstants.spacingL),

              // Admin access (if admin)
              Consumer(
                builder: (context, ref, child) {
                  final isAdmin = ref.watch(isAdminProvider);
                  return isAdmin.when(
                    data: (admin) {
                      if (!admin) return const SizedBox.shrink();
                      return Column(
                        children: [
                          const Divider(),
                          const SizedBox(height: AppConstants.spacingM),
                          SoftCard(
                            onTap: () => context.go('/admin'),
                            padding: const EdgeInsets.all(AppConstants.spacingM),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.purpleGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Admin Panel',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      Text(
                                        'Manage app content',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isDark
                                              ? AppColors.textTertiaryDark
                                              : AppColors.textTertiaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic userData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = userData?.displayName ?? 'Learner';
    final email = userData?.email ?? '';

    return SoftCard(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.coloredShadow(AppColors.primaryCyan),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'L',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Name
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Text(
              (userData?.preferences.level ?? 'beginner').toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic userData) {
    final stats = userData?.stats;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.accentOrange,
            value: '${stats?.streak ?? 0}',
            label: 'Day Streak',
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.accentYellow,
            value: '${stats?.stars ?? 0}',
            label: 'Stars',
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            value: '${stats?.totalLessonsCompleted ?? 0}',
            label: 'Lessons',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildAchievements(BuildContext context) {
    final achievements = [
      _Achievement(
        icon: Icons.school_rounded,
        title: 'First Steps',
        description: 'Complete your first lesson',
        isUnlocked: true,
        gradient: AppColors.skyBlueGradient,
      ),
      _Achievement(
        icon: Icons.local_fire_department_rounded,
        title: 'On Fire',
        description: '7 day streak',
        isUnlocked: false,
        gradient: AppColors.coralGradient,
      ),
      _Achievement(
        icon: Icons.star_rounded,
        title: 'Star Collector',
        description: 'Earn 100 stars',
        isUnlocked: false,
        gradient: AppColors.sunsetGradient,
      ),
      _Achievement(
        icon: Icons.quiz_rounded,
        title: 'Quiz Master',
        description: 'Complete 10 quizzes',
        isUnlocked: false,
        gradient: AppColors.mintGradient,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.spacingM,
        mainAxisSpacing: AppConstants.spacingM,
        childAspectRatio: 1.2,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _AchievementCard(achievement: achievement);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final IconData icon;
  final String title;
  final String description;
  final bool isUnlocked;
  final LinearGradient gradient;

  const _Achievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.gradient,
  });
}

class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: achievement.isUnlocked ? achievement.gradient : null,
              color: achievement.isUnlocked
                  ? null
                  : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked
                  ? Colors.white
                  : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              size: 24,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            achievement.title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: achievement.isUnlocked ? null : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            achievement.description,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
