import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/presentation/home_screen.dart';
import '../../rhymes/presentation/rhyme_screen.dart';
import '../../profile/presentation/progress_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/layout/responsive_layout.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RhymeScreen(),
    const ProgressScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            _buildPremiumBackground(isDark),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 115 : 110),
                child: IndexedStack(index: _selectedIndex, children: _screens),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildGlassicNav(isDark, isTablet),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex > 0) {
      setState(() {
        _selectedIndex -= 1;
      });
      return false;
    }

    // Keep users inside the app shell instead of closing from the root tab.
    return false;
  }

  Widget _buildPremiumBackground(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0A0E1A), Color(0xFF121A2B), Color(0xFF1E2A44)]
              : const [Color(0xFFF3F8FF), Color(0xFFF8FAFF), Color(0xFFE8F0FF)],
        ),
      ),
    );
  }

  Widget _buildGlassicNav(bool isDark, bool isTablet) {
    return Container(
      margin: EdgeInsets.fromLTRB(isTablet ? 32 : 24, 0, isTablet ? 32 : 24, 30),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
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
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.music_note_rounded, 'Rhymes'),
                _buildNavItem(2, Icons.analytics_rounded, 'Progress'),
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
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: AppColors.primary.withOpacity(0.2))
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
