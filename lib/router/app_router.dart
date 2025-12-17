import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/providers/providers.dart';

// Screens
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/lessons/presentation/lessons_screen.dart';
import '../features/lessons/presentation/lesson_detail_screen.dart';
import '../features/lessons/presentation/category_lessons_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/admin/presentation/admin_shell.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_categories_screen.dart';
import '../features/admin/presentation/admin_banners_screen.dart';
import '../features/admin/presentation/admin_letters_screen.dart';
import '../features/admin/presentation/admin_lessons_screen.dart';
import '../features/admin/presentation/admin_quizzes_screen.dart';

// Route names
class AppRoutes {
  static const welcome = 'welcome';
  static const signIn = 'signIn';
  static const signUp = 'signUp';
  static const onboarding = 'onboarding';
  static const home = 'home';
  static const lessons = 'lessons';
  static const lessonDetail = 'lessonDetail';
  static const categoryLessons = 'categoryLessons';
  static const quiz = 'quiz';
  static const profile = 'profile';
  static const settings = 'settings';
  static const admin = 'admin';
  static const adminCategories = 'adminCategories';
  static const adminBanners = 'adminBanners';
  static const adminLetters = 'adminLetters';
  static const adminLessons = 'adminLessons';
  static const adminQuizzes = 'adminQuizzes';
}

// Custom page transitions
CustomTransitionPage<T> _fadeTransition<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

CustomTransitionPage<T> _slideTransition<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurveTween(curve: Curves.easeInOut).animate(animation)),
        child: child,
      );
    },
  );
}

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up';

      // If not authenticated and not on auth route, redirect to welcome
      if (!isAuthenticated && !isAuthRoute) {
        return '/welcome';
      }

      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/welcome',
        name: AppRoutes.welcome,
        pageBuilder: (context, state) => _fadeTransition(
          context,
          state,
          const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/sign-in',
        name: AppRoutes.signIn,
        pageBuilder: (context, state) => _slideTransition(
          context,
          state,
          const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/sign-up',
        name: AppRoutes.signUp,
        pageBuilder: (context, state) => _slideTransition(
          context,
          state,
          const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: AppRoutes.onboarding,
        pageBuilder: (context, state) => _fadeTransition(
          context,
          state,
          const OnboardingScreen(),
        ),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            pageBuilder: (context, state) => _fadeTransition(
              context,
              state,
              const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/lessons',
            name: AppRoutes.lessons,
            pageBuilder: (context, state) => _fadeTransition(
              context,
              state,
              const LessonsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'category/:categoryId',
                name: AppRoutes.categoryLessons,
                pageBuilder: (context, state) => _slideTransition(
                  context,
                  state,
                  CategoryLessonsScreen(
                    categoryId: state.pathParameters['categoryId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: AppRoutes.profile,
            pageBuilder: (context, state) => _fadeTransition(
              context,
              state,
              const ProfileScreen(),
            ),
          ),
        ],
      ),

      // Standalone routes (no bottom nav)
      GoRoute(
        path: '/lesson/:lessonId',
        name: AppRoutes.lessonDetail,
        pageBuilder: (context, state) => _slideTransition(
          context,
          state,
          LessonDetailScreen(
            lessonId: state.pathParameters['lessonId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/quiz/:quizId',
        name: AppRoutes.quiz,
        pageBuilder: (context, state) => _slideTransition(
          context,
          state,
          QuizScreen(
            quizId: state.pathParameters['quizId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoutes.settings,
        pageBuilder: (context, state) => _slideTransition(
          context,
          state,
          const SettingsScreen(),
        ),
      ),

      // Admin routes
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: AppRoutes.admin,
            pageBuilder: (context, state) => _fadeTransition(
              context,
              state,
              const AdminDashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: 'categories',
                name: AppRoutes.adminCategories,
                pageBuilder: (context, state) => _slideTransition(
                  context,
                  state,
                  const AdminCategoriesScreen(),
                ),
              ),
              GoRoute(
                path: 'banners',
                name: AppRoutes.adminBanners,
                pageBuilder: (context, state) => _slideTransition(
                  context,
                  state,
                  const AdminBannersScreen(),
                ),
              ),
              GoRoute(
                path: 'letters',
                name: AppRoutes.adminLetters,
                pageBuilder: (context, state) => _slideTransition(
                  context,
                  state,
                  const AdminLettersScreen(),
                ),
              ),
              GoRoute(
                path: 'lessons',
                name: AppRoutes.adminLessons,
                pageBuilder: (context, state) => _slideTransition(
                  context,
                  state,
                  const AdminLessonsScreen(),
                ),
              ),
              GoRoute(
                path: 'quizzes',
                name: AppRoutes.adminQuizzes,
                pageBuilder: (context, state) => _slideTransition(
                  context,
                  state,
                  const AdminQuizzesScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
