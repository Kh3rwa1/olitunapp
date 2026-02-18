import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    // Breakpoints
    final isDesktop = width > 1100;
    final isTablet = width > 600 && width <= 1100;

    // TEMPORARILY BYPASS AUTH CHECK FOR PREVIEW
    // TODO: Re-enable isAdminProvider check before production

    if (isDesktop || isTablet) {
      // Web/Desktop/Tablet layout with sidebar
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF1F5F9),
        body: Row(
          children: [
            // Adaptive Sidebar
            Container(
              width: isDesktop ? 280 : 88,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.white.withOpacity(0.8),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              child: _AdminSidebar(isCompact: !isDesktop),
            ),
            // Main content
            Expanded(
              child: Material(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                child: child,
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile layout with drawer
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            'Admin CMS',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          width: 280,
          child: _AdminSidebar(),
        ),
        body: Material(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          child: child,
        ),
      );
    }
  }
}

class _AdminSidebar extends StatelessWidget {
  final bool isCompact;

  const _AdminSidebar({this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // Header with logo
          Container(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Row(
              mainAxisAlignment: isCompact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  width: isCompact ? 44 : 52,
                  height: isCompact ? 44 : 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
                    boxShadow: AppColors.glowShadow(AppColors.primary),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
                    child: Image.asset(
                      'assets/icons/olitun_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Olitun CMS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Content Management',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
            indent: isCompact ? 12 : 0,
            endIndent: isCompact ? 12 : 0,
          ),

          const SizedBox(height: 16),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == '/admin',
                  onTap: () => context.go('/admin'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  isSelected: location == '/admin/categories',
                  onTap: () => context.go('/admin/categories'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.featured_play_list_rounded,
                  label: 'Banners',
                  isSelected: location == '/admin/banners',
                  onTap: () => context.go('/admin/banners'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.text_fields_rounded,
                  label: 'Letters & Alphabet',
                  isSelected: location == '/admin/letters',
                  onTap: () => context.go('/admin/letters'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.school_rounded,
                  label: 'Lessons',
                  isSelected: location == '/admin/lessons',
                  onTap: () => context.go('/admin/lessons'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.music_note_rounded,
                  label: 'Rhymes & Stories',
                  isSelected: location == '/admin/rhymes',
                  onTap: () => context.go('/admin/rhymes'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Rhyme Categories',
                  isSelected: location == '/admin/rhymes/categories',
                  onTap: () => context.go('/admin/rhymes/categories'),
                  isCompact: isCompact,
                  padding: const EdgeInsets.only(left: 16),
                ),
                _NavItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  isSelected: location == '/admin/quizzes',
                  onTap: () => context.go('/admin/quizzes'),
                  isCompact: isCompact,
                ),

                const SizedBox(height: 24),

                _NavItem(
                  icon: Icons.perm_media_rounded,
                  label: 'Media Library',
                  isSelected: location == '/admin/media',
                  onTap: () => context.go('/admin/media'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.audiotrack_rounded,
                  label: 'Audio Files',
                  isSelected: location == '/admin/audio',
                  onTap: () => context.go('/admin/audio'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.videocam_rounded,
                  label: 'Video Files',
                  isSelected: location == '/admin/video',
                  onTap: () => context.go('/admin/video'),
                  isCompact: isCompact,
                ),

                const SizedBox(height: 24),

                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: location == '/admin/settings',
                  onTap: () => context.go('/admin/settings'),
                  isCompact: isCompact,
                ),
              ],
            ),
          ),

          // Back to app button
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/home'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.glowShadow(AppColors.primary),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Back to App',
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
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;

  final EdgeInsets? padding;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
