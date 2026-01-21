import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final banners = ref.watch(featuredBannersProvider);
    final letters = ref.watch(lettersProvider);
    final lessons = ref.watch(lessonsProvider);
    final quizzes = ref.watch(quizzesProvider);
    final mediaFiles = ref.watch(mediaFilesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Premium animated background
          _buildPremiumBackground(isDark, size),
          
          // Floating orbs
          ..._buildFloatingOrbs(size),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isWideScreen ? 32 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Header
                  _buildPremiumHeader(context, isDark)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.3, curve: Curves.easeOutQuart),

                  const SizedBox(height: 36),

                  // Live Stats Grid with animations
                  _buildLiveStatsGrid(
                    context,
                    categories.length,
                    banners.length,
                    letters.length,
                    lessons.length,
                    quizzes.length,
                    mediaFiles.length,
                    isDark,
                    isWideScreen,
                  ),

                  const SizedBox(height: 36),

                  // Quick Actions with glow effects
                  _buildQuickActionsSection(context, isDark, isWideScreen),

                  const SizedBox(height: 36),

                  // Content Management with hover animations
                  _buildContentSection(context, isDark, isWideScreen),

                  const SizedBox(height: 36),

                  // Media Upload Zone
                  _buildPremiumMediaSection(context, isDark, isWideScreen),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground(bool isDark, Size size) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0A0E14), const Color(0xFF0D1117), const Color(0xFF161B22)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), Colors.white],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        
        // Mesh gradient effect
        Positioned(
          top: -size.height * 0.3,
          right: -size.width * 0.3,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15 + _pulseController.value * 0.1),
                      AppColors.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Secondary glow
        Positioned(
          bottom: -size.height * 0.2,
          left: -size.width * 0.2,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentPurple.withValues(alpha: 0.12 + (1 - _pulseController.value) * 0.08),
                      AppColors.accentPurple.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Noise texture overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFloatingOrbs(Size size) {
    return [
      // Floating orb 1
      AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Positioned(
            top: 100 + math.sin(_floatController.value * math.pi) * 20,
            right: 50 + math.cos(_floatController.value * math.pi) * 15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.premiumGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      
      // Floating orb 2
      AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Positioned(
            top: 300 + math.cos(_floatController.value * math.pi * 1.5) * 25,
            left: 30 + math.sin(_floatController.value * math.pi * 1.5) * 10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.premiumPurple,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.4),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildPremiumHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin badge with glow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ADMIN CONTROL CENTER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Main title with gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark 
                ? [Colors.white, Colors.white70]
                : [const Color(0xFF1A1A2E), const Color(0xFF3D3D5C)],
          ).createShader(bounds),
          child: const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your Olitun learning content',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatsGrid(
    BuildContext context,
    int categories,
    int banners,
    int letters,
    int lessons,
    int quizzes,
    int mediaFiles,
    bool isDark,
    bool isWideScreen,
  ) {
    final stats = [
      _StatData('Categories', '$categories', Icons.category_rounded, AppColors.premiumGreen, '/admin/categories'),
      _StatData('Banners', '$banners', Icons.featured_play_list_rounded, AppColors.premiumPurple, '/admin/banners'),
      _StatData('Letters', '$letters', Icons.text_fields_rounded, AppColors.premiumMint, '/admin/letters'),
      _StatData('Lessons', '$lessons', Icons.school_rounded, AppColors.premiumCyan, '/admin/lessons'),
      _StatData('Quizzes', '$quizzes', Icons.quiz_rounded, AppColors.premiumPink, '/admin/quizzes'),
      _StatData('Media', '$mediaFiles', Icons.perm_media_rounded, AppColors.premiumOrange, '/admin/media'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Live Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWideScreen ? 6 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isWideScreen ? 1.2 : 1.0,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return _PremiumStatCard(
              data: stats[index],
              isDark: isDark,
              delay: index * 80,
              onTap: () => context.go(stats[index].route),
            ).animate().fadeIn(
              delay: (200 + index * 80).ms,
              duration: 500.ms,
            ).scale(
              begin: const Offset(0.8, 0.8),
              delay: (200 + index * 80).ms,
              duration: 500.ms,
              curve: Curves.easeOutBack,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, bool isDark, bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppColors.premiumPurple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _GlowingActionChip(
              icon: Icons.add_circle_outline_rounded,
              label: 'New Category',
              gradient: AppColors.premiumGreen,
              onTap: () => context.go('/admin/categories'),
            ),
            _GlowingActionChip(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Add Banner',
              gradient: AppColors.premiumPurple,
              onTap: () => context.go('/admin/banners'),
            ),
            _GlowingActionChip(
              icon: Icons.abc_rounded,
              label: 'Add Letter',
              gradient: AppColors.premiumMint,
              onTap: () => context.go('/admin/letters'),
            ),
            _GlowingActionChip(
              icon: Icons.school_outlined,
              label: 'New Lesson',
              gradient: AppColors.premiumCyan,
              onTap: () => context.go('/admin/lessons'),
            ),
            _GlowingActionChip(
              icon: Icons.quiz_outlined,
              label: 'Create Quiz',
              gradient: AppColors.premiumPink,
              onTap: () => context.go('/admin/quizzes'),
            ),
            _GlowingActionChip(
              icon: Icons.cloud_upload_rounded,
              label: 'Upload Media',
              gradient: AppColors.premiumOrange,
              onTap: () => context.go('/admin/media'),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
  }

  Widget _buildContentSection(BuildContext context, bool isDark, bool isWideScreen) {
    final items = [
      _ContentItemData(
        'Categories',
        'Organize learning modules',
        Icons.category_rounded,
        AppColors.premiumGreen,
        '/admin/categories',
        '4 active',
      ),
      _ContentItemData(
        'Featured Banners',
        'Home screen promotions',
        Icons.featured_play_list_rounded,
        AppColors.premiumPurple,
        '/admin/banners',
        '1 active',
      ),
      _ContentItemData(
        'Letters & Alphabet',
        'Ol Chiki script library',
        Icons.text_fields_rounded,
        AppColors.premiumMint,
        '/admin/letters',
        '12 letters',
      ),
      _ContentItemData(
        'Lessons',
        'Educational content',
        Icons.school_rounded,
        AppColors.premiumCyan,
        '/admin/lessons',
        '3 lessons',
      ),
      _ContentItemData(
        'Quizzes',
        'Interactive assessments',
        Icons.quiz_rounded,
        AppColors.premiumPink,
        '/admin/quizzes',
        '1 quiz',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppColors.premiumCyan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Content Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...items.asMap().entries.map((entry) {
          return _HoverContentCard(
            data: entry.value,
            isDark: isDark,
            onTap: () => context.go(entry.value.route),
          ).animate().fadeIn(
            delay: (700 + entry.key * 100).ms,
            duration: 400.ms,
          ).slideX(begin: -0.1);
        }),
      ],
    );
  }

  Widget _buildPremiumMediaSection(BuildContext context, bool isDark, bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Media Library',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/admin/media'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_upload_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Upload',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => context.go('/admin/media'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.04),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.7),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Animated upload icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGreen,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: 0, end: -8, duration: 1500.ms, curve: Curves.easeInOut),
                    const SizedBox(height: 28),
                    Text(
                      'Drop files here or click to upload',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Supports images, audio, and video files',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MediaTypeTag(icon: Icons.image_rounded, label: 'PNG/JPG/GIF', gradient: AppColors.premiumGreen),
                        const SizedBox(width: 12),
                        _MediaTypeTag(icon: Icons.audiotrack_rounded, label: 'MP3/WAV', gradient: AppColors.premiumPurple),
                        const SizedBox(width: 12),
                        _MediaTypeTag(icon: Icons.videocam_rounded, label: 'MP4/MOV', gradient: AppColors.premiumOrange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 900.ms, duration: 500.ms);
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final String route;

  _StatData(this.label, this.value, this.icon, this.gradient, this.route);
}

class _PremiumStatCard extends StatefulWidget {
  final _StatData data;
  final bool isDark;
  final int delay;
  final VoidCallback onTap;

  const _PremiumStatCard({
    required this.data,
    required this.isDark,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_PremiumStatCard> createState() => _PremiumStatCardState();
}

class _PremiumStatCardState extends State<_PremiumStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered 
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: widget.data.gradient,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: (widget.data.gradient as LinearGradient).colors.first.withValues(alpha: 0.5),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: (widget.data.gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
                            blurRadius: 15,
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.data.icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      widget.data.value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.data.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _GlowingActionChip({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_GlowingActionChip> createState() => _GlowingActionChipState();
}

class _GlowingActionChipState extends State<_GlowingActionChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: (widget.gradient as LinearGradient).colors.first.withValues(alpha: 0.5),
                      blurRadius: 25,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: (widget.gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String route;
  final String badge;

  _ContentItemData(this.title, this.subtitle, this.icon, this.gradient, this.route, this.badge);
}

class _HoverContentCard extends StatefulWidget {
  final _ContentItemData data;
  final bool isDark;
  final VoidCallback onTap;

  const _HoverContentCard({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HoverContentCard> createState() => _HoverContentCardState();
}

class _HoverContentCardState extends State<_HoverContentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: _isHovered 
                ? (Matrix4.identity()..translate(-4.0, 0))
                : Matrix4.identity(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: _isHovered ? 0.1 : 0.06)
                        : Colors.white.withValues(alpha: _isHovered ? 1 : 0.9),
                    border: Border.all(
                      color: _isHovered
                          ? (widget.data.gradient as LinearGradient).colors.first.withValues(alpha: 0.5)
                          : (widget.isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05)),
                      width: _isHovered ? 2 : 1,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: (widget.data.gradient as LinearGradient).colors.first.withValues(alpha: 0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: widget.data.gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (widget.data.gradient as LinearGradient).colors.first.withValues(alpha: 0.4),
                              blurRadius: _isHovered ? 20 : 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(widget.data.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.data.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (widget.data.gradient as LinearGradient).colors.first.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.data.badge,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: (widget.data.gradient as LinearGradient).colors.first,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.data.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: widget.isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? (widget.data.gradient as LinearGradient).colors.first.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: _isHovered
                              ? (widget.data.gradient as LinearGradient).colors.first
                              : AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaTypeTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;

  const _MediaTypeTag({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: (gradient as LinearGradient).colors.first),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
