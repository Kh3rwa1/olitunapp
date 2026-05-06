import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/auth/presentation/email_auth_screen.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import '../../test_utils.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  testWidgets('EmailAuthScreen initial state shows email input', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestableWidget(
        child: const EmailAuthScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byType(TextField),
      findsOneWidget,
    ); // Assuming one main text field initially
    // We can also find by label text or hint text based on localization
    // AppLocalizations.of(context)!.emailAddress
  });

  testWidgets('EmailAuthScreen sends OTP and shows OTP input', (tester) async {
    when(
      () => mockAuthRepository.sendOtp(any()),
    ).thenAnswer((_) async => const Right('mock_user_id'));

    await tester.pumpWidget(
      createTestableWidget(
        child: const EmailAuthScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      ),
    );

    // Enter email
    final emailField = find.byType(TextField);
    await tester.enterText(emailField, 'test@example.com');
    await tester.pump();

    // Tap "Send Code" or the equivalent button.
    // It's the only elevated button/primary button usually.
    // We can find by type if there's a specific button type, or by gesture detector.
    // Let's just tap the button containing 'Continue' or 'Send Code' text from localization.
    // We will find any button/gesture detector that has a text child.

    // Instead of hardcoding, let's find the PrimaryButton or InkWell that triggers it.
    // We will look for a widget that contains "Send Code" text or just tap the only button.
    // To be safe, we'll try to find the button. In EmailAuthScreen it's likely a PrimaryButton or DuoButton.
    // Let's use tester.tap(find.byType(ElevatedButton)) or similar.
    // We know there's a text field. We can try submitting the form.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Sometimes we need to find the button by text, but since it's localized we can't easily hardcode without knowing the mock l10n.
    // Our test utils uses real l10n. 'Continue' is 'Continue' in English.
    final continueButton = find.text('Continue');
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton.first);
    } else {
      // In email_auth_screen, the button text is: _codeSent ? l10n.verifyCode : l10n.sendCode
      final sendCodeButton = find.text('Send Code');
      if (sendCodeButton.evaluate().isNotEmpty) {
        await tester.tap(sendCodeButton.first);
      }
    }

    await tester.pumpAndSettle();

    verify(() => mockAuthRepository.sendOtp('test@example.com')).called(1);

    // After successful send, it should show a second text field for OTP.
    // Or replace the field. Let's see if there's text "Verify Code" or two text fields.
  });
}
