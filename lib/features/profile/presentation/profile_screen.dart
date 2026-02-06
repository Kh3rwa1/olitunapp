import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch adaptors for user stats
    final userName = ref.watch(userNameProvider);
    final streak = ref.watch(userStreakProvider);
    final stars = ref.watch(userStarsProvider);
    final lessonsCompleted = ref.watch(lessonsCompletedProvider);
    final quizzesCompleted = ref.watch(quizzesCompletedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppColors.primary.withValues(alpha: 0.2),
                            Theme.of(context).scaffoldBackgroundColor,
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.1),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.accentCyan,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: () =>
                                _showEditNameDialog(context, ref, isDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats Grid
                  _buildStatsGrid(
                    streak,
                    stars,
                    lessonsCompleted,
                    quizzesCompleted,
                    isDark,
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  _buildActionsList(context, ref, isDark),

                  const SizedBox(height: 32),

                  // Sign Out
                  _buildSignOutButton(context, ref),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    int streak,
    int stars,
    int lessons,
    int quizzes,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: 'Day Streak',
                gradient: AppColors.premiumOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                value: '$stars',
                label: 'Stars',
                gradient: AppColors.premiumGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.book_rounded,
                value: '$lessons',
                label: 'Lessons',
                gradient: AppColors.premiumCyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.quiz_rounded,
                value: '$quizzes',
                label: 'Quizzes',
                gradient: AppColors.premiumPink,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildActionsList(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.edit_rounded,
          label: 'Edit Profile',
          onTap: () => _showEditNameDialog(context, ref, isDark),
          isDark: isDark,
        ),
        _ActionTile(
          icon: Icons.settings_rounded,
          label: 'Settings',
          onTap: () => context.go('/profile/settings'),
          isDark: isDark,
        ),

        _ActionTile(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () {},
          isDark: isDark,
        ),
        _ActionTile(
          icon: Icons.info_outline_rounded,
          label: 'About',
          onTap: () {},
          isDark: isDark,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Clear local user data (no auth in local storage mode)
          if (context.mounted) {
            context.go('/welcome');
          }
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final controller = TextEditingController(text: ref.read(userNameProvider));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Name',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                updateUserName(ref, controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Gradient gradient;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withValues(
              alpha: 0.3,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
