import 'package:flutter_test/flutter_test.dart';
import 'package:itun/app/router/route_names.dart';
import 'package:itun/app/router/url_strategy.dart';

void main() {
  group('RouteNames', () {
    test('every shell and auth route name is stable', () {
      expect(RouteNames.splash, 'splash');
      expect(RouteNames.welcome, 'welcome');
      expect(RouteNames.login, 'login');
      expect(RouteNames.home, 'home');
      expect(RouteNames.categories, 'categories');
      expect(RouteNames.lessons, 'lessons');
      expect(RouteNames.lessonDetail, 'lessonDetail');
      expect(RouteNames.quiz, 'quiz');
      expect(RouteNames.profile, 'profile');
    });

    test('legal, admin and onboarding route names are stable', () {
      expect(RouteNames.privacy, 'privacy');
      expect(RouteNames.terms, 'terms');
      expect(RouteNames.admin, 'admin');
      expect(RouteNames.adminLogin, 'adminLogin');
      expect(RouteNames.onboarding, 'onboarding');
    });

    test('route names are unique so GoRouter can address each screen', () {
      final names = [
        RouteNames.splash,
        RouteNames.welcome,
        RouteNames.login,
        RouteNames.home,
        RouteNames.categories,
        RouteNames.lessons,
        RouteNames.lessonDetail,
        RouteNames.quiz,
        RouteNames.profile,
        RouteNames.privacy,
        RouteNames.terms,
        RouteNames.admin,
        RouteNames.adminLogin,
        RouteNames.onboarding,
      ];
      expect(names.toSet().length, names.length);
    });
  });

  group('configureUrlStrategy', () {
    // On the VM the conditional export picks url_strategy_stub.dart; on the
    // web build it wires the path URL strategy. Either way the call must be
    // a safe no-op-or-configure at app startup.
    test(
      'resolves the platform strategy without throwing on mobile/VM',
      configureUrlStrategy,
    );
  });
}
