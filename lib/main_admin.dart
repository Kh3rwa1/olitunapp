import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/presentation/admin_login_screen.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/admin_categories_screen.dart';
import 'features/admin/presentation/admin_banners_screen.dart';
import 'features/admin/presentation/admin_letters_screen.dart';
import 'features/admin/presentation/admin_lessons_screen.dart';
import 'features/admin/presentation/admin_lesson_content_screen.dart';
import 'features/admin/presentation/admin_quizzes_screen.dart';
import 'features/admin/presentation/admin_rhymes_screen.dart';
import 'features/admin/presentation/admin_media_screen.dart';
import 'features/admin/presentation/admin_shell.dart';
import 'features/admin/providers/admin_auth_provider.dart';

import 'core/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared storage
  await initStorage();
  final prefs = await SharedPreferences.getInstance();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AdminWebLoader(),
    ),
  );
}

final _adminRouter = GoRouter(
  initialLocation: '/admin',
  routes: [
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(path: '/', redirect: (_, __) => '/admin'),
    ShellRoute(
      builder: (context, state, child) {
        return AdminShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/admin',
          redirect: _adminAuthRedirect,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/categories',
          redirect: _adminAuthRedirect,
          builder: (context, state) => const AdminCategoriesScreen(),
        ),
        GoRoute(
          path: '/admin/banners',
          redirect: _adminAuthRedirect,
          builder: (context, state) => const AdminBannersScreen(),
        ),
        GoRoute(
          path: '/admin/letters',
          redirect: _adminAuthRedirect,
          builder: (context, state) => const AdminLettersScreen(),
        ),
        GoRoute(
          path: '/admin/lessons',
          redirect: _adminAuthRedirect,
          builder: (context, state) => const AdminLessonsScreen(),
          routes: [
            GoRoute(
              path: 'content/:lessonId',
              builder: (context, state) {
                final lessonId = state.pathParameters['lessonId'] ?? '';
                return AdminLessonContentScreen(lessonId: lessonId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/admin/quizzes',
          redirect: _adminAuthRedirect,
          builder: (context, state) => const AdminQuizzesScreen(),
        ),
        GoRoute(
          path: '/admin/rhymes',
          redirect: _adminAuthRedirect,
          builder: (context, state) => const AdminRhymesScreen(),
        ),
        GoRoute(
          path: '/admin/media',
          redirect: _adminAuthRedirect,
          builder: (context, state) =>
              const AdminMediaScreen(initialType: MediaType.all),
        ),
        GoRoute(
          path: '/admin/audio',
          redirect: _adminAuthRedirect,
          builder: (context, state) =>
              const AdminMediaScreen(initialType: MediaType.audio),
        ),
        GoRoute(
          path: '/admin/video',
          redirect: _adminAuthRedirect,
          builder: (context, state) =>
              const AdminMediaScreen(initialType: MediaType.video),
        ),
      ],
    ),
  ],
);

String? _adminAuthRedirect(BuildContext context, GoRouterState state) {
  final container = ProviderScope.containerOf(context);
  final isAuthenticated = container.read(adminAuthProvider);
  if (!isAuthenticated) return '/admin/login';
  return null;
}

class AdminWebLoader extends ConsumerWidget {
  const AdminWebLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Olitun Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _adminRouter,
    );
  }
}
