import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import '../../../core/auth/appwrite_auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    debugPrint('Splash: starting _navigateToNext');
    // Wait for animation and pre-fetching
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('Splash: delay finished');

    if (mounted) {
      // Desktop/web wide screens skip onboarding entirely
      final isDesktopWeb = kIsWeb && MediaQuery.of(context).size.width > 900;
      debugPrint('Splash: isDesktopWeb = $isDesktopWeb');

      final showOnboarding = ref.read(onboardingProvider);
      debugPrint('Splash: showOnboarding = $showOnboarding');
      if (showOnboarding && !isDesktopWeb) {
        debugPrint('Splash: navigating to /welcome');
        context.go('/welcome');
        return;
      }

      // If desktop skipped onboarding, mark it as done
      if (showOnboarding && isDesktopWeb) {
        debugPrint('Splash: marking onboarding complete for desktop');
        ref.read(onboardingProvider.notifier).completeOnboarding();
      }

      // Check for OAuth token in URL params (after Google sign-in redirect on web)
      if (kIsWeb) {
        final uri = Uri.base;
        final userId = uri.queryParameters['userId'];
        final secret = uri.queryParameters['secret'];
        if (userId != null && secret != null) {
          debugPrint('Splash: Found OAuth token, exchanging for session...');
          final authService = ref.read(appwriteAuthServiceProvider);
          final success = await authService.exchangeOAuthToken(userId, secret);
          if (success) {
            // Invalidate cached auth state so AuthGate widgets update
            ref.invalidate(isAuthenticatedProvider);
            // Sync user's first name from Google profile
            try {
              final authRepo = ref.read(authRepositoryProvider);
              final userResult = await authRepo.getCurrentUser();
              userResult.fold(
                (_) => null,
                (user) async {
                  if (user != null && (user.name?.isNotEmpty ?? false)) {
                    final firstName = user.name!.split(' ').first;
                    await ref.read(userStatsProvider.notifier).updateName(ref, firstName);
                  }
                },
              );
            } catch (_) {}
            if (!mounted) return;
            context.go('/');
            return;
          }
        }
      }

      // Check authentication status
      debugPrint('Splash: checking auth status...');
      final authRepo = ref.read(authRepositoryProvider);
      final isLoggedInResult = await authRepo.isLoggedIn();
      final isLoggedIn = isLoggedInResult.getOrElse((_) => false);
      debugPrint('Splash: isLoggedIn = $isLoggedIn');

      if (isLoggedIn) {
        if (!mounted) return;
        debugPrint('Splash: navigating to /');
        context.go('/');
      } else {
        if (!mounted) return;
        debugPrint('Splash: navigating to /welcome (not logged in)');
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Animation
            Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),

                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/icons/olitun_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                .scale(
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                )
                .shimmer(delay: 800.ms, duration: 1.5.seconds),

            const SizedBox(height: 48),

            // App Name
            Text(
              'OLITUN',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: isDark ? Colors.white : AppColors.primaryDark,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'LEARN OL CHIKI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
