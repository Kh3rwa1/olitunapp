import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/widgets/gamified_card.dart';
import '../../../../shared/widgets/animated_buttons.dart';
import 'widgets/admin_nav_rail.dart';
import 'admin_banners_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_letters_screen.dart';
import 'admin_lessons_screen.dart';
import 'admin_rhymes_screen.dart';
import 'admin_quizzes_screen.dart';
import '../../../../core/theme/app_colors.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AdminNavRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          Expanded(child: _buildContent(_selectedIndex, isDark)),
        ],
      ),
    );
  }

  Widget _buildContent(int index, bool isDark) {
    switch (index) {
      case 0:
        return _buildOverview(isDark);
      case 1:
        return const AdminBannersScreen();
      case 2:
        return const AdminCategoriesScreen();
      case 3:
        return const AdminLettersScreen();
      case 4:
        return const AdminLessonsScreen();
      case 5:
        return const AdminRhymesScreen();
      case 6:
        return const AdminQuizzesScreen();
      default:
        return _buildOverview(isDark);
    }
  }

  Widget _buildOverview(bool isDark) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final bannersAsync = ref.watch(featuredBannersProvider);
    final lettersAsync = ref.watch(lettersProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final quizzesAsync = ref.watch(quizzesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your content and settings',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              DuoButton(
                text: 'SEED SAMPLE DATA',
                icon: Icons.auto_fix_high_rounded,
                color: AppColors.primary,
                width: 220,
                height: 52,
                borderRadius: 14,
                onPressed: () => _handleSeeding(),
              ),
            ],
          ),
          const SizedBox(height: 48),

          Text(
            'STATISTICS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDark ? AppColors.primary : AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildStatCard(
                'Categories',
                categoriesAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.category_rounded,
                AppColors.duoGreen,
                AppColors.duoGreenDark,
              ),
              _buildStatCard(
                'Letters',
                lettersAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.text_fields_rounded,
                AppColors.duoOrange,
                AppColors.duoOrangeDark,
              ),
              _buildStatCard(
                'Lessons',
                lessonsAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.book_rounded,
                AppColors.duoBlue,
                AppColors.duoBlueDark,
              ),
              _buildStatCard(
                'Quizzes',
                quizzesAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.quiz_rounded,
                AppColors.duoBlue,
                AppColors.duoBlueDark,
              ),
              _buildStatCard(
                'Banners',
                bannersAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.view_carousel_rounded,
                AppColors.duoYellow,
                AppColors.duoYellowDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color shadowColor,
  ) {
    return SizedBox(
      width: 220,
      child: GamifiedCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              value,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSeeding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Sample Data?'),
        content: const Text(
          'This will populate the app with rich sample categories, lessons, and letters. It will not delete existing data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // We'll implement this function in the next step
              await seedAppContent(ref);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Content seeded successfully! ✨'),
                  ),
                );
              }
            },
            child: const Text('SEED DATA'),
          ),
        ],
      ),
    );
  }
}
