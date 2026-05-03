import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/presentation/home_screen.dart';
import '../../rhymes/presentation/rhyme_screen.dart';
import '../../profile/presentation/progress_screen.dart';
import '../../profile/presentation/settings_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../../../shared/providers/providers.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppActive = state == AppLifecycleState.resumed;
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const RhymeScreen(),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    ref.read(shellTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    // Listen for external tab change requests (e.g. from ProgressScreen "Settings" tile)
    ref.listen<int>(shellTabIndexProvider, (prev, next) {
      if (next != _selectedIndex) {
        setState(() {
          _selectedIndex = next;
        });
      }
    });

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex > 0) {
          setState(() {
            _selectedIndex = 0;
          });
          ref.read(shellTabIndexProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0E1A)
            : const Color(0xFFF5F7FA),
        body: isDesktop
            ? _buildDesktopLayout(isDark)
            : _buildMobileLayout(isDark, isTablet),
      ),
    );
  }

  // ============== DESKTOP LAYOUT ==============
  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      children: [
        // Left Sidebar Navigation
        _DesktopSidebar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          isDark: isDark,
        ),

        // Subtle vertical divider
        Container(
          width: 1,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),

        // Center Content — clipped so child screens don't bleed behind sidebars
        Expanded(
          child: ClipRect(
            child: Stack(
              children: [
                _buildPremiumBackground(isDark),
                SafeArea(
                  child: _ShellTabSwitcher(
                    index: _selectedIndex,
                    screens: _screens,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Subtle vertical divider
        Container(
          width: 1,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),

        // Right Sidebar (Stats Panel)
        _DesktopRightPanel(isDark: isDark),
      ],
    );
  }

  // ============== MOBILE LAYOUT ==============
  Widget _buildMobileLayout(bool isDark, bool isTablet) {
    return Stack(
      children: [
        _buildPremiumBackground(isDark),
        SafeArea(
          bottom: false,
          child: _ShellTabSwitcher(
            index: _selectedIndex,
            screens: _screens,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildGlassicNav(isDark, isTablet),
        ),
      ],
    );
  }

  Widget _buildPremiumBackground(bool isDark) {
    // Only animate particles when home tab is active and app is in foreground
    final shouldAnimate = _selectedIndex == 0 && _isAppActive;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF0A0E1A),
                        Color(0xFF121A2B),
                        Color(0xFF1E2A44),
                      ]
                    : const [
                        Color(0xFFF3F8FF),
                        Color(0xFFF8FAFF),
                        Color(0xFFE8F0FF),
                      ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: EnchantedVisualizer(
            isPlaying: shouldAnimate,
            color: AppColors.primary,
            showWaves: false,
            showParticles: true,
            height: 400,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassicNav(bool isDark, bool isTablet) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 32 : 24,
        0,
        isTablet ? 32 : 24,
        MediaQuery.of(context).viewPadding.bottom + (isTablet ? 20 : 15),
      ),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(
                alpha: 0.6,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.15,
                ),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.music_note_rounded, 'Rhymes'),
                _buildNavItem(2, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0.0,
      duration: 800.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _onItemTapped(index);
        HapticFeedback.lightImpact();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
                duration: 400.ms,
                padding: const EdgeInsets.all(10),
                curve: Curves.easeOutBack,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white54 : Colors.black45),
                  size: isSelected ? 30 : 26,
                ),
              )
              .animate(target: isSelected ? 1 : 0)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
              ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== DESKTOP LEFT SIDEBAR ==============

class _DesktopSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final bool isDark;

  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: ResponsiveLayout.leftSidebarWidth,
      color: isDark ? const Color(0xFF0D1117) : Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Logo / Brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'ᱚ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Olitun',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Nav Items
          _SidebarNavItem(
            icon: Icons.home_rounded,
            label: 'Learn',
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
            isDark: isDark,
          ),
          _SidebarNavItem(
            icon: Icons.music_note_rounded,
            label: 'Rhymes',
            isSelected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
            isDark: isDark,
          ),
          _SidebarNavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
            isDark: isDark,
          ),

          const Spacer(),

          // Dark/Light Mode Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.04,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isCurrentlyDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 20,
                    color: isDark
                        ? Colors.amber.shade300
                        : Colors.orange.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCurrentlyDark ? 'Dark' : 'Light',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: isCurrentlyDark,
                      onChanged: (val) {
                        updateThemeMode(ref, val ? 'dark' : 'light');
                      },
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.3,
                      ),
                      inactiveThumbColor: Colors.orange.shade400,
                      inactiveTrackColor: Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Settings at bottom
          _SidebarNavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isSelected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
            isDark: isDark,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    final hovered = _isHovered && !isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : hovered
                  ? (widget.isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.04,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.15))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: isActive
                      ? AppColors.primary
                      : widget.isDark
                      ? Colors.white54
                      : Colors.black45,
                ),
                const SizedBox(width: 14),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : widget.isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============== DESKTOP RIGHT PANEL ==============

