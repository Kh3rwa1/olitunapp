import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/providers.dart';
import 'widgets/admin_nav_rail.dart';
import 'admin_banners_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_letters_screen.dart';
import 'admin_lessons_screen.dart';
import 'admin_quizzes_screen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AdminNavRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          Expanded(child: _buildContent(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return _buildOverview();
      case 1:
        return const AdminBannersScreen(); // Placeholder until file updated
      case 2:
        return const AdminCategoriesScreen(); // Placeholder
      case 3:
        return const AdminLettersScreen(); // Placeholder
      case 4:
        return const AdminLessonsScreen(); // Placeholder
      case 5:
        return const AdminQuizzesScreen(); // Placeholder
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    // Watch all async providers
    final categoriesAsync = ref.watch(categoriesProvider);
    final bannersAsync = ref.watch(featuredBannersProvider);
    final lettersAsync = ref.watch(lettersProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final quizzesAsync = ref.watch(quizzesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildStatCard(
                'Categories',
                categoriesAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.category_rounded,
                Colors.blue,
              ),
              _buildStatCard(
                'Banners',
                bannersAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.view_carousel_rounded,
                Colors.orange,
              ),
              _buildStatCard(
                'Letters',
                lettersAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.text_fields_rounded,
                Colors.purple,
              ),
              _buildStatCard(
                'Lessons',
                lessonsAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.book_rounded,
                Colors.green,
              ),
              _buildStatCard(
                'Quizzes',
                quizzesAsync.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.quiz_rounded,
                Colors.red,
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
  ) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.8),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
