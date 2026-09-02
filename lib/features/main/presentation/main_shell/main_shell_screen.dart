import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import 'widgets/desktop_right_panel.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/glassic_bottom_nav.dart';
import 'widgets/shell_ambient_background.dart';

part 'bottom_nav.dart';
part 'drawer.dart';
part 'route_tab_mapper.dart';

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

  // ============== LAYOUTS ==============
  // Composed in bottom_nav.dart (mobile) and drawer.dart (desktop).

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
}
