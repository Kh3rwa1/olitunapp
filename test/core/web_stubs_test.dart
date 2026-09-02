import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/web_redirect.dart';

/// On the VM the conditional export in web_redirect.dart resolves to the
/// mobile stub (web_redirect_stub.dart). This test pins that contract: the
/// symbol exists and calling it on a non-web platform surfaces an
/// UnsupportedError instead of silently doing nothing.
///
/// The web implementation (web_redirect_web.dart) uses package:web +
/// dart:js_interop and therefore cannot compile under the VM test runner —
/// it is verified by the web build rather than this suite (SKIPPED here).
void main() {
  test('web_redirect resolves to the throwing stub on the VM', () {
    expect(() => redirectToUrl('https://example.com'), throwsUnsupportedError);
  });
}
