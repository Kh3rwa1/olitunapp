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
}
