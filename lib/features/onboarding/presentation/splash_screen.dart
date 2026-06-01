import 'package:itun/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../auth/presentation/providers/auth_providers.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    AppLogger.debug('Splash: starting _navigateToNext');
    final startTime = DateTime.now();
    String? targetLocation;

    try {
      // 1. Check for OAuth token in URL params (after Google sign-in redirect on web)
      if (kIsWeb) {
        final uri = Uri.base;
        var userId = uri.queryParameters['userId'] ?? uri.queryParameters['key'];
        var secret = uri.queryParameters['secret'];

        if (userId == null || secret == null) {
          try {
            final routerState = GoRouterState.of(context);
            userId ??= routerState.uri.queryParameters['userId'] ??
                routerState.uri.queryParameters['key'];
            secret ??= routerState.uri.queryParameters['secret'];
          } catch (e) {
            AppLogger.debug('Splash: Could not read GoRouter state: $e');
          }
        }

        if (userId != null && secret != null) {
          AppLogger.debug(
            'Splash: Found OAuth token (userId: $userId), exchanging for session...',
          );
          final authService = ref.read(appwriteAuthServiceProvider);
          final success = await authService.exchangeOAuthToken(userId, secret);
          if (success) {
            AppLogger.debug('Splash: OAuth token exchange succeeded, navigating to /');
            ref.read(onboardingProvider.notifier).completeOnboarding();
            ref.invalidate(isAuthenticatedProvider);
            targetLocation = '/';
          } else {
            AppLogger.debug('Splash: OAuth token exchange failed');
          }
        }
      }

      if (targetLocation == null) {
        // 2. Check authentication before onboarding
        AppLogger.debug('Splash: checking auth status...');
        final authRepo = ref.read(authRepositoryProvider);
        bool isLoggedIn = false;
        try {
          final isLoggedInResult = await authRepo.isLoggedIn().timeout(
            const Duration(seconds: 4),
          );
          isLoggedIn = isLoggedInResult.getOrElse((_) => false);
        } catch (_) {
          AppLogger.debug('Splash: auth check timed out, treating as logged out');
        }
        AppLogger.debug('Splash: isLoggedIn = $isLoggedIn');

        if (isLoggedIn) {
          ref.read(onboardingProvider.notifier).completeOnboarding();
          targetLocation = '/';
        } else {
          // 3. Desktop/web wide screens skip onboarding entirely
          if (!mounted) return;
          final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width > 900;
          AppLogger.debug('Splash: isDesktopWeb = $isDesktopWeb');

          final showOnboarding = ref.read(onboardingProvider);
          AppLogger.debug('Splash: showOnboarding = $showOnboarding');
          if (showOnboarding && !isDesktopWeb) {
            targetLocation = '/welcome';
          } else if (showOnboarding && isDesktopWeb) {
            AppLogger.debug('Splash: marking onboarding complete for desktop');
            ref.read(onboardingProvider.notifier).completeOnboarding();
            targetLocation = '/welcome';
          } else {
            targetLocation = '/welcome';
          }
        }
      }
    } catch (e) {
      AppLogger.debug('Splash error during check: $e');
    }

    // Enforce a minimum load time of 2.0s so the premium, smooth brand animations have time to breathe
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 2000) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (mounted) {
      context.go(targetLocation ?? '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF030712), // Deepest dark slate/black
                        const Color(0xFF0F172A), // Slate Navy
                        const Color(0xFF052014), // Subtle dark emerald hint matching brand green
                      ]
                    : [
                        const Color(0xFFF8FAF9), // Pristine light grey
                        const Color(0xFFE2F3EC), // Premium soft mint light hint
                        Colors.white,
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Glowing radial background ambient orbs
                if (isDark) ...[
                  Positioned(
                    top: -150,
                    left: -150,
                    right: -150,
                    child: Center(
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.04),
                              blurRadius: 100.0,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.03),
                            blurRadius: 80.0,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Glowing background Ol Chiki alphabet characters (Magical learning space vibe)
                ..._bgLetters.map((letter) {
                  return Positioned(
                    left: letter.x * constraints.maxWidth,
                    top: letter.y * constraints.maxHeight,
                    child: Transform.rotate(
                      angle: letter.rotation,
                      child: Text(
                        letter.char,
                        style: TextStyle(
                          fontFamily: 'OlChiki',
                          fontSize: letter.size,
                          color: (isDark ? Colors.white : const Color(0xFF00C767))
                              .withValues(alpha: isDark ? 0.05 : 0.04),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .fade(begin: 0.3, end: 1.0, duration: 4.seconds, delay: letter.delay)
                        .scaleXY(begin: 0.9, end: 1.1, duration: 4.seconds, curve: Curves.easeInOut),
                  );
                }),

                // Central interactive brand container
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Double-layered premium card layout (Glass outer ring + solid branding card)
                      Container(
                        width: 154,
                        height: 154,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF1E293B).withValues(alpha: 0.2) 
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(44),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/icons/olitun_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .scale(
                            duration: 1000.ms,
                            curve: Curves.easeOutBack,
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                          )
                          .fadeIn(duration: 800.ms)
                          .shimmer(delay: 1200.ms, duration: 1800.ms, color: AppColors.primaryLight.withValues(alpha: 0.35))
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scaleXY(begin: 1.0, end: 1.03, duration: 2500.ms, curve: Curves.easeInOut),

                      const SizedBox(height: 48),

                      // Brand App Name with premium linear ShaderMask gradient
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isDark
                              ? [Colors.white, AppColors.primaryLight]
                              : [const Color(0xFF0F172A), AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'OLITUN',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 12,
                            color: Colors.white,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic, duration: 600.ms),

                      const SizedBox(height: 12),

                      // Premium Subtitle
                      Text(
                        'LEARN OL CHIKI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black45,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic, duration: 600.ms),

                      const SizedBox(height: 72),

                      // Elegant cycling loader and filling progress indicator
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 2000),
                        builder: (context, value, child) {
                          String statusText;
                          if (value < 0.35) {
                            statusText = 'Harmonizing Ol Chiki script...';
                          } else if (value < 0.7) {
                            statusText = 'Synthesizing vocal lessons...';
                          } else if (value < 0.95) {
                            statusText = 'Preparing interactive workspace...';
                          } else {
                            statusText = 'Entering the world of Santali...';
                          }

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white.withValues(alpha: 0.45) : Colors.black54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    width: 180,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  Container(
                                    width: 180 * value,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primary, AppColors.primaryLight],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Background letters positioning details
class _BackgroundLetter {
  final String char;
  final double x;
  final double y;
  final double size;
  final double rotation;
  final Duration delay;

  const _BackgroundLetter({
    required this.char,
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.delay,
  });
}

final List<_BackgroundLetter> _bgLetters = [
  const _BackgroundLetter(char: 'ᱚ', x: 0.08, y: 0.15, size: 40, rotation: 0.2, delay: Duration(milliseconds: 100)),
  const _BackgroundLetter(char: 'ᱛ', x: 0.85, y: 0.12, size: 36, rotation: -0.3, delay: Duration(milliseconds: 300)),
  const _BackgroundLetter(char: 'ᱜ', x: 0.12, y: 0.45, size: 28, rotation: 0.4, delay: Duration(milliseconds: 500)),
  const _BackgroundLetter(char: 'ᱝ', x: 0.82, y: 0.42, size: 32, rotation: -0.15, delay: Duration(milliseconds: 200)),
  const _BackgroundLetter(char: 'ᱞ', x: 0.10, y: 0.72, size: 38, rotation: -0.25, delay: Duration(milliseconds: 600)),
  const _BackgroundLetter(char: 'ᱟ', x: 0.88, y: 0.75, size: 44, rotation: 0.35, delay: Duration(milliseconds: 400)),
  const _BackgroundLetter(char: 'ᱠ', x: 0.48, y: 0.10, size: 30, rotation: -0.1, delay: Duration(milliseconds: 750)),
  const _BackgroundLetter(char: 'ᱡ', x: 0.52, y: 0.86, size: 34, rotation: 0.25, delay: Duration(milliseconds: 800)),
];

