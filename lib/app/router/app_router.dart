import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../core/motion/page_transitions.dart';
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
import '../../features/quiz/presentation/mistake_review_screen.dart';
import '../../features/circle/presentation/weekly_circle_screen.dart';
import '../../features/home/presentation/screens/ai_translator_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';

import '../../features/legal/presentation/legal_document_screen.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/shell/admin_shell.dart';
import '../../features/admin/presentation/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/presentation/categories/admin_categories_screen.dart';
import '../../features/admin/presentation/banners/admin_banners_screen.dart';
import '../../features/admin/presentation/letters/admin_letters_screen.dart';
import '../../features/admin/presentation/lessons/admin_lessons_screen.dart';
import '../../features/admin/presentation/lessons/content/admin_lesson_content_screen.dart';
import '../../features/admin/presentation/quizzes/admin_quizzes_screen.dart';
import '../../features/admin/presentation/numbers/admin_numbers_screen.dart';
import '../../features/admin/presentation/words/admin_words_screen.dart';
import '../../features/admin/presentation/sentences/admin_sentences_screen.dart';
import '../../features/admin/presentation/admin_rhymes_screen.dart';
import '../../features/admin/presentation/admin_rhyme_categories_screen.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/admin/presentation/admin_media_screen.dart';
import '../../features/admin/presentation/access/admin_access_screen.dart';
import '../../features/admin/presentation/analytics/admin_analytics_screen.dart';
import '../../features/admin/presentation/gamification/admin_gamification_screen.dart';
import '../../features/admin/providers/admin_auth_provider.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
const _adminHost = 'admin.olitun.in';

@visibleForTesting
String? adminHostRedirectFor(String host, String path) {
  if (host.toLowerCase() != _adminHost) return null;
  if (path == '/admin' || path.startsWith('/admin/')) return null;
  return '/admin';
}

@visibleForTesting
String? adminAccessRedirectFor({required bool isAdmin, required String path}) {
  if (!path.startsWith('/admin') || path == '/admin/login') return null;
  return isAdmin ? null : '/admin/login';
}

/// Convenience: builds a GoRoute whose `pageBuilder` wraps the screen
/// in our shared-axis Z transition. Used for content "drill-in" routes
/// (lesson, letter, word, number, sentence, quiz, practice).
GoRoute _drillRoute({
  required String path,
  String? name,
  required Widget Function(BuildContext, GoRouterState) child,
}) {
  return GoRoute(
    path: path,
    name: name,
    pageBuilder: (context, state) => AppPageTransitions.sharedAxisZ(
      key: state.pageKey,
      child: child(context, state),
    ),
  );
}

/// Lateral / shell-level routes get the fade-through pattern.
GoRoute _peerRoute({
  required String path,
  String? name,
  required Widget Function(BuildContext, GoRouterState) child,
  FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
}) {
  return GoRoute(
    path: path,
    name: name,
    redirect: redirect,
    pageBuilder: (context, state) => AppPageTransitions.fadeThrough(
      key: state.pageKey,
      child: child(context, state),
    ),
  );
}

/// Shell routes share the same mounted tab scaffold. They should not run a
/// full page transition when the bottom navigation updates the URL, otherwise
/// the tab animation and router animation fight each other.
GoRoute _shellRoute({
  required String path,
  String? name,
  required Widget Function(BuildContext, GoRouterState) child,
}) {
  return GoRoute(
    path: path,
    name: name,
    pageBuilder: (context, state) => NoTransitionPage<void>(
      key: const ValueKey<String>('main-shell-route'),
      child: child(context, state),
    ),
  );
}

