import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/legal/presentation/legal_document_screen.dart';
import 'route_names.dart';

List<RouteBase> buildPublicRoutes({
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) child,
  })
  peerRoute,
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) child,
  })
  modalRoute,
}) {
  return [
    peerRoute(
      path: '/splash',
      name: RouteNames.splash,
      child: (_, _) => const SplashScreen(),
    ),
    peerRoute(
      path: '/welcome',
      name: RouteNames.welcome,
      child: (_, _) => const WelcomeScreen(),
    ),
    peerRoute(
      path: '/onboarding',
      name: RouteNames.onboarding,
      child: (_, _) => const OnboardingScreen(),
    ),
    modalRoute(
      path: '/login',
      name: RouteNames.login,
      child: (_, _) => const EmailAuthScreen(),
    ),
    peerRoute(
      path: '/privacy',
      name: RouteNames.privacy,
      child: (_, _) =>
          const LegalDocumentScreen(type: LegalDocumentType.privacy),
    ),
    peerRoute(
      path: '/terms',
      name: RouteNames.terms,
      child: (_, _) => const LegalDocumentScreen(type: LegalDocumentType.terms),
    ),
  ];
}
