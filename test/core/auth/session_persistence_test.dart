import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/session_persistence.dart';

class MockClient extends Mock implements Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    when(() => mockClient.setSession(any())).thenReturn(mockClient);
  });

  group('SessionPersistence Web Security & Regression Tests', () {
    test(
      '1. Web persistence NEVER writes raw secret string and purges any legacy secret from SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({
          SessionPersistence.webSessionSecretKey: 'legacy_secret_string_12345',
        });
        final prefs = await SharedPreferences.getInstance();

        await SessionPersistence.persistWebSession(
          client: mockClient,
          prefs: prefs,
          secret: 'new_session_secret_67890',
          isWebOverride: true,
        );

        // Verify raw secret is NOT written to SharedPreferences on Web
        expect(prefs.getString(SessionPersistence.webSessionSecretKey), isNull);
        // Verify non-secret metadata is stored
        expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isTrue);
        expect(
          prefs.getInt(SessionPersistence.webSessionTimestampKey),
          isNotNull,
        );

        // Verify client setSession was called in memory
        verify(
          () => mockClient.setSession('new_session_secret_67890'),
        ).called(1);
      },
    );

    test(
      '2. Web session restoration purges legacy secret string and delegates to cookie/timestamp state',
      () async {
        final validMs = DateTime.now()
            .subtract(const Duration(minutes: 30))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          SessionPersistence.webSessionSecretKey: 'legacy_secret_to_purge',
          SessionPersistence.webSessionTimestampKey: validMs,
          SessionPersistence.hasLocalSessionKey: true,
        });
        final prefs = await SharedPreferences.getInstance();

        await SessionPersistence.restoreWebSession(
          client: mockClient,
          prefs: prefs,
          isWeb: true,
        );

        // Verify legacy secret key is purged from SharedPreferences
        expect(prefs.getString(SessionPersistence.webSessionSecretKey), isNull);
        // Verify valid session flags remain intact
        expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isTrue);
        expect(
          prefs.getInt(SessionPersistence.webSessionTimestampKey),
          equals(validMs),
        );
      },
    );

    test(
      '3. Expired or invalid web session restoration fails closed and clears all session metadata',
      () async {
        final expiredMs = DateTime.now()
            .subtract(const Duration(hours: 48))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          SessionPersistence.webSessionTimestampKey: expiredMs,
          SessionPersistence.hasLocalSessionKey: true,
        });
        final prefs = await SharedPreferences.getInstance();

        await SessionPersistence.restoreWebSession(
          client: mockClient,
          prefs: prefs,
          isWeb: true,
        );

        // Verify local session state is cleared
        expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isFalse);
        expect(prefs.getInt(SessionPersistence.webSessionTimestampKey), isNull);
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      '4. Logout (clearLocalSessionState) purges all metadata and resets Client SDK session',
      () async {
        final validMs = DateTime.now().millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          SessionPersistence.webSessionTimestampKey: validMs,
          SessionPersistence.hasLocalSessionKey: true,
        });
        final prefs = await SharedPreferences.getInstance();

        await SessionPersistence.clearLocalSessionState(
          client: mockClient,
          prefs: prefs,
        );

        expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isFalse);
        expect(prefs.getInt(SessionPersistence.webSessionTimestampKey), isNull);
        expect(prefs.getString(SessionPersistence.webSessionSecretKey), isNull);
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      '5. Non-web platform (isWebOverride = false) persists secret string to secure local preferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await SessionPersistence.persistWebSession(
          client: mockClient,
          prefs: prefs,
          secret: 'mobile_secret_token_12345',
          isWebOverride: false,
        );

        expect(
          prefs.getString(SessionPersistence.webSessionSecretKey),
          equals('mobile_secret_token_12345'),
        );
        expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isTrue);
        expect(
          prefs.getInt(SessionPersistence.webSessionTimestampKey),
          isNotNull,
        );
      },
    );
  });
}
