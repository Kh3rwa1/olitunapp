import 'package:flutter_test/flutter_test.dart';
import 'package:itun/app/router/app_router.dart';
import 'package:itun/features/main/presentation/main_shell/main_shell_screen.dart';

void main() {
  group('adminHostRedirectFor', () {
    test('routes admin subdomain root traffic to the admin panel', () {
      expect(adminHostRedirectFor('admin.olitun.in', '/'), '/admin');
      expect(adminHostRedirectFor('admin.olitun.in', '/splash'), '/admin');
      expect(adminHostRedirectFor('admin.olitun.in', '/welcome'), '/admin');
    });

    test('leaves admin routes and other hosts untouched', () {
      expect(adminHostRedirectFor('admin.olitun.in', '/admin'), isNull);
      expect(adminHostRedirectFor('admin.olitun.in', '/admin/login'), isNull);
      expect(adminHostRedirectFor('olitun.in', '/'), isNull);
      expect(adminHostRedirectFor('localhost', '/splash'), isNull);
    });
  });

  group('adminAccessRedirectFor', () {
    test('redirects non-admin users away from every admin content route', () {
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin'),
        '/admin/login',
      );
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin/categories'),
        '/admin/login',
      );
      expect(
        adminAccessRedirectFor(
          isAdmin: false,
          path: '/admin/lessons/content/lesson_1',
        ),
        '/admin/login',
      );
    });

    test('allows admin users and leaves non-admin areas alone', () {
      expect(adminAccessRedirectFor(isAdmin: true, path: '/admin'), isNull);
      expect(
        adminAccessRedirectFor(isAdmin: true, path: '/admin/settings'),
        isNull,
      );
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/admin/login'),
        isNull,
      );
      expect(
        adminAccessRedirectFor(isAdmin: false, path: '/lessons/cat_alphabet'),
        isNull,
      );
    });
  });

  group('shellTabIndexForPath', () {
    test('maps shell routes to their visible tabs', () {
      expect(shellTabIndexForPath('/'), 0);
      expect(shellTabIndexForPath('/bakhed'), 1);
      expect(shellTabIndexForPath('/profile'), 2);
    });

    test('ignores routes handled outside the shell tabs', () {
      expect(shellTabIndexForPath('/lesson/abc'), isNull);
      expect(shellTabIndexForPath('/admin'), isNull);
    });
  });

  group('fragmentRedirectFor', () {
    test('returns null if not on web', () {
      expect(
        fragmentRedirectFor(isWeb: false, path: '/', fragment: '/admin/login'),
        isNull,
      );
    });

    test('returns null if path is not root /', () {
      expect(
        fragmentRedirectFor(
          isWeb: true,
          path: '/welcome',
          fragment: '/admin/login',
        ),
        isNull,
      );
    });

    test('returns null if fragment is empty', () {
      expect(fragmentRedirectFor(isWeb: true, path: '/', fragment: ''), isNull);
    });

    test('returns null if fragment does not start with /', () {
      expect(
        fragmentRedirectFor(isWeb: true, path: '/', fragment: 'admin/login'),
        isNull,
      );
    });

    test(
      'returns fragment path if web, path is / and fragment starts with /',
      () {
        expect(
          fragmentRedirectFor(isWeb: true, path: '/', fragment: '/admin/login'),
          '/admin/login',
        );
        expect(
          fragmentRedirectFor(isWeb: true, path: '/', fragment: '/admin'),
          '/admin',
        );
        expect(
          fragmentRedirectFor(isWeb: true, path: '/', fragment: '/welcome'),
          '/welcome',
        );
      },
    );

    test('returns initialHash path if provided on web root path', () {
      expect(
        fragmentRedirectFor(
          isWeb: true,
          path: '/',
          fragment: '',
          initialHash: '/admin/login',
        ),
        '/admin/login',
      );
      expect(
        fragmentRedirectFor(
          isWeb: true,
          path: '/',
          fragment: '/somewhere',
          initialHash: '/admin/login',
        ),
        '/admin/login',
      );
    });
  });
}
