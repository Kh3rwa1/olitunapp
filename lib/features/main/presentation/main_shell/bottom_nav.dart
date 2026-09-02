part of 'main_shell_screen.dart';

// Mobile shell layout: page stack, readability scrim and the floating
// glass bottom navigation, extracted from [_MainShellScreenState] into
// this library part.

extension _MainShellBottomNavLayout on _MainShellScreenState {
  Widget _buildMobileLayout(bool isDark, bool isTablet, int selectedIndex) {
    return Stack(
      children: [
        ShellAmbientBackground(
          isDark: isDark,
          shouldAnimate: selectedIndex == 0 && _isAppActive,
        ),
        widget.navigationShell,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Stack(
            children: [
              // Readability scrim: fades page content out beneath the
              // floating glass nav so text never collides with it.
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
              GlassicBottomNav(
                selectedIndex: selectedIndex,
                onItemTapped: _onItemTapped,
                isDark: isDark,
                isTablet: isTablet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _scrimBaseColor(bool isDark) {
    return isDark ? AppColors.santaliNightSkyDark : AppColors.lightScrimBase;
  }
}