class _DesktopRightPanel extends ConsumerWidget {
  final bool isDark;

  const _DesktopRightPanel({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final streak = statsAsync.value?.currentStreak ?? 0;
    final stars = ref.watch(userStarsProvider);
    final lessonsCompleted = ref.watch(lessonsCompletedProvider);
    final learningTime = statsAsync.value?.totalLearningMinutes ?? 0;
    final userName = ref.watch(userNameProvider);

    return Container(
      width: ResponsiveLayout.rightSidebarWidth,
      color: isDark ? const Color(0xFF0D1117) : Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // User Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primaryDark.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'L',
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Santali Learner',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Section
            Text(
              'YOUR STATS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 14),

            _RightPanelStat(
              icon: Icons.local_fire_department_rounded,
              label: 'Day Streak',
              value: '$streak',
              color: AppColors.duoOrange,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _RightPanelStat(
              icon: Icons.star_rounded,
              label: 'Stars Earned',
              value: '$stars',
              color: AppColors.duoYellow,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _RightPanelStat(
              icon: Icons.emoji_events_rounded,
              label: 'Lessons Done',
              value: '$lessonsCompleted',
              color: AppColors.primary,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _RightPanelStat(
              icon: Icons.timer_rounded,
              label: 'Learning Time',
              value: '${learningTime}m',
              color: AppColors.duoBlue,
              isDark: isDark,
            ),

            const SizedBox(height: 28),

            // Daily Goal Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.06,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Goal',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (lessonsCompleted % 3) / 3,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${lessonsCompleted % 3}/3 lessons today',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RightPanelStat extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _RightPanelStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  State<_RightPanelStat> createState() => _RightPanelStatState();
}

class _RightPanelStatState extends State<_RightPanelStat> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? Matrix4.diagonal3Values(1.02, 1.02, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04))
              : (widget.isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.2)
                : (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-fade switcher: all tabs stay mounted (so scroll/form state
/// is preserved per [IndexedStack] semantics); active tab fades in
/// while previous fades out. Inactive tabs ignore pointers. Honors
/// reduce-motion.
class _ShellTabSwitcher extends StatelessWidget {
  const _ShellTabSwitcher({required this.index, required this.screens});

  final int index;
  final List<Widget> screens;

  @override
  Widget build(BuildContext context) {
    final reduce =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final dur = Duration(milliseconds: reduce ? 1 : 220);
    return Stack(
      children: List.generate(screens.length, (i) {
        final active = i == index;
        return IgnorePointer(
          ignoring: !active,
          child: AnimatedOpacity(
            duration: dur,
            curve: Curves.easeOutCubic,
            opacity: active ? 1.0 : 0.0,
            child: KeyedSubtree(
              key: PageStorageKey<int>('shell-tab-$i'),
              child: screens[i],
            ),
          ),
        );
      }),
    );
  }
}
