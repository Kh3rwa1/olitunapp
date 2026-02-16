import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AdminNavRail extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withOpacity(0.5)
            : Colors.white.withOpacity(0.8),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelType: NavigationRailLabelType.none,
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: isDark ? Colors.white38 : Colors.black26,
          size: 24,
        ),
        leading: _buildLeading(isDark),
        trailing: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLogoutButton(context, ref, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
        destinations: _destinations,
      ),
    );
  }

  Widget _buildLeading(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_mosaic_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isDark) {
    return Tooltip(
      message: 'Log Out',
      child: IconButton(
        onPressed: () => ref.read(adminAuthProvider.notifier).logout(),
        icon: Icon(
          Icons.power_settings_new_rounded,
          color: AppColors.error.withOpacity(0.7),
        ),
      ),
    );
  }

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: Text('Overview'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.view_carousel_outlined),
      selectedIcon: Icon(Icons.view_carousel_rounded),
      label: Text('Banners'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category_rounded),
      label: Text('Categories'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.text_fields_outlined),
      selectedIcon: Icon(Icons.text_fields_rounded),
      label: Text('Letters'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.book_outlined),
      selectedIcon: Icon(Icons.book_rounded),
      label: Text('Lessons'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.format_list_numbered_outlined),
      selectedIcon: Icon(Icons.format_list_numbered_rounded),
      label: Text('Numbers'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: Text('Words'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_tree_outlined),
      selectedIcon: Icon(Icons.account_tree_rounded),
      label: Text('Rhyme Types'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.music_note_outlined),
      selectedIcon: Icon(Icons.music_note_rounded),
      label: Text('Rhymes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz_rounded),
      label: Text('Quizzes'),
    ),
  ];
}
