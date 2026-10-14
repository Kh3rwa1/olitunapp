import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/admin_screens.dart' deferred as admin;
import 'deferred_route.dart';
import 'route_names.dart';

/// The admin CMS is a separate deferred load unit; it is fetched the first
/// time any `/admin` route is built.
final DeferredLibrary adminLibrary = DeferredLibrary(admin.loadLibrary);

Widget _deferred(Widget Function() builder) =>
    DeferredRoute(library: adminLibrary, builder: (_) => builder());

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
      child: (_, _) => _deferred(admin.loginScreen),
    ),
    ShellRoute(
      builder: (context, state, child) => _deferred(() => admin.shell(child)),
      routes: [
        adminRoute(
          path: '/admin',
          name: RouteNames.admin,
          builder: (context, state) => _deferred(admin.dashboardScreen),
        ),
        adminRoute(
          path: '/admin/translations',
          builder: (context, state) => _deferred(admin.translationsScreen),
        ),
        adminRoute(
          path: '/admin/categories',
          builder: (context, state) => _deferred(admin.categoriesScreen),
        ),
        adminRoute(
          path: '/admin/banners',
          builder: (context, state) => _deferred(admin.bannersScreen),
        ),
        adminRoute(
          path: '/admin/letters',
          builder: (context, state) => _deferred(
            () => admin.lettersScreen(state.uri.queryParameters['categoryId']),
          ),
        ),
        adminRoute(
          path: '/admin/alphabets',
          builder: (context, state) => _deferred(
            () => admin.lettersScreen(state.uri.queryParameters['categoryId']),
          ),
        ),
        adminRoute(
          path: '/admin/lessons',
          builder: (context, state) => _deferred(
            () => admin.lessonsScreen(state.uri.queryParameters['categoryId']),
          ),
        ),
        adminRoute(
          path: '/admin/lessons/content/:lessonId',
          builder: (context, state) {
            final lessonId = state.pathParameters['lessonId'] ?? '';
            return _deferred(() => admin.lessonContentScreen(lessonId));
          },
        ),
        adminRoute(
          path: '/admin/numbers',
          builder: (context, state) => _deferred(
            () => admin.numbersScreen(state.uri.queryParameters['categoryId']),
          ),
        ),
        adminRoute(
          path: '/admin/words',
          builder: (context, state) => _deferred(
            () => admin.wordsScreen(state.uri.queryParameters['categoryId']),
          ),
        ),
        adminRoute(
          path: '/admin/sentences',
          builder: (context, state) => _deferred(
            () =>
                admin.sentencesScreen(state.uri.queryParameters['categoryId']),
          ),
        ),
        adminRoute(
          path: '/admin/quizzes',
          builder: (context, state) => _deferred(admin.quizzesScreen),
        ),
        adminRoute(
          path: '/admin/rhymes',
          builder: (context, state) => _deferred(
            () =>
                admin.bakhedHubScreen(state.uri.queryParameters['categoryId']),
          ),
        ),
        adminRoute(
          path: '/admin/bakhed/editor/:id',
          builder: (context, state) => _deferred(
            () => admin.bakhedEditorScreen(state.pathParameters['id'] ?? ''),
          ),
        ),
        adminRoute(
          path: '/admin/media',
          builder: (context, state) => _deferred(admin.mediaScreen),
        ),
        adminRoute(
          path: '/admin/audio',
          builder: (context, state) =>
              _deferred(() => admin.mediaScreen(mediaType: 'audio')),
        ),
        adminRoute(
          path: '/admin/video',
          builder: (context, state) =>
              _deferred(() => admin.mediaScreen(mediaType: 'video')),
        ),
        adminRoute(
          path: '/admin/settings',
          builder: (context, state) => _deferred(admin.settingsScreen),
        ),
        adminRoute(
          path: '/admin/access',
          builder: (context, state) => _deferred(admin.accessScreen),
        ),
        adminRoute(
          path: '/admin/gamification',
          builder: (context, state) =>
              _deferred(() => admin.gamificationScreen('overview')),
        ),
        adminRoute(
          path: '/admin/gamification/badges',
          builder: (context, state) =>
              _deferred(() => admin.gamificationScreen('badges')),
        ),
        adminRoute(
          path: '/admin/gamification/config',
          builder: (context, state) =>
              _deferred(() => admin.gamificationScreen('config')),
        ),
        adminRoute(
          path: '/admin/audit-logs',
          builder: (context, state) =>
              _deferred(() => admin.gamificationScreen('audit_logs')),
        ),
        adminRoute(
          path: '/admin/analytics',
          builder: (context, state) => _deferred(admin.analyticsScreen),
        ),
        adminRoute(
          path: '/admin/maintenance',
          builder: (context, state) =>
              _deferred(() => admin.gamificationScreen('maintenance')),
        ),
        adminRoute(
          path: '/admin/purchases',
          builder: (context, state) => _deferred(admin.purchasesScreen),
        ),
        adminRoute(
          path: '/admin/binti-waitlist',
          builder: (context, state) => _deferred(admin.bintiWaitlistScreen),
        ),
        adminRoute(
          path: '/admin/review',
          builder: (context, state) => _deferred(admin.reviewScreen),
        ),
      ],
    ),
  ];
}
