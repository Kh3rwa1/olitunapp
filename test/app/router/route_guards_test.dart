import 'package:flutter_test/flutter_test.dart';
import 'package:itun/app/router/route_guards.dart';

void main() {
  group('adminHostRedirectFor', () {
    test('never redirects for a non-admin host', () {
      expect(adminHostRedirectFor('olitun.in', '/privacy'), isNull);
      expect(adminHostRedirectFor('www.olitun.in', '/lessons'), isNull);
      expect(adminHostRedirectFor('', '/admin'), isNull);
    });

    test('keeps admin paths on the admin host', () {
      expect(adminHostRedirectFor('admin.olitun.in', '/admin'), isNull);
      expect(adminHostRedirectFor('admin.olitun.in', '/admin/login'), isNull);
      expect(adminHostRedirectFor('admin.olitun.in', '/admin/review'), isNull);
    });

    test('bounces non-admin paths to the admin shell', () {
      expect(adminHostRedirectFor('admin.olitun.in', '/'), '/admin');
      expect(adminHostRedirectFor('admin.olitun.in', '/privacy'), '/admin');
      expect(
        adminHostRedirectFor('admin.olitun.in', '/lessons/lesson_1'),
        '/admin',
      );
    });

    test('matches the admin host case-insensitively', () {
      expect(adminHostRedirectFor('Admin.Olitun.IN', '/privacy'), '/admin');
    });
  });

  group('fragmentRedirectFor', () {
    test('ignores fragments on non-web platforms', () {
      expect(
        fragmentRedirectFor(isWeb: false, path: '/', fragment: '/lessons'),
        isNull,
      );
    });

    test('ignores fragments on deep paths (only root uses them)', () {
      expect(
        fragmentRedirectFor(
          isWeb: true,
          path: '/privacy',
          fragment: '/lessons',
        ),
        isNull,
      );
    });

    test('redirects a rooted fragment at the root path', () {
      expect(
        fragmentRedirectFor(isWeb: true, path: '/', fragment: '/lessons'),
        '/lessons',
      );
    });

    test(
      'redirects a rooted fragment on /splash and /welcome startup paths',
      () {
        expect(
          fragmentRedirectFor(isWeb: true, path: '/splash', fragment: '/admin'),
          '/admin',
        );
        expect(
          fragmentRedirectFor(
            isWeb: true,
            path: '/welcome',
            fragment: '/admin/login',
          ),
          '/admin/login',
        );
      },
    );

    test('prefers the captured initial hash over the live fragment', () {
      expect(
        fragmentRedirectFor(
          isWeb: true,
          path: '/',
          fragment: '/live',
          initialHash: '/initial',
        ),
        '/initial',
      );
    });

    test('falls back to the live fragment when no initial hash exists', () {
      expect(
        fragmentRedirectFor(
          isWeb: true,
          path: '/',
          fragment: '/live',
          initialHash: '',
        ),
        '/live',
      );
    });

    test('rejects empty and non-path fragments', () {
      expect(fragmentRedirectFor(isWeb: true, path: '/', fragment: ''), isNull);
      expect(
        fragmentRedirectFor(isWeb: true, path: '/', fragment: 'lessons'),
        isNull,
      );
    });

    test('rejects protocol-relative and backslash open-redirect tricks', () {
      expect(
        fragmentRedirectFor(isWeb: true, path: '/', fragment: '//evil.test'),
        isNull,
      );
      expect(
        fragmentRedirectFor(isWeb: true, path: '/', fragment: '/\\evil.test'),
        isNull,
      );
    });
  });

  group('adminAccessRedirectFor', () {
    test('allows public routes for everyone', () {
      expect(adminAccessRedirectFor(isAdmin: false, path: '/lessons'), isNull);
      expect(adminAccessRedirectFor(isAdmin: false, path: '/'), isNull);
    });

    test('always allows the admin login route', () {
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin/login'),
        isNull,
      );
      expect(
        adminAccessRedirectFor(isAdmin: true, path: '/admin/login'),
        isNull,
      );
    });

    test('bounces non-admins from admin routes to the login page', () {
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin'),
        '/admin/login',
      );
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin/review'),
        '/admin/login',
      );
    });

    test('lets admins through to admin routes', () {
      expect(adminAccessRedirectFor(isAdmin: true, path: '/admin'), isNull);
      expect(
        adminAccessRedirectFor(isAdmin: true, path: '/admin/review'),
        isNull,
      );
    });
  });
}
