import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/legacy_appwrite_session_stub.dart' as stub;

/// The web build resolves legacy_appwrite_session.dart to this stub: the
/// Appwrite session cookie is httpOnly on the Appwrite domain there, so web
/// users have nothing to migrate and simply sign in again.
void main() {
  test('the web stub never finds an Appwrite session', () async {
    expect(
      await stub.readLegacyAppwriteSession(
        endpoint: 'https://sgp.cloud.appwrite.io/v1',
        projectId: 'p',
      ),
      isNull,
    );
  });

  test('clearing on web is a no-op', () async {
    await expectLater(
      stub.clearLegacyAppwriteSession(
        endpoint: 'https://sgp.cloud.appwrite.io/v1',
      ),
      completes,
    );
  });
}
