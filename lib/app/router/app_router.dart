import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/home/presentation/screens/ai_translator_screen.dart';
import '../../features/legal/presentation/legal_document_screen.dart';
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
import '../../features/admin/presentation/admin_media_screen.dart';
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
      builder: builder,
    );
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) =>
        adminHostRedirectFor(Uri.base.host, state.uri.path),
    routes: [
      _peerRoute(
        path: '/splash',
        name: RouteNames.splash,
        child: (_, __) => const SplashScreen(),
      ),
      _peerRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        child: (_, __) => const WelcomeScreen(),
      ),
      _modalRoute(
        path: '/login',
        name: RouteNames.login,
        child: (_, __) => const EmailAuthScreen(),
      ),
      _peerRoute(
        path: '/',
        name: RouteNames.home,
        child: (_, __) => const MainShellScreen(),
      ),
      _peerRoute(
        path: '/categories',
        name: RouteNames.categories,
        child: (_, __) => const MainShellScreen(),
      ),
      _drillRoute(path: '/quizzes', child: (_, __) => const QuizListScreen()),
      _peerRoute(
        path: '/profile',
        name: RouteNames.profile,
        child: (_, __) => const MainShellScreen(),
      ),
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
        ),
      ),
      _modalRoute(
        path: '/translate',
        child: (_, __) => const AiTranslatorScreen(),
      ),
      _peerRoute(
        path: '/privacy',
        name: RouteNames.privacy,
        child: (_, __) =>
            const LegalDocumentScreen(type: LegalDocumentType.privacy),
      ),
      _peerRoute(
        path: '/terms',
        name: RouteNames.terms,
        child: (_, __) =>
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
        child: (_, __) => const AdminLoginScreen(),
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
        ],
      ),
    ],
  );
});
