import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/main/presentation/main_shell_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import 'route_names.dart';

List<RouteBase> buildAccountRoutes({
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) child,
  })
  shellRoute,
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) child,
  })
  drillRoute,
}) {
  return [
    shellRoute(
      path: '/profile',
      name: RouteNames.profile,
      child: (_, _) => const MainShellScreen(),
    ),
    drillRoute(path: '/settings', child: (_, _) => const SettingsScreen()),
  ];
}
