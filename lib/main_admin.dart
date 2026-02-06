import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/admin_categories_screen.dart';
import 'features/admin/presentation/admin_banners_screen.dart';
import 'features/admin/presentation/admin_letters_screen.dart';
import 'features/admin/presentation/admin_lessons_screen.dart';
import 'features/admin/presentation/admin_quizzes_screen.dart';

import 'core/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared storage
  await initStorage();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: AdminWebLoader()));
}

final _adminRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AdminDashboardScreen(),
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

class AdminWebLoader extends ConsumerWidget {
  const AdminWebLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Olitun Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode
          .light, // Admin panel usually preferred in light or dark explicitly
      routerConfig: _adminRouter,
    );
  }
}
