import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/oauth_sanitizer.dart';
import '../../../../app/router/route_guards.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../providers/onboarding_provider.dart';

class SplashController {
  static Future<String?> determineInitialLocation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    AppLogger.debug('Splash: starting determineInitialLocation');
    String? targetLocation;

    try {
      if (kIsWeb) {
        final hash = (initialWebHash != null && initialWebHash!.isNotEmpty)
            ? initialWebHash
            : Uri.base.fragment;
        if (hash != null && hash.startsWith('/admin')) {
          AppLogger.debug('Splash: Admin hash target requested: $hash');
          return hash;
        }
        final path = Uri.base.path;
        if (path.startsWith('/admin')) {
          AppLogger.debug('Splash: Admin path target requested: $path');
          return path;
        }
        if (Uri.base.host.toLowerCase() == 'admin.olitun.in') {
          AppLogger.debug(
            'Splash: Admin host detected, routing to /admin/login',
          );
          return '/admin/login';
        }
      }

      // 1. Check for the Worker's one-time login code in URL params (after
      // the Google sign-in redirect on web).
      if (kIsWeb) {
        const codeParam = AppwriteAuthService.webLoginCodeParam;
        var code = Uri.base.queryParameters[codeParam];

        if (code == null) {
          try {
            final routerState = GoRouterState.of(context);
            code = routerState.uri.queryParameters[codeParam];
          } catch (e) {
            AppLogger.debug('Splash: Could not read GoRouter state: $e');
          }
        }

        if (code != null && code.isNotEmpty) {
          OAuthSanitizer.sanitizeUrlHistory();

          AppLogger.debug(
            'Splash: Found Google login code, exchanging for session...',
          );
          final authService = ref.read(appwriteAuthServiceProvider);
          final success = await authService.exchangeLoginCode(code);

          if (success) {
            AppLogger.debug('Splash: OAuth token exchange succeeded');
            try {
              final _ = await ref.refresh(isAuthenticatedProvider.future);
              ref.invalidate(currentUserProvider);
            } catch (e) {
              AppLogger.debug(
                'Refreshing auth state after OAuth exchange failed: $e',
                name: 'Splash',
              );
            }
            // Respect first-run onboarding instead of silently completing it:
            // new web users must see /onboarding like every other flow.
            final showOnboarding = ref.read(onboardingProvider);
            AppLogger.debug(
              'Splash: OAuth done, showOnboarding=$showOnboarding',
            );
            targetLocation = showOnboarding ? '/onboarding' : '/';
          } else {
            AppLogger.debug('Splash: OAuth token exchange failed');
          }
        }
      }

      if (targetLocation == null) {
        // 2. Check authentication before onboarding
        AppLogger.debug('Splash: checking auth status...');
        final authRepo = ref.read(authRepositoryProvider);
        bool isLoggedIn = false;
        try {
          // Usually instant (local session). Longer only for the one-time
          // move of an Appwrite-era session to Worker sign-in.
          final isLoggedInResult = await authRepo.isLoggedIn().timeout(
            const Duration(seconds: 10),
          );
          isLoggedIn = isLoggedInResult.getOrElse((_) => false);
        } catch (e) {
          AppLogger.debug(
            'Splash: auth check failed/timed out, treating as logged out: $e',
          );
        }
        AppLogger.debug('Splash: isLoggedIn = $isLoggedIn');

        if (isLoggedIn) {
          try {
            final _ = await ref.refresh(isAuthenticatedProvider.future);
            ref.invalidate(currentUserProvider);
          } catch (e) {
            AppLogger.debug('Refreshing auth state failed: $e', name: 'Splash');
          }
          ref.read(onboardingProvider.notifier).completeOnboarding();
          targetLocation = '/';
        } else {
          AppLogger.debug('Splash: User unauthenticated, routing to /welcome');
          targetLocation = '/welcome';
        }
      }
    } catch (e, stack) {
      AppLogger.debug('Splash error: $e\n$stack');
      targetLocation = '/welcome';
    }

    return targetLocation;
  }
}
