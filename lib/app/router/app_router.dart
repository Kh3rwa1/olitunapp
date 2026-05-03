import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/main/presentation/main_shell_screen.dart';
import '../../features/lessons/presentation/category_lessons_screen.dart';
import '../../features/lessons/presentation/lesson_detail_screen.dart';
import '../../features/lessons/presentation/letter_detail_screen.dart';
import '../../features/lessons/presentation/word_detail_screen.dart';
import '../../features/lessons/presentation/number_detail_screen.dart';
import '../../features/lessons/presentation/sentence_detail_screen.dart';
import '../../features/lessons/presentation/practice/practice_screen.dart';
import '../../features/quiz/presentation/quiz_list_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import '../../features/home/presentation/screens/ai_translator_screen.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_categories_screen.dart';
import '../../features/admin/presentation/admin_banners_screen.dart';
import '../../features/admin/presentation/admin_letters_screen.dart';
import '../../features/admin/presentation/admin_lessons_screen.dart';
import '../../features/admin/presentation/admin_lesson_content_screen.dart';
import '../../features/admin/presentation/admin_quizzes_screen.dart';
import '../../features/admin/presentation/admin_rhymes_screen.dart';
import '../../features/admin/presentation/admin_rhyme_categories_screen.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/admin/providers/admin_auth_provider.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const EmailAuthScreen(),
      ),
      GoRoute(
        path: '/',
        name: RouteNames.home,
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/categories',
        name: RouteNames.categories,
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/quizzes',
        builder: (context, state) => const QuizListScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/lessons/:categoryId',
        name: RouteNames.lessons,
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId'] ?? '';
          return CategoryLessonsScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        name: RouteNames.lessonDetail,
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return LessonDetailScreen(lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/letter/:lessonId/:letterId',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          final letterId = state.pathParameters['letterId'] ?? '';
          return LetterDetailScreen(lessonId: lessonId, letterId: letterId);
        },
      ),
      GoRoute(
        path: '/word/:lessonId/:wordId',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          final wordId = state.pathParameters['wordId'] ?? '';
          return WordDetailScreen(lessonId: lessonId, wordId: wordId);
        },
      ),
      GoRoute(
        path: '/number/:lessonId/:numberId',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          final numberId = state.pathParameters['numberId'] ?? '';
          return NumberDetailScreen(lessonId: lessonId, numberId: numberId);
        },
      ),
      GoRoute(
        path: '/sentence/:lessonId/:sentenceId',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          final sentenceId = state.pathParameters['sentenceId'] ?? '';
          return SentenceDetailScreen(lessonId: lessonId, sentenceId: sentenceId);
        },
      ),
      GoRoute(
        path: '/practice/:char/:name',
        builder: (context, state) {
          final char = state.pathParameters['char'] ?? '';
          final name = state.pathParameters['name'] ?? '';
          return PracticeScreen(letterChar: char, letterName: name);
        },
      ),
      GoRoute(
        path: '/translate',
        builder: (context, state) => const AiTranslatorScreen(),
      ),
      GoRoute(
        path: '/quiz/:quizId',
        name: RouteNames.quiz,
        builder: (context, state) {
          final quizId = state.pathParameters['quizId'] ?? '';
          return QuizScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: '/admin/login',
        name: RouteNames.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: RouteNames.admin,
            redirect: (context, state) async {
              final isAdmin = await ref.read(adminAuthProvider.future);
              if (!isAdmin) return '/admin/login';
              return null;
            },
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
            path: '/admin/lessons/content/:lessonId',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId'] ?? '';
              return AdminLessonContentScreen(lessonId: lessonId);
            },
          ),
          GoRoute(
            path: '/admin/quizzes',
            builder: (context, state) => const AdminQuizzesScreen(),
          ),
          GoRoute(
            path: '/admin/rhymes',
            builder: (context, state) => const AdminRhymesScreen(),
          ),
          GoRoute(
            path: '/admin/rhymes/categories',
            builder: (context, state) => const AdminRhymeCategoriesScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
