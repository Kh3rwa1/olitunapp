import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../../shared/providers/providers.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isAdmin.when(
      data: (admin) {
        if (!admin) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'Access Denied',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    'You don\'t have admin privileges',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }

        final isWideScreen = MediaQuery.of(context).size.width > 800;

        if (isWideScreen) {
          // Web/Desktop layout with sidebar
          return Scaffold(
            body: Row(
              children: [
                // Sidebar
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: _AdminSidebar(),
                ),
                // Main content
                Expanded(
                  child: BubbleBackground(
                    child: child,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout
          return BubbleBackground(child: child);
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppConstants.spacingM),
              const Text('Failed to verify admin access'),
              const SizedBox(height: AppConstants.spacingM),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'ᱚ',
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olitun Admin',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Content Management',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == '/admin',
                  onTap: () => context.go('/admin'),
                ),
                _NavItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  isSelected: location == '/admin/categories',
                  onTap: () => context.go('/admin/categories'),
                ),
                _NavItem(
                  icon: Icons.featured_play_list_rounded,
                  label: 'Featured Banners',
                  isSelected: location == '/admin/banners',
                  onTap: () => context.go('/admin/banners'),
                ),
                _NavItem(
                  icon: Icons.text_fields_rounded,
                  label: 'Letters',
                  isSelected: location == '/admin/letters',
                  onTap: () => context.go('/admin/letters'),
                ),
                _NavItem(
                  icon: Icons.school_rounded,
                  label: 'Lessons',
                  isSelected: location == '/admin/lessons',
                  onTap: () => context.go('/admin/lessons'),
                ),
                _NavItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  isSelected: location == '/admin/quizzes',
                  onTap: () => context.go('/admin/quizzes'),
                ),
              ],
            ),
          ),

          // Back to app
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: InkWell(
              onTap: () => context.go('/home'),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 20),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Back to App',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryCyan.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primaryCyan : null,
              ),
              const SizedBox(width: AppConstants.spacingM),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryCyan : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
