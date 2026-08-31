import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/layout/responsive_layout.dart';
import '../../../../shared/providers/providers.dart';
import 'widgets/desktop_right_panel.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/glassic_bottom_nav.dart';
import 'widgets/shell_ambient_background.dart';

@visibleForTesting
int? shellTabIndexForPath(String path) {
  if (path == '/' || path == '/categories') return 0;
  if (path == '/bakhed') return 1;
  if (path == '/profile') return 2;
  return null;
}

class MainShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with WidgetsBindingObserver {
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

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    ref.read(shellTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final currentIndex = widget.navigationShell.currentIndex;

    // Keep shellTabIndexProvider in sync with GoRouter branch changes
    ref.listen<int>(shellTabIndexProvider, (prev, next) {
      if (next != widget.navigationShell.currentIndex) {
        widget.navigationShell.goBranch(next);
      }
    });

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex > 0) {
          widget.navigationShell.goBranch(0);
          ref.read(shellTabIndexProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0E1A)
            : const Color(0xFFF5F7FA),
        body: isDesktop
            ? _buildDesktopLayout(isDark, currentIndex)
            : _buildMobileLayout(isDark, isTablet, currentIndex),
      ),
    );
  }

  // ============== DESKTOP LAYOUT ==============
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

  // ============== MOBILE LAYOUT ==============
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
    return isDark ? const Color(0xFF121A2B) : const Color(0xFFF8FAFF);
  }
}
