import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/providers.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/admin_categories_screen.dart';
import 'features/admin/presentation/admin_banners_screen.dart';
import 'features/admin/presentation/admin_letters_screen.dart';
import 'features/admin/presentation/admin_lessons_screen.dart';
import 'features/admin/presentation/admin_quizzes_screen.dart';
import 'features/lessons/presentation/category_lessons_screen.dart';
import 'features/profile/presentation/settings_screen.dart';

// Global SharedPreferences instance
late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences for local storage
  prefs = await SharedPreferences.getInstance();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: OlitunApp()));
}

// Simple router
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/lessons',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/lessons/category/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? '';
        return CategoryLessonsScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const AdminCategoriesScreen(),
    ),
    GoRoute(
      path: '/admin/banners',
      builder: (context, state) => const AdminBannersScreen(),
    ),
    GoRoute(
      path: '/admin/letters',
      builder: (context, state) => const AdminLettersScreen(),
    ),
    GoRoute(
      path: '/admin/lessons',
      builder: (context, state) => const AdminLessonsScreen(),
    ),
    GoRoute(
      path: '/admin/quizzes',
      builder: (context, state) => const AdminQuizzesScreen(),
    ),
  ],
);

class OlitunApp extends ConsumerWidget {
  const OlitunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Olitun - Learn Ol Chiki',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(themeMode),
      routerConfig: _router,
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
