import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/settings/controllers/admin_settings_controller.dart';

void main() {
  group('AdminSettingsController - Razorpay Key Validation', () {
    test('accepts valid live and test publishable Key IDs', () {
      expect(
        AdminSettingsController.validateRazorpayKeyId(
          'rzp_test_1234567890abcdef',
        ),
        isNull,
      );
      expect(
        AdminSettingsController.validateRazorpayKeyId(
          'rzp_live_abcdef1234567890',
        ),
        isNull,
      );
      expect(AdminSettingsController.validateRazorpayKeyId(''), isNull);
    });

    test('rejects Razorpay Secret Keys', () {
      final result = AdminSettingsController.validateRazorpayKeyId(
        'rzp_sec_abcdef1234567890',
      );
      expect(result, isNotNull);
      expect(result, contains('Rejected: You entered a Razorpay Secret Key'));
    });

    test('rejects invalid key formats', () {
      final invalidPrefix = AdminSettingsController.validateRazorpayKeyId(
        'invalid_key_12345',
      );
      expect(invalidPrefix, isNotNull);
      expect(
        invalidPrefix,
        contains('must start with "rzp_test_" or "rzp_live_"'),
      );

      final tooShort = AdminSettingsController.validateRazorpayKeyId(
        'rzp_test_short',
      );
      expect(tooShort, isNotNull);
      expect(tooShort, contains('between 16 and 64 characters'));
    });
  });

  group('AdminSettingsState', () {
    test('tracks dirty state and failure indicators correctly', () {
      const state = AdminSettingsState(status: AdminSettingsStatus.loaded);

      expect(state.isLoaded, isTrue);
      expect(state.hasLoadFailure, isFalse);
      expect(state.isSavingAny, isFalse);

      final savingState = state.copyWith(
        status: AdminSettingsStatus.saving,
        savingKey: 'onboarding_video_url',
      );
      expect(savingState.isSaving('onboarding_video_url'), isTrue);
      expect(savingState.isSaving('razorpay_key_id'), isFalse);
    });
  });
}
