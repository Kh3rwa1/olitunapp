import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/motion/page_transitions.dart';
import '../../features/admin/providers/admin_auth_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/main/presentation/main_shell_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/profile/presentation/progress_screen.dart';
import '../../features/rhymes/presentation/rhyme_screen.dart';
import 'account_routes.dart';
import 'admin_routes.dart';
import 'learning_routes.dart';
import 'public_routes.dart';
import 'route_guards.dart';
import 'route_names.dart';

export 'route_guards.dart';
export 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Convenience: builds a GoRoute whose `pageBuilder` wraps the screen
/// in our shared-axis Z transition. Used for content "drill-in" routes.
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Learn / Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: RouteNames.home,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'categories',
                    name: RouteNames.categories,
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: HomeScreen()),
                  ),
                ],
              ),
            ],
          ),
          // Branch 1: Bakhed / Rhymes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bakhed',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: RhymeScreen()),
              ),
            ],
          ),
          // Branch 2: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProgressScreen()),
              ),
            ],
          ),
        ],
      ),
      ...buildPublicRoutes(peerRoute: _peerRoute, modalRoute: _modalRoute),
      ...buildLearningRoutes(drillRoute: _drillRoute, modalRoute: _modalRoute),
      ...buildAccountRoutes(drillRoute: _drillRoute),
      ...buildAdminRoutes(modalRoute: _modalRoute, adminRoute: adminRoute),
    ],
  );
});