/// Modal-style: translator, login. Slide-up + fade-in.
GoRoute _modalRoute({
  required String path,
  String? name,
  required Widget Function(BuildContext, GoRouterState) child,
}) {
  return GoRoute(
    path: path,
    name: name,
    pageBuilder: (context, state) => AppPageTransitions.fadeUp(
      key: state.pageKey,
      child: child(context, state),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  FutureOr<String?> adminRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final path = state.uri.path;
    if (!path.startsWith('/admin') || path == '/admin/login') return null;

    final isAdmin = await ref.read(adminAuthProvider.future);
    return adminAccessRedirectFor(isAdmin: isAdmin, path: path);
  }

  GoRoute adminRoute({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) builder,
  }) {
    return GoRoute(
      path: path,
      name: name,
      redirect: adminRedirect,
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: builder(context, state),
      ),
    );
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final hostRedirect = adminHostRedirectFor(Uri.base.host, state.uri.path);
      if (hostRedirect != null) return hostRedirect;

      // On Web: if OAuth token is present, route to /splash to exchange it
      if (kIsWeb) {
        final userId = state.uri.queryParameters['userId'];
        final secret = state.uri.queryParameters['secret'];
        if (userId != null && secret != null && state.uri.path != '/splash') {
          return '/splash';
        }
      }

      // Check onboarding: if onboarding not completed and we are not on welcome/splash/login/privacy/terms/admin, redirect to /welcome
      final showOnboarding = ref.read(onboardingProvider);
      final path = state.uri.path;
      final isAllowedDuringOnboarding =
          path == '/welcome' ||
          path == '/splash' ||
          path == '/login' ||
          path == '/privacy' ||
          path == '/terms' ||
          path.startsWith('/admin');

      if (showOnboarding && !isAllowedDuringOnboarding) {
        return '/welcome';
      }
      return null;
    },
    routes: [
      _peerRoute(
        path: '/splash',
        name: RouteNames.splash,
        child: (_, _) => const SplashScreen(),
      ),
      _peerRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        child: (_, _) => const WelcomeScreen(),
      ),
      _modalRoute(
        path: '/login',
        name: RouteNames.login,
        child: (_, _) => const EmailAuthScreen(),
      ),
      _shellRoute(
        path: '/',
        name: RouteNames.home,
        child: (_, _) => const MainShellScreen(),
      ),
      _shellRoute(
        path: '/categories',
        name: RouteNames.categories,
        child: (_, _) => const MainShellScreen(),
      ),
      _shellRoute(path: '/bakhed', child: (_, _) => const MainShellScreen()),
      _drillRoute(path: '/quizzes', child: (_, _) => const QuizListScreen()),
      _drillRoute(
        path: '/mistakes',
        child: (_, _) => const MistakeReviewScreen(),
      ),
      _drillRoute(path: '/circle', child: (_, _) => const WeeklyCircleScreen()),

      _shellRoute(
        path: '/profile',
        name: RouteNames.profile,
        child: (_, _) => const MainShellScreen(),
      ),
      _drillRoute(path: '/settings', child: (_, _) => const SettingsScreen()),
      _drillRoute(
        path: '/lessons/:categoryId',
        name: RouteNames.lessons,
        child: (_, state) => CategoryLessonsScreen(
          categoryId: state.pathParameters['categoryId'] ?? '',
        ),
      ),
      _drillRoute(
        path: '/lesson/:lessonId',
        name: RouteNames.lessonDetail,
        child: (_, state) => LessonDetailScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
        ),
      ),
      _drillRoute(
        path: '/letter/:lessonId/:letterId',
        child: (_, state) => LetterDetailScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
          letterId: state.pathParameters['letterId'] ?? '',
        ),
      ),
      _drillRoute(
        path: '/word/:lessonId/:wordId',
        child: (_, state) => WordDetailScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
          wordId: state.pathParameters['wordId'] ?? '',
        ),
      ),
      _drillRoute(
        path: '/number/:lessonId/:numberId',
        child: (_, state) => NumberDetailScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
          numberId: state.pathParameters['numberId'] ?? '',
        ),
      ),
      _drillRoute(
        path: '/sentence/:lessonId/:sentenceId',
        child: (_, state) => SentenceDetailScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
          sentenceId: state.pathParameters['sentenceId'] ?? '',
        ),
      ),
      _drillRoute(
        path: '/practice/:char/:name',
        child: (_, state) => PracticeScreen(
          letterChar: state.pathParameters['char'] ?? '',
          letterName: state.pathParameters['name'] ?? '',
          startInTrace: state.uri.queryParameters['mode'] == 'trace',
        ),
      ),
      _modalRoute(
        path: '/translate',
        child: (_, _) => const AiTranslatorScreen(),
      ),
      _peerRoute(
        path: '/privacy',
        name: RouteNames.privacy,
        child: (_, _) =>
            const LegalDocumentScreen(type: LegalDocumentType.privacy),
      ),
      _peerRoute(
        path: '/terms',
        name: RouteNames.terms,
        child: (_, _) =>
            const LegalDocumentScreen(type: LegalDocumentType.terms),
      ),
      _drillRoute(
        path: '/quiz/:quizId',
        name: RouteNames.quiz,
        child: (_, state) =>
            QuizScreen(quizId: state.pathParameters['quizId'] ?? ''),
      ),
      _modalRoute(
        path: '/admin/login',
        name: RouteNames.adminLogin,
        child: (_, _) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          adminRoute(
            path: '/admin',
            name: RouteNames.admin,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          adminRoute(
            path: '/admin/categories',
            builder: (context, state) => const AdminCategoriesScreen(),
          ),
          adminRoute(
            path: '/admin/banners',
            builder: (context, state) => const AdminBannersScreen(),
          ),
          adminRoute(
            path: '/admin/letters',
            builder: (context, state) => const AdminLettersScreen(),
          ),
          adminRoute(
            path: '/admin/lessons',
            builder: (context, state) => const AdminLessonsScreen(),
          ),
          adminRoute(
            path: '/admin/lessons/content/:lessonId',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId'] ?? '';
              return AdminLessonContentScreen(lessonId: lessonId);
            },
          ),
          adminRoute(
            path: '/admin/numbers',
            builder: (context, state) => const AdminNumbersScreen(),
          ),
          adminRoute(
            path: '/admin/words',
            builder: (context, state) => const AdminWordsScreen(),
          ),
          adminRoute(
            path: '/admin/sentences',
            builder: (context, state) => const AdminSentencesScreen(),
          ),
          adminRoute(
            path: '/admin/quizzes',
            builder: (context, state) => const AdminQuizzesScreen(),
          ),
          adminRoute(
            path: '/admin/rhymes',
            builder: (context, state) => const AdminRhymesScreen(),
          ),
          adminRoute(
            path: '/admin/rhymes/categories',
            builder: (context, state) => const AdminRhymeCategoriesScreen(),
          ),
          adminRoute(
            path: '/admin/media',
            builder: (context, state) => const AdminMediaScreen(),
          ),
          adminRoute(
            path: '/admin/audio',
            builder: (context, state) =>
                const AdminMediaScreen(initialType: MediaType.audio),
          ),
          adminRoute(
            path: '/admin/video',
            builder: (context, state) =>
                const AdminMediaScreen(initialType: MediaType.video),
          ),
          adminRoute(
            path: '/admin/settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
          adminRoute(
            path: '/admin/access',
            builder: (context, state) => const AdminAccessScreen(),
          ),
          adminRoute(
            path: '/admin/gamification',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'overview'),
          ),
          adminRoute(
            path: '/admin/gamification/copy',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'copy'),
          ),
          adminRoute(
            path: '/admin/gamification/badges',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'badges'),
          ),
          adminRoute(
            path: '/admin/gamification/circles',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'circles'),
          ),
          adminRoute(
            path: '/admin/gamification/circles/templates',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'circle_templates'),
          ),
          adminRoute(
            path: '/admin/gamification/events',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'circle_events'),
          ),
          adminRoute(
            path: '/admin/gamification/missions',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'missions'),
          ),
          adminRoute(
            path: '/admin/gamification/rewards',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'rewards'),
          ),
          adminRoute(
            path: '/admin/gamification/quiz-feedback',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'quiz_feedback'),
          ),
          adminRoute(
            path: '/admin/gamification/bakhed/lyrics',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'bakhed_lyrics'),
          ),
          adminRoute(
            path: '/admin/gamification/bakhed/vocabulary',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'bakhed_vocabulary'),
          ),
          adminRoute(
            path: '/admin/gamification/bakhed/cultural-notes',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'bakhed_notes'),
          ),
          adminRoute(
            path: '/admin/gamification/config',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'config'),
          ),
          adminRoute(
            path: '/admin/audit-logs',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'audit_logs'),
          ),
          adminRoute(
            path: '/admin/analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
          adminRoute(
            path: '/admin/maintenance',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'maintenance'),
          ),
        ],
      ),
    ],
  );
});
