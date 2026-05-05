import 'package:flutter_test/flutter_test.dart';
import 'package:itun/app/router/app_router.dart';

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
}
