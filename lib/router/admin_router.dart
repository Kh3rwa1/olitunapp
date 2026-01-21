import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';

// Admin
import '../features/admin/presentation/admin_shell.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_categories_screen.dart';
import '../features/admin/presentation/admin_banners_screen.dart';
import '../features/admin/presentation/admin_letters_screen.dart';
import '../features/admin/presentation/admin_lessons_screen.dart';
import '../features/admin/presentation/admin_quizzes_screen.dart';
import '../features/admin/presentation/admin_media_screen.dart';

// Route names
class AdminRoutes {
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';

  static const String admin = '/admin';
  static const String adminCategories = '/admin/categories';
  static const String adminBanners = '/admin/banners';
  static const String adminLetters = '/admin/letters';
  static const String adminLessons = '/admin/lessons';
  static const String adminQuizzes = '/admin/quizzes';
  static const String adminMedia = '/admin/media';
}

// Custom transition
CustomTransitionPage _fadeTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
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

CustomTransitionPage _slideTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurveTween(curve: Curves.easeInOutCubic).animate(animation)),
        child: child,
      );
    },
  );
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sign-in', // Start at sign-in for admin
    debugLogDiagnostics: false,

    routes: [
      // Redirect root to sign-in
      GoRoute(path: '/', redirect: (_, __) => '/sign-in'),

      // Auth routes
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            _fadeTransition(child: const WelcomeScreen(), state: state),
      ),
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) =>
            _fadeTransition(child: const SignInScreen(), state: state),
      ),
      GoRoute(
        path: '/sign-up',
        pageBuilder: (context, state) =>
            _fadeTransition(child: const SignUpScreen(), state: state),
      ),

      // Admin routes
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _fadeTransition(
              child: const AdminDashboardScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/admin/categories',
            pageBuilder: (context, state) => _slideTransition(
              child: const AdminCategoriesScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/admin/banners',
            pageBuilder: (context, state) => _slideTransition(
              child: const AdminBannersScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/admin/letters',
            pageBuilder: (context, state) => _slideTransition(
              child: const AdminLettersScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/admin/lessons',
            pageBuilder: (context, state) => _slideTransition(
              child: const AdminLessonsScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/admin/quizzes',
            pageBuilder: (context, state) => _slideTransition(
              child: const AdminQuizzesScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/admin/media',
            pageBuilder: (context, state) =>
                _slideTransition(child: const AdminMediaScreen(), state: state),
          ),
        ],
      ),
    ],
  );
});
