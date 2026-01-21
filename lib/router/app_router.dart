import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';

// Home
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/main_shell.dart';

// Lessons
import '../features/lessons/presentation/lessons_screen.dart';
import '../features/lessons/presentation/lesson_detail_screen.dart';
import '../features/lessons/presentation/category_lessons_screen.dart';

// Quiz
import '../features/quiz/presentation/quiz_screen.dart';

// Profile
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/settings_screen.dart';

// Route names
class AppRoutes {
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lesson/:lessonId';
  static const String categoryLessons = '/lessons/category/:categoryId';
  static const String quiz = '/quiz/:quizId';
  static const String profile = '/profile';
  static const String settings = '/settings';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: false,

    // No authentication required - open access
    redirect: (context, state) {
      // Allow all routes - no auth required
      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),

    routes: [
      // Welcome / Auth routes (simplified - no auth required)
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
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadeTransition(child: const OnboardingScreen(), state: state),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _fadeTransition(child: const HomeScreen(), state: state),
          ),
          GoRoute(
            path: '/lessons',
            pageBuilder: (context, state) =>
                _fadeTransition(child: const LessonsScreen(), state: state),
            routes: [
              GoRoute(
                path: 'category/:categoryId',
                pageBuilder: (context, state) => _slideTransition(
                  child: CategoryLessonsScreen(
                    categoryId: state.pathParameters['categoryId']!,
                  ),
                  state: state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _fadeTransition(child: const ProfileScreen(), state: state),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _slideTransition(child: const SettingsScreen(), state: state),
          ),
        ],
      ),

      // Standalone routes (outside shell)
      GoRoute(
        path: '/lesson/:lessonId',
        pageBuilder: (context, state) => _slideTransition(
          child: LessonDetailScreen(
            lessonId: state.pathParameters['lessonId']!,
          ),
          state: state,
        ),
      ),
      GoRoute(
        path: '/quiz/:quizId',
        pageBuilder: (context, state) => _slideTransition(
          child: QuizScreen(quizId: state.pathParameters['quizId']!),
          state: state,
        ),
      ),
    ],
  );
});
