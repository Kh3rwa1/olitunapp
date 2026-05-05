import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/providers.dart';

/// Wraps a child widget with auth protection.
/// Shows a login prompt if the user is not authenticated.
class AuthGate extends ConsumerWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final IconData icon;

  const AuthGate({
    super.key,
    required this.child,
    this.title = 'Login Required',
    this.subtitle = 'Sign in to unlock this feature and track your progress.',
    this.icon = Icons.lock_rounded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(isAuthenticatedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return authAsync.when(
      data: (isAuthenticated) {
        if (isAuthenticated) return child;
        return _buildLoginPrompt(context, isDark);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildLoginPrompt(context, isDark),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),

            const SizedBox(height: 28),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            SizedBox(
              width: 300,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Login button
            GestureDetector(
              onTap: () => context.go('/welcome'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.glowShadow(AppColors.primary),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
