import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/oauth_sanitizer.dart';
import '../../../../app/router/route_guards.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
      }

      // 1. Check for OAuth token in URL params (after Google sign-in redirect on web)
      if (kIsWeb) {
        final uri = Uri.base;
        var userId =
            uri.queryParameters['userId'] ?? uri.queryParameters['key'];
        var secret = uri.queryParameters['secret'];

        if (userId == null || secret == null) {
          try {
            final routerState = GoRouterState.of(context);
            userId ??=
                routerState.uri.queryParameters['userId'] ??
                routerState.uri.queryParameters['key'];
            secret ??= routerState.uri.queryParameters['secret'];
          } catch (e) {
            AppLogger.debug('Splash: Could not read GoRouter state: $e');
          }
        }

        if (userId != null && secret != null) {
          OAuthSanitizer.sanitizeUrlHistory();

          AppLogger.debug(
            'Splash: Found OAuth token, exchanging for session...',
          );
          final authService = ref.read(appwriteAuthServiceProvider);
          final success = await authService.exchangeOAuthToken(userId, secret);

          if (success) {
            AppLogger.debug(
              'Splash: OAuth token exchange succeeded, navigating to /',
            );
            ref.read(onboardingProvider.notifier).completeOnboarding();
            try {
              final _ = await ref.refresh(isAuthenticatedProvider.future);
              ref.invalidate(currentUserProvider);
            } catch (_) {}
            targetLocation = '/';
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
          final isLoggedInResult = await authRepo.isLoggedIn().timeout(
            const Duration(seconds: 4),
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
          } catch (_) {}
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
