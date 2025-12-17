import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/providers/providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final banners = ref.watch(featuredBannersProvider);
    final letters = ref.watch(lettersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isWideScreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              leading: CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.go('/home'),
              ),
              title: const Text('Admin Panel'),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWideScreen) ...[
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Manage your Olitun app content',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),
              ],

              // Stats cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWideScreen ? 4 : 2,
                crossAxisSpacing: AppConstants.spacingM,
                mainAxisSpacing: AppConstants.spacingM,
                childAspectRatio: isWideScreen ? 1.5 : 1.2,
                children: [
                  _StatCard(
                    icon: Icons.category_rounded,
                    label: 'Categories',
                    value: categories.when(
                      data: (list) => list.length.toString(),
                      loading: () => '-',
                      error: (_, __) => '0',
                    ),
                    gradient: AppColors.skyBlueGradient,
                    onTap: () => context.go('/admin/categories'),
                  ),
                  _StatCard(
                    icon: Icons.featured_play_list_rounded,
                    label: 'Banners',
                    value: banners.when(
                      data: (list) => list.length.toString(),
                      loading: () => '-',
                      error: (_, __) => '0',
                    ),
                    gradient: AppColors.peachGradient,
                    onTap: () => context.go('/admin/banners'),
                  ),
                  _StatCard(
                    icon: Icons.text_fields_rounded,
                    label: 'Letters',
                    value: letters.when(
                      data: (list) => list.length.toString(),
                      loading: () => '-',
                      error: (_, __) => '0',
                    ),
                    gradient: AppColors.mintGradient,
                    onTap: () => context.go('/admin/letters'),
                  ),
                  _StatCard(
                    icon: Icons.school_rounded,
                    label: 'Lessons',
                    value: '-',
                    gradient: AppColors.sunsetGradient,
                    onTap: () => context.go('/admin/lessons'),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Quick actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.spacingM),

              Wrap(
                spacing: AppConstants.spacingM,
                runSpacing: AppConstants.spacingM,
                children: [
                  _ActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Add Category',
                    onTap: () => context.go('/admin/categories'),
                  ),
                  _ActionButton(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Add Banner',
                    onTap: () => context.go('/admin/banners'),
                  ),
                  _ActionButton(
                    icon: Icons.abc_rounded,
                    label: 'Add Letter',
                    onTap: () => context.go('/admin/letters'),
                  ),
                  _ActionButton(
                    icon: Icons.quiz_outlined,
                    label: 'Add Quiz',
                    onTap: () => context.go('/admin/quizzes'),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Mobile navigation (when not wide screen)
              if (!isWideScreen) ...[
                Text(
                  'Content Management',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppConstants.spacingM),
                _NavCard(
                  icon: Icons.category_rounded,
                  title: 'Categories',
                  subtitle: 'Manage learning categories',
                  gradient: AppColors.skyBlueGradient,
                  onTap: () => context.go('/admin/categories'),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _NavCard(
                  icon: Icons.featured_play_list_rounded,
                  title: 'Featured Banners',
                  subtitle: 'Manage home screen banners',
                  gradient: AppColors.peachGradient,
                  onTap: () => context.go('/admin/banners'),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _NavCard(
                  icon: Icons.text_fields_rounded,
                  title: 'Letters',
                  subtitle: 'Manage Ol Chiki alphabet',
                  gradient: AppColors.mintGradient,
                  onTap: () => context.go('/admin/letters'),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _NavCard(
                  icon: Icons.school_rounded,
                  title: 'Lessons',
                  subtitle: 'Manage lesson content',
                  gradient: AppColors.sunsetGradient,
                  onTap: () => context.go('/admin/lessons'),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _NavCard(
                  icon: Icons.quiz_rounded,
                  title: 'Quizzes',
                  subtitle: 'Manage quiz questions',
                  gradient: AppColors.purpleGradient,
                  onTap: () => context.go('/admin/quizzes'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: gradient,
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryCyan, size: 20),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ],
      ),
    );
  }
}
