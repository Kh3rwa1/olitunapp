import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/providers.dart';

import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/admin_categories_screen.dart';
import 'features/admin/presentation/admin_banners_screen.dart';
import 'features/admin/presentation/admin_letters_screen.dart';
import 'features/admin/presentation/admin_lessons_screen.dart';
import 'features/admin/presentation/admin_quizzes_screen.dart';
import 'features/lessons/presentation/category_lessons_screen.dart';
import 'features/lessons/presentation/lesson_detail_screen.dart';
import 'features/lessons/presentation/lessons_screen.dart';

import 'features/lessons/presentation/letter_detail_screen.dart';
import 'features/lessons/presentation/word_detail_screen.dart';
import 'features/lessons/presentation/number_detail_screen.dart';
import 'features/lessons/presentation/sentence_detail_screen.dart';
import 'features/lessons/presentation/practice/practice_screen.dart';
import 'features/lessons/presentation/quiz/quiz_screen.dart';
import 'features/quiz/presentation/quiz_list_screen.dart';
import 'features/profile/presentation/progress_screen.dart';
import 'features/profile/presentation/settings_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/onboarding/presentation/splash_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/auth/presentation/email_auth_screen.dart';
import 'features/main/presentation/main_shell_screen.dart';
import 'features/admin/presentation/admin_login_screen.dart';
import 'features/admin/presentation/admin_rhymes_screen.dart';
import 'features/admin/presentation/admin_rhyme_categories_screen.dart';
import 'features/admin/presentation/admin_media_screen.dart';
import 'features/admin/presentation/admin_settings_screen.dart';
import 'features/admin/presentation/admin_shell.dart';
import 'features/admin/providers/admin_auth_provider.dart';
import 'core/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared storage
  await initStorage();
  final prefs = await SharedPreferences.getInstance();

  // Set system UI to edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const OlitunApp(),
    ),
  );
}

// Simple router
final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final container = ProviderScope.containerOf(context);
        final showOnboarding = container.read(onboardingProvider);
        if (showOnboarding) return '/onboarding';
        return '/home';
      },
      builder: (context, state) => const MainShellScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const EmailAuthScreen(),
    ),
    GoRoute(
      path: '/profile',
      redirect: (context, state) async {
        final container = ProviderScope.containerOf(context);
        final authRepo = container.read(authRepositoryProvider);
        final token = await authRepo.getToken();
        if (token == null) return '/welcome';
        return null;
      },
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/settings',
      redirect: (context, state) async {
        final container = ProviderScope.containerOf(context);
        final authRepo = container.read(authRepositoryProvider);
        final token = await authRepo.getToken();
        if (token == null) return '/welcome';
        return null;
      },
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainShellScreen(),
    ),
    GoRoute(
      path: '/lessons',
      builder: (context, state) => const LessonsScreen(),
    ),
    GoRoute(
      path: '/lessons/category/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? '';
        return CategoryLessonsScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/lesson/:lessonId',
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
      path: '/quizzes',
      builder: (context, state) => const QuizListScreen(),
    ),
    GoRoute(
      path: '/quiz/:quizId',
      builder: (context, state) {
        final quizId = state.pathParameters['quizId'];
        return QuizScreen(quizId: quizId);
      },
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AdminShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/admin',
          redirect: (context, state) {
            final container = ProviderScope.containerOf(context);
            final isAuthenticated = container.read(adminAuthProvider);
            if (!isAuthenticated) return '/admin/login';
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
          path: '/admin/quizzes',
          builder: (context, state) => const AdminQuizzesScreen(),
        ),
        GoRoute(
          path: '/admin/rhymes',
          builder: (context, state) => const AdminRhymesScreen(),
          routes: [
            GoRoute(
              path: 'categories',
              builder: (context, state) => const AdminRhymeCategoriesScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/admin/media',
          builder: (context, state) =>
              const AdminMediaScreen(initialType: MediaType.all),
        ),
        GoRoute(
          path: '/admin/audio',
          builder: (context, state) =>
              const AdminMediaScreen(initialType: MediaType.audio),
        ),
        GoRoute(
          path: '/admin/video',
          builder: (context, state) =>
              const AdminMediaScreen(initialType: MediaType.video),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) => const AdminSettingsScreen(),
        ),
      ],
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
