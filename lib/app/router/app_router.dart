import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../core/motion/page_transitions.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/main/presentation/main_shell_screen.dart';
import '../../features/lessons/presentation/category_lessons_screen.dart';
import '../../features/lessons/presentation/lesson_block_detail_screen.dart';
import '../../features/lessons/presentation/practice/practice_screen.dart';
import '../../features/content/presentation/content_detail_screen.dart';
import '../../features/learn/presentation/screens/content_grid_screen.dart';
import '../../shared/models/content_item.dart';

import '../../features/quiz/presentation/quiz_list_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import '../../features/quiz/presentation/mistake_review_screen.dart';
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
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/admin/presentation/admin_media_screen.dart';
import '../../features/admin/presentation/affirmations/admin_affirmations_screen.dart';
import '../../features/admin/presentation/purchases/admin_purchases_screen.dart';
import '../../features/admin/presentation/binti_waitlist/admin_binti_waitlist_screen.dart';
import '../../features/admin/presentation/access/admin_access_screen.dart';
import '../../features/admin/presentation/analytics/admin_analytics_screen.dart';
import '../../features/admin/presentation/gamification/admin_gamification_screen.dart';
import '../../features/admin/presentation/bakhed/bakhed_hub_screen.dart';
import '../../features/admin/presentation/bakhed/bakhed_editor_screen.dart';
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

/// Web-only global variable that captures the hash fragment at the very start of main()
/// before any URL strategy or routing initialization can modify or strip it.
String? initialWebHash;

@visibleForTesting
String? fragmentRedirectFor({
  required bool isWeb,
  required String path,
  required String fragment,
  String? initialHash,
}) {
  if (!isWeb || path != '/') return null;
  final hash = (initialHash != null && initialHash.isNotEmpty)
      ? initialHash
      : fragment;
  if (hash.isNotEmpty &&
      hash.startsWith('/') &&
      !hash.startsWith('//') &&
      !hash.startsWith('/\\')) {
    return hash;
  }
  return null;
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
    initialLocation: '/splash',
    redirect: (context, state) {
      final hostRedirect = adminHostRedirectFor(Uri.base.host, state.uri.path);
      if (hostRedirect != null) return hostRedirect;

      final fragRedirect = fragmentRedirectFor(
        isWeb: kIsWeb,
        path: state.uri.path,
        fragment: Uri.base.fragment,
        initialHash: initialWebHash,
      );
      if (fragRedirect != null) {
        initialWebHash =
            null; // Clear it so it acts as a one-time startup redirect
        return fragRedirect;
      }

      // On Web: if OAuth token is present, route to /splash to exchange it
      if (kIsWeb) {
        final userId =
            state.uri.queryParameters['userId'] ??
            state.uri.queryParameters['key'];
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
          path == '/onboarding' ||
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
      _peerRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        child: (_, _) => const OnboardingScreen(),
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
      GoRoute(
        path: '/lesson/:lessonId',
        redirect: (context, state) {
          final id = state.pathParameters['lessonId'];
          return '/lesson/$id/block/0';
        },
      ),
      _drillRoute(
        path: '/lesson/:lessonId/block/:blockIndex',
        child: (_, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          final blockIndexStr = state.pathParameters['blockIndex'] ?? '0';
          final blockIndex = int.tryParse(blockIndexStr) ?? 0;
          return LessonBlockDetailScreen(
            lessonId: lessonId,
            initialBlockIndex: blockIndex,
          );
        },
      ),
      // ORDER MATTERS: standalone routes MUST be declared before the
      // /:lessonId/:letterId catch-all. GoRouter matches in declaration order,
      // first match wins. Reordering this block will reintroduce the
      // subcategory-fallback regression (see phase1_subcategory_fallback_regression_audit.md).
      _drillRoute(
        path: '/letter/standalone/:subcategoryId',
        child: (_, state) {
          final pathParam = state.pathParameters['subcategoryId'];
          final subcategoryId = pathParam == 'all' ? null : pathParam;
          return ContentGridScreen(
            kind: ContentKind.letter,
            subcategoryId: subcategoryId,
          );
        },
      ),
      _drillRoute(
        path: '/number/standalone/:subcategoryId',
        child: (_, state) {
          final pathParam = state.pathParameters['subcategoryId'];
          final subcategoryId = pathParam == 'all' ? null : pathParam;
          return ContentGridScreen(
            kind: ContentKind.number,
            subcategoryId: subcategoryId,
          );
        },
      ),
      GoRoute(
        path: '/letter/:lessonId/:letterId',
        redirect: (context, state) {
          final id = state.pathParameters['letterId'];
          return '/content/letter/$id';
        },
      ),
      GoRoute(
        path: '/word/:lessonId/:wordId',
        redirect: (context, state) {
          final id = state.pathParameters['wordId'];
          return '/content/word/$id';
        },
      ),
      GoRoute(
        path: '/number/:lessonId/:numberId',
        redirect: (context, state) {
          final id = state.pathParameters['numberId'];
          return '/content/number/$id';
        },
      ),
      GoRoute(
        path: '/sentence/:lessonId/:sentenceId',
        redirect: (context, state) {
          final id = state.pathParameters['sentenceId'];
          return '/content/sentence/$id';
        },
      ),
      _drillRoute(
        path: '/content/:kind/:id',
        child: (_, state) {
          final kindStr = state.pathParameters['kind'] ?? 'lesson';
          final id = state.pathParameters['id'] ?? '';
          final kind = ContentKind.fromString(kindStr);
          return ContentDetailScreen(kind: kind, id: id);
        },
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
            builder: (context, state) => AdminLettersScreen(
              categoryId: state.uri.queryParameters['categoryId'],
            ),
          ),
          adminRoute(
            path: '/admin/lessons',
            builder: (context, state) => AdminLessonsScreen(
              categoryId: state.uri.queryParameters['categoryId'],
            ),
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
            builder: (context, state) => AdminNumbersScreen(
              categoryId: state.uri.queryParameters['categoryId'],
            ),
          ),
          adminRoute(
            path: '/admin/words',
            builder: (context, state) => AdminWordsScreen(
              categoryId: state.uri.queryParameters['categoryId'],
            ),
          ),
          adminRoute(
            path: '/admin/sentences',
            builder: (context, state) => AdminSentencesScreen(
              categoryId: state.uri.queryParameters['categoryId'],
            ),
          ),
          adminRoute(
            path: '/admin/quizzes',
            builder: (context, state) => const AdminQuizzesScreen(),
          ),
          adminRoute(
            path: '/admin/rhymes',
            builder: (context, state) => BakhedHubScreen(
              categoryId: state.uri.queryParameters['categoryId'],
            ),
          ),
          adminRoute(
            path: '/admin/bakhed/editor/:id',
            builder: (context, state) =>
                BakhedEditorScreen(bakhedId: state.pathParameters['id'] ?? ''),
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
            path: '/admin/gamification/badges',
            builder: (context, state) =>
                const AdminGamificationScreen(section: 'badges'),
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
          adminRoute(
            path: '/admin/affirmations',
            builder: (context, state) => const AdminAffirmationsScreen(),
          ),
          adminRoute(
            path: '/admin/purchases',
            builder: (context, state) => const AdminPurchasesScreen(),
          ),
          adminRoute(
            path: '/admin/binti-waitlist',
            builder: (context, state) => const AdminBintiWaitlistScreen(),
          ),
        ],
      ),
    ],
  );
});
