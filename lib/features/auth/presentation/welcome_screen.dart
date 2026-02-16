import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildBackground(isDark, size),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo and branding
                  _buildLogo()
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 28),

                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ).createShader(bounds),
                    child: const Text(
                      'Olitun',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        color: Colors.white,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                  const SizedBox(height: 12),

                  Text(
                    'Learn Ol Chiki Script',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                  const Spacer(flex: 2),

                  // Features
                  _buildFeatureCards(isDark),

                  const Spacer(),

                  // CTA Buttons
                  _buildCTAButtons(context, isDark),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark, Size size) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0A0E14), const Color(0xFF161B22)]
                  : [Colors.white, const Color(0xFFF0FDF4)],
            ),
          ),
        ),
        // Floating orbs
        Positioned(
          top: -size.height * 0.15,
          right: -size.width * 0.25,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.1,
          left: -size.width * 0.2,
          child: Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accentPurple.withValues(alpha: 0.15),
                  AppColors.accentPurple.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Image.asset(
          'assets/icons/olitun_logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text(
              'ᱚ',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCards(bool isDark) {
    final features = [
      _FeatureData(Icons.auto_awesome_rounded, 'Interactive', 'Learn by doing'),
      _FeatureData(Icons.school_rounded, 'Structured', 'Step-by-step lessons'),
      _FeatureData(Icons.emoji_events_rounded, 'Gamified', 'Earn rewards'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features.asMap().entries.map((entry) {
        final feature = entry.value;
        return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: entry.key == 0 ? 0 : 8,
                  right: entry.key == features.length - 1 ? 0 : 8,
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        feature.icon,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feature.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: (600 + entry.key * 100).ms, duration: 400.ms)
            .slideY(begin: 0.2);
      }).toList(),
    );
  }

  Widget _buildCTAButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Start Learning Button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/auth');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Start Learning',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 800.ms, duration: 500.ms).slideY(begin: 0.3),

        const SizedBox(height: 16),

        // Login link
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/auth');
          },
          child: RichText(
            text: TextSpan(
              text: "Already have an account? ",
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: "Sign In",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
      ],
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;

  _FeatureData(this.icon, this.title, this.subtitle);
}
