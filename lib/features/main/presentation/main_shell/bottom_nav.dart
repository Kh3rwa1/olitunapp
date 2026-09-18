part of 'main_shell_screen.dart';

// Mobile shell layout: page stack, readability scrim and the floating
// glass bottom navigation, extracted from [_MainShellScreenState] into
// this library part.

extension _MainShellBottomNavLayout on _MainShellScreenState {
  Widget _buildMobileLayout(bool isDark, bool isTablet, int selectedIndex) {
    // Tablets keep the bottom-nav UX (no sidebar below 1100dp) but the bar
    // is centered and width-constrained so it stays thumb-reachable on
    // 8–11" screens instead of stretching edge-to-edge.
    final nav = GlassicBottomNav(
      selectedIndex: selectedIndex,
      onItemTapped: _onItemTapped,
      isDark: isDark,
      isTablet: isTablet,
    );
    return Stack(
      children: [
        ShellAmbientBackground(
          isDark: isDark,
          shouldAnimate: selectedIndex == 0 && _isAppActive,
        ),
        widget.navigationShell,
        // Readability scrim: fades page content out beneath the floating
        // glass nav so text never collides with it.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _scrimBaseColor(isDark).withValues(alpha: 0),
                    _scrimBaseColor(isDark).withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Bottom nav: full-bleed on phones, centered width-constrained pill
        // on tablets. GlassicBottomNav already offsets for viewPadding.bottom
        // (notch / gesture bar), so no extra SafeArea here to avoid doubling
        // the inset on iPhones.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: isTablet
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: nav,
                  ),
                )
              : nav,
        ),
      ],
    );
  }

  Color _scrimBaseColor(bool isDark) {
    return isDark ? AppColors.santaliNightSkyDark : AppColors.lightScrimBase;
  }
}
