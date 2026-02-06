import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bubble_background.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    // TEMPORARILY BYPASS AUTH CHECK FOR PREVIEW
    // TODO: Re-enable isAdminProvider check before production

    if (isWideScreen) {
      // Web/Desktop layout with sidebar
      return Scaffold(
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0D1117), const Color(0xFF161B22)]
                      : [Colors.white, const Color(0xFFF6F8FA)],
                ),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
              child: _AdminSidebar(),
            ),
            // Main content
            Expanded(child: BubbleBackground(child: child)),
          ],
        ),
      );
    } else {
      // Mobile layout with drawer
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icons/olitun_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Admin CMS',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded),
              onPressed: () => context.go('/home'),
              tooltip: 'Back to App',
            ),
          ],
        ),
        drawer: Drawer(child: _AdminSidebar()),
        body: BubbleBackground(child: child),
      );
    }
  }
}

class _AdminSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // Header with logo
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.glowShadow(AppColors.primary),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icons/olitun_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),

          const SizedBox(height: 16),

          // Navigation section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CONTENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == '/admin',
                  onTap: () => context.go('/admin'),
                ),
                _NavItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  isSelected: location == '/admin/categories',
                  onTap: () => context.go('/admin/categories'),
                ),
                _NavItem(
                  icon: Icons.featured_play_list_rounded,
                  label: 'Banners',
                  isSelected: location == '/admin/banners',
                  onTap: () => context.go('/admin/banners'),
                ),
                _NavItem(
                  icon: Icons.text_fields_rounded,
                  label: 'Letters & Alphabet',
                  isSelected: location == '/admin/letters',
                  onTap: () => context.go('/admin/letters'),
                ),
                _NavItem(
                  icon: Icons.school_rounded,
                  label: 'Lessons',
                  isSelected: location == '/admin/lessons',
                  onTap: () => context.go('/admin/lessons'),
                ),
                _NavItem(
                  icon: Icons.music_note_rounded,
                  label: 'Rhymes & Stories',
                  isSelected: location == '/admin/rhymes',
                  onTap: () => context.go('/admin/rhymes'),
                ),
                _NavItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  isSelected: location == '/admin/quizzes',
                  onTap: () => context.go('/admin/quizzes'),
                ),

                const SizedBox(height: 24),

                // Media section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'MEDIA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _NavItem(
                  icon: Icons.perm_media_rounded,
                  label: 'Media Library',
                  isSelected: location == '/admin/media',
                  onTap: () => context.go('/admin/media'),
                ),
                _NavItem(
                  icon: Icons.audiotrack_rounded,
                  label: 'Audio Files',
                  isSelected: location == '/admin/audio',
                  onTap: () => context.go('/admin/audio'),
                ),
                _NavItem(
                  icon: Icons.videocam_rounded,
                  label: 'Video Files',
                  isSelected: location == '/admin/video',
                  onTap: () => context.go('/admin/video'),
                ),
              ],
            ),
          ),

          // Back to app button
          Padding(
            padding: const EdgeInsets.all(16),
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
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
