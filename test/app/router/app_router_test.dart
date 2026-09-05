import 'package:flutter_test/flutter_test.dart';
import 'package:itun/app/router/app_router.dart';
import 'package:itun/features/main/presentation/main_shell_screen.dart';

void main() {
  group('Router Guards & Redirect Invariants', () {
    test('adminHostRedirectFor redirects admin host root to /admin', () {
      expect(adminHostRedirectFor('admin.olitun.in', '/'), '/admin');
      expect(adminHostRedirectFor('admin.olitun.in', '/admin'), isNull);
      expect(
        adminHostRedirectFor('admin.olitun.in', '/admin/categories'),
        isNull,
      );
      expect(adminHostRedirectFor('olitun.in', '/'), isNull);
    });

    test('fragmentRedirectFor extracts hash location on web startup', () {
      final redirect = fragmentRedirectFor(
        isWeb: true,
        path: '/',
        fragment: '/categories',
        initialHash: '/categories',
      );
      expect(redirect, '/categories');
    });

    test('fragmentRedirectFor rejects non-web or non-root paths', () {
      expect(
        fragmentRedirectFor(isWeb: false, path: '/', fragment: '/categories'),
        isNull,
      );
      expect(
        fragmentRedirectFor(
          isWeb: true,
          path: '/categories',
          fragment: '/categories',
        ),
        isNull,
      );
    });

    test('adminAccessRedirectFor blocks non-admin users from admin routes', () {
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin'),
        '/admin/login',
      );
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin/categories'),
        '/admin/login',
      );
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin/login'),
        isNull,
      );
    });

    test('adminAccessRedirectFor allows authenticated admin users', () {
      expect(adminAccessRedirectFor(isAdmin: true, path: '/admin'), isNull);
      expect(
        adminAccessRedirectFor(isAdmin: true, path: '/admin/categories'),
        isNull,
      );
    });

    group('authAndOnboardingRedirectFor', () {
      test('unauthenticated users cannot access protected routes', () {
        expect(
          authAndOnboardingRedirectFor(
            path: '/',
            isAuth: false,
            showOnboarding: false,
          ),
          '/welcome',
        );
        expect(
          authAndOnboardingRedirectFor(
            path: '/categories',
            isAuth: false,
            showOnboarding: false,
          ),
          '/welcome',
        );
        expect(
          authAndOnboardingRedirectFor(
            path: '/onboarding',
            isAuth: false,
            showOnboarding: true,
          ),
          '/welcome',
        );
      });

      test('unauthenticated users can access public auth and legal routes', () {
        expect(
          authAndOnboardingRedirectFor(
            path: '/welcome',
            isAuth: false,
            showOnboarding: true,
          ),
          isNull,
        );
        expect(
          authAndOnboardingRedirectFor(
            path: '/login',
            isAuth: false,
            showOnboarding: true,
          ),
          isNull,
        );
        expect(
          authAndOnboardingRedirectFor(
            path: '/splash',
            isAuth: false,
            showOnboarding: true,
          ),
          isNull,
        );
        expect(
          authAndOnboardingRedirectFor(
            path: '/privacy',
            isAuth: false,
            showOnboarding: true,
          ),
          isNull,
        );
        expect(
          authAndOnboardingRedirectFor(
            path: '/terms',
            isAuth: false,
            showOnboarding: true,
          ),
          isNull,
        );
      });

      test(
        'authenticated users on welcome or login are routed away from login',
        () {
          expect(
            authAndOnboardingRedirectFor(
              path: '/welcome',
              isAuth: true,
              showOnboarding: false,
            ),
            '/',
          );
          expect(
            authAndOnboardingRedirectFor(
              path: '/welcome',
              isAuth: true,
              showOnboarding: true,
            ),
            '/onboarding',
          );
          expect(
            authAndOnboardingRedirectFor(
              path: '/login',
              isAuth: true,
              showOnboarding: false,
            ),
            '/',
          );
          expect(
            authAndOnboardingRedirectFor(
              path: '/login',
              isAuth: true,
              showOnboarding: true,
            ),
            '/onboarding',
          );
        },
      );

      test(
        'authenticated users needing onboarding are gated to /onboarding',
        () {
          expect(
            authAndOnboardingRedirectFor(
              path: '/',
              isAuth: true,
              showOnboarding: true,
            ),
            '/onboarding',
          );
          expect(
            authAndOnboardingRedirectFor(
              path: '/onboarding',
              isAuth: true,
              showOnboarding: true,
            ),
            isNull,
          );
        },
      );

      test(
        'authenticated users with onboarding completed access home directly',
        () {
          expect(
            authAndOnboardingRedirectFor(
              path: '/',
              isAuth: true,
              showOnboarding: false,
            ),
            isNull,
          );
        },
      );
    });
  });

  group('StatefulShellRoute & Deep Links', () {
    test('shellTabIndexForPath maps all main shell branches', () {
      expect(shellTabIndexForPath('/'), 0);
      expect(shellTabIndexForPath('/categories'), 0);
      expect(shellTabIndexForPath('/bakhed'), 1);
      expect(shellTabIndexForPath('/profile'), 2);
      expect(shellTabIndexForPath('/other'), isNull);
    });
  });
}
