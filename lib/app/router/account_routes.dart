import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/profile/presentation/settings_screen.dart';

List<RouteBase> buildAccountRoutes({
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) child,
  })
  drillRoute,
}) {
  return [
    drillRoute(path: '/settings', child: (_, _) => const SettingsScreen()),
  ];
}
