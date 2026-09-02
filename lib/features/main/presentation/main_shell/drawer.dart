part of 'main_shell_screen.dart';

// Desktop shell layout: left navigation drawer (sidebar), centered
// content column and the right stats panel, extracted from
// [_MainShellScreenState] into this library part.

extension _MainShellDrawerLayout on _MainShellScreenState {
  Widget _buildDesktopLayout(bool isDark, int selectedIndex) {
    return Row(
      children: [
        // Left Sidebar Navigation
        DesktopSidebar(
          selectedIndex: selectedIndex,
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
                ShellAmbientBackground(
                  isDark: isDark,
                  shouldAnimate: selectedIndex == 0 && _isAppActive,
                ),
                SafeArea(child: widget.navigationShell),
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
        DesktopRightPanel(isDark: isDark),
      ],
    );
  }
}
