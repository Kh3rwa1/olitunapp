import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/admin/presentation/review/admin_review_screen.dart';
import 'route_names.dart';

List<RouteBase> buildAdminRoutes({
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) child,
  })
  modalRoute,
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) builder,
  })
  adminRoute,
}) {
  return [
    modalRoute(
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
        adminRoute(
          path: '/admin/review',
          builder: (context, state) => const AdminReviewScreen(),
        ),
      ],
    ),
  ];
}
