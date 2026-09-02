import 'package:flutter_test/flutter_test.dart';
import 'package:itun/app/router/url_strategy_stub.dart' as stub_arm;
import 'package:itun/app/router/url_strategy_web.dart' as web_arm;

/// `url_strategy_web.dart` is the web arm of the conditional export in
/// `url_strategy.dart`. On the VM `flutter_web_plugins` swaps in its non-web
/// branch, so `usePathUrlStrategy()` is a safe no-op — the test still proves
/// the web implementation compiles, is callable, and honors the shared
/// startup contract.
void main() {
  group('configureUrlStrategy (web implementation)', () {
    test('configures the path URL strategy without throwing on the VM', () {
      expect(web_arm.configureUrlStrategy, returnsNormally);
    });

    test('is idempotent so app startup can safely call it repeatedly', () {
      web_arm.configureUrlStrategy();
      expect(web_arm.configureUrlStrategy, returnsNormally);
    });

    test('stays contract-compatible with the mobile stub implementation', () {
      // Both arms of the conditional export must be zero-argument synchronous
      // void functions so `main()` can call either one identically.
      expect(web_arm.configureUrlStrategy, isA<void Function()>());

      expect(stub_arm.configureUrlStrategy, returnsNormally);
      expect(web_arm.configureUrlStrategy, returnsNormally);
    });
  });
}
