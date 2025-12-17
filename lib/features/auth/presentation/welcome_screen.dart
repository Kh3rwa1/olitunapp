import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated gradient background
            _buildAnimatedBackground(isDark, size),

            // Floating decorative elements
            _buildFloatingElements(size),

            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // Animated Logo
                    _buildHeroLogo()
                        .animate()
                        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                        ),

                    const SizedBox(height: 32),

                    // App name with premium typography
                    _buildAppTitle(context)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.3, curve: Curves.easeOut),

                    const SizedBox(height: 12),

                    // Tagline
                    _buildTagline(context, isDark)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, curve: Curves.easeOut),

                    const Spacer(),

                    // Feature cards
                    _buildFeatureCards(context, isDark),

                    const SizedBox(height: 48),

                    // CTA Buttons
                    _buildCTAButtons(context)
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 600.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOut),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_gradientController.value * 2 * math.pi),
                math.sin(_gradientController.value * 2 * math.pi),
              ),
              end: Alignment(
                -math.cos(_gradientController.value * 2 * math.pi),
                -math.sin(_gradientController.value * 2 * math.pi),
              ),
              colors: isDark
                  ? [
                      const Color(0xFF0B1120),
                      const Color(0xFF0F172A),
                      const Color(0xFF1E1B4B).withValues(alpha: 0.5),
                    ]
                  : [
                      const Color(0xFFF0FDFA),
                      const Color(0xFFFAFBFC),
                      const Color(0xFFEFF6FF),
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingElements(Size size) {
    return Stack(
      children: [
        // Top right blob
        Positioned(
          top: -100,
          right: -80,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatController.value * 20),
                child: child,
              );
            },
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom left blob
        Positioned(
          bottom: -120,
          left: -100,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatController.value * 15),
                child: child,
              );
            },
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.12),
                    AppColors.accentPurple.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Scattered small orbs
        ...List.generate(6, (index) {
          final random = math.Random(index);
          return Positioned(
            top: random.nextDouble() * size.height * 0.7,
            left: random.nextDouble() * size.width,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_pulseController.value * 0.4),
                  child: Opacity(
                    opacity: 0.3 + (_pulseController.value * 0.3),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 8 + random.nextDouble() * 12,
                height: 8 + random.nextDouble() * 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: [
                    AppColors.primary,
                    AppColors.accentPurple,
                    AppColors.accentPink,
                  ][index % 3]
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHeroLogo() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatController.value * 8),
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: AppColors.heroGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.3 + (_pulseController.value * 0.15),
                  ),
                  blurRadius: 40 + (_pulseController.value * 20),
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Inner glow
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(38),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Logo character
                const Center(
                  child: Text(
                    'ᱚ',
                    style: TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: 72,
                      color: Colors.white,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppTitle(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF111827),
          Color(0xFF374151),
        ],
      ).createShader(bounds),
      child: const Text(
        'Olitun',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTagline(BuildContext context, bool isDark) {
    return Text(
      'Master Ol Chiki. Your way.',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context, bool isDark) {
    final features = [
      _FeatureData(
        icon: Icons.auto_awesome_rounded,
        title: 'AI-Powered',
        subtitle: 'Personalized learning path',
        gradient: AppColors.premiumCyan,
      ),
      _FeatureData(
        icon: Icons.psychology_rounded,
        title: 'Smart Practice',
        subtitle: 'Adaptive quizzes',
        gradient: AppColors.premiumPurple,
      ),
      _FeatureData(
        icon: Icons.emoji_events_rounded,
        title: 'Gamified',
        subtitle: 'Earn rewards & streak',
        gradient: AppColors.premiumOrange,
      ),
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        return _buildFeatureCard(context, feature, isDark)
            .animate()
            .fadeIn(delay: (500 + index * 100).ms, duration: 500.ms)
            .slideX(begin: -0.1, curve: Curves.easeOut);
      }).toList(),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, _FeatureData feature, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.7),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              children: [
                // Icon container with gradient
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: feature.gradient,
                    boxShadow: AppColors.glowShadow(
                      (feature.gradient as LinearGradient).colors.first,
                    ),
                  ),
                  child: Icon(
                    feature.icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
          ),
        ),
      ),
    );
  }

  Widget _buildCTAButtons(BuildContext context) {
    return Column(
      children: [
        // Primary CTA
        _PremiumButton(
          text: 'Start Learning Free',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pushNamed('signUp');
          },
          isPrimary: true,
        ),

        const SizedBox(height: 12),

        // Secondary CTA
        _PremiumButton(
          text: 'I have an account',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pushNamed('signIn');
          },
          isPrimary: false,
        ),

        const SizedBox(height: 24),

        // Trust indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_rounded,
              size: 16,
              color: AppColors.success,
            ),
            const SizedBox(width: 6),
            Text(
              'Join 50,000+ learners',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _PremiumButton({
    required this.text,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isPrimary ? AppColors.heroGradient : null,
            color: widget.isPrimary
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05)),
            boxShadow: widget.isPrimary ? AppColors.buttonShadow : null,
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: widget.isPrimary
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
