import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/admin_content_client.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/admin/domain/admin_failure.dart';
import 'package:itun/features/admin/presentation/settings/controllers/admin_settings_controller.dart';
import 'package:itun/core/auth/auth_providers.dart';
import 'package:itun/core/config/app_settings_provider.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/payments/purchased_categories_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_admin_worker.dart';

void main() {
  late FakeAdminWorker worker;
  late SharedPreferences prefs;

  setUp(() async {
    worker = FakeAdminWorker();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        adminContentClientProvider.overrideWithValue(worker.adminClient),
        sharedPreferencesProvider.overrideWithValue(prefs),
        isAuthenticatedProvider.overrideWith((ref) async => true),
        appSettingsProvider.overrideWith((ref) async => <String, dynamic>{}),
        adStateProvider.overrideWith(() => AdStateNotifier(const AdState())),
        purchasedCategoriesProvider.overrideWith((ref) async => <String>{}),
      ],
    );
    // Keep the autoDispose controller alive for the duration of the test and
    // ensure every later `.notifier` read resolves to this same instance.
    container.listen(adminSettingsControllerProvider, (previous, next) {});
    container.read(adminSettingsControllerProvider.notifier);
    return container;
  }

  /// Waits for the controller's build()-triggered initial load to finish.
  Future<void> waitForLoaded(ProviderContainer container) async {
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(Duration.zero);
      final status = container.read(adminSettingsControllerProvider).status;
      if (status == AdminSettingsStatus.loaded ||
          status == AdminSettingsStatus.loadFailure ||
          status == AdminSettingsStatus.conflict) {
        return;
      }
    }
  }

  group('AdminSettingsController - Razorpay Key Validation Matrix', () {
    test('Case 1: accepts valid rzp_live_ Key ID', () {
      expect(
        AdminSettingsController.validateRazorpayKeyId(
          'rzp_live_1234567890abcdef',
        ),
        isNull,
      );
    });

    test('Case 2: accepts valid rzp_test_ Key ID', () {
      expect(
        AdminSettingsController.validateRazorpayKeyId(
          'rzp_test_1234567890abcdef',
        ),
        isNull,
      );
    });

    test('Case 3: accepts empty string to use bundled default fallback', () {
      expect(AdminSettingsController.validateRazorpayKeyId(''), isNull);
      expect(AdminSettingsController.validateRazorpayKeyId('   '), isNull);
    });

    test('Case 4: rejects Razorpay Secret Keys starting with rzp_sec_', () {
      final res = AdminSettingsController.validateRazorpayKeyId(
        'rzp_sec_abcdef1234567890',
      );
      expect(res, isNotNull);
      expect(res, contains('Rejected: You entered a Razorpay Secret Key'));
    });

    test('Case 5: rejects invalid prefixes', () {
      final res = AdminSettingsController.validateRazorpayKeyId(
        'pk_live_1234567890abcdef',
      );
      expect(res, isNotNull);
      expect(res, contains('must start with "rzp_test_" or "rzp_live_"'));
    });

    test('Case 6: rejects key shorter than 16 characters', () {
      final res = AdminSettingsController.validateRazorpayKeyId(
        'rzp_test_short',
      );
      expect(res, isNotNull);
      expect(res, contains('between 16 and 64 characters'));
    });

    test('Case 7: rejects key longer than 64 characters', () {
      final longKey = 'rzp_test_${'a' * 60}';
      final res = AdminSettingsController.validateRazorpayKeyId(longKey);
      expect(res, isNotNull);
      expect(res, contains('between 16 and 64 characters'));
    });
  });

  group('AdminSettingsController - Load & Save State Machine Matrix', () {
    test('Case 8: initial load success parses remote app_settings', () async {
      worker.settings.addAll({
        'onboarding_video_url': 'https://example.com/video.mp4',
        'global_review_unlock_enabled': 'true',
        'razorpay_key_id': 'rzp_test_123456789012',
      });

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(adminSettingsControllerProvider.notifier);
      await waitForLoaded(container);

      final state = container.read(adminSettingsControllerProvider);
      expect(state.isLoaded, isTrue);
      expect(state.onboardingVideoUrl, 'https://example.com/video.mp4');
      expect(state.globalReviewUnlockEnabled, isTrue);
      expect(state.razorpayKeyId, 'rzp_test_123456789012');
    });

    test(
      'Case 9: initial load handles malformed goals JSON gracefully',
      () async {
        worker.settings['onboarding_goals'] = 'invalid-json-string{';

        final container = createContainer();
        addTearDown(container.dispose);
        await waitForLoaded(container);

        final state = container.read(adminSettingsControllerProvider);
        expect(state.isLoaded, isTrue);
        expect(state.goalsList, AdminSettingsController.defaultGoals);
      },
    );

    test('Case 10: initial load failure sets loadFailure state', () async {
      // Transport failure: the Worker cannot be reached.
      worker.transportError = const SocketException('Failed host lookup');
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        adminSettingsControllerProvider.notifier,
      );
      await controller.loadSettings();

      final state = container.read(adminSettingsControllerProvider);
      expect(state.hasLoadFailure, isTrue);
      expect(state.failure, isA<AdminNetworkFailure>());
    });

    test(
      'Case 11: save setting PUTs to the Worker with the admin JWT',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(
          adminSettingsControllerProvider.notifier,
        );
        await controller.loadSettings();

        final success = await controller.saveSetting(
          'onboarding_video_url',
          'https://olitun.org/demo.mp4',
        );

        expect(success, isTrue);
        expect(
          container.read(adminSettingsControllerProvider).onboardingVideoUrl,
          'https://olitun.org/demo.mp4',
        );
        final put = worker.requestsWith('PUT').single;
        expect(
          put.url.toString(),
          '${CloudflareConfig.adminSettingsEndpoint}/onboarding_video_url',
        );
        expect(put.headers['Authorization'], 'Bearer ${FakeAdminWorker.jwt}');
        expect(worker.bodyOf(put), {
          'settingValue': 'https://olitun.org/demo.mp4',
        });
        expect(worker.settings['onboarding_video_url'], isNotNull);
      },
    );

    test(
      'Case 12: initial load reads the uncached admin settings route',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        await waitForLoaded(container);

        final get = worker.requestsWith('GET').first;
        expect(get.url.toString(), CloudflareConfig.adminSettingsEndpoint);
        expect(get.headers['Authorization'], 'Bearer ${FakeAdminWorker.jwt}');
      },
    );

    test(
      'Case 13: a 401/403 from the Worker is a permission failure',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        await waitForLoaded(container);
        final controller = container.read(
          adminSettingsControllerProvider.notifier,
        );
        worker.failStatus = 403;

        final success = await controller.saveSetting(
          'onboarding_video_url',
          'https://olitun.org/unauthorized.mp4',
        );

        expect(success, isFalse);
        expect(worker.settings, isEmpty);
        expect(
          container.read(adminSettingsControllerProvider).failure,
          isA<AdminPermissionFailure>(),
        );
      },
    );

    test(
      'Case 14: save setting handles 429 rate limiting with retry guidance',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        await waitForLoaded(container);
        final controller = container.read(
          adminSettingsControllerProvider.notifier,
        );
        worker.failStatus = 429;

        final success = await controller.saveSetting(
          'onboarding_video_url',
          'https://olitun.org/rate.mp4',
        );

        expect(success, isFalse);
        final failure = container.read(adminSettingsControllerProvider).failure;
        expect(failure, isA<AdminRateLimitFailure>());
        expect(failure?.userMessage, contains('Too many requests'));
      },
    );

    test(
      'Case 15: save setting rolls back state to lastConfirmedState on 500 failure',
      () async {
        worker.settings['onboarding_video_url'] =
            'https://olitun.org/initial.mp4';

        final container = createContainer();
        addTearDown(container.dispose);
        await waitForLoaded(container);
        final controller = container.read(
          adminSettingsControllerProvider.notifier,
        );

        expect(
          container.read(adminSettingsControllerProvider).onboardingVideoUrl,
          'https://olitun.org/initial.mp4',
        );

        worker.failStatus = 500;
        final success = await controller.saveSetting(
          'onboarding_video_url',
          'https://olitun.org/failed-update.mp4',
        );

        expect(success, isFalse);
        expect(
          container.read(adminSettingsControllerProvider).onboardingVideoUrl,
          'https://olitun.org/initial.mp4',
        );
        expect(
          container.read(adminSettingsControllerProvider).failure,
          isA<AdminServerFailure>(),
        );
      },
    );

    test(
      'Case 16: save setting stops before network when Razorpay key validation fails',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        await waitForLoaded(container);
        final controller = container.read(
          adminSettingsControllerProvider.notifier,
        );

        final success = await controller.saveSetting(
          'razorpay_key_id',
          'rzp_sec_secret_key_12345',
        );

        expect(success, isFalse);
        expect(worker.requestsWith('PUT'), isEmpty);
        expect(
          container.read(adminSettingsControllerProvider).status,
          AdminSettingsStatus.validationFailure,
        );
      },
    );

    test('Case 17: saveGoals rejects empty titles', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        adminSettingsControllerProvider.notifier,
      );
      await controller.loadSettings();

      final success = await controller.saveGoals([
        {'id': 'g1', 'title': '', 'icon': 'translate_rounded'},
      ]);

      expect(success, isFalse);
      expect(
        container.read(adminSettingsControllerProvider).status,
        AdminSettingsStatus.validationFailure,
      );
    });

    test('Case 18: saveBadgeNames rejects empty names', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        adminSettingsControllerProvider.notifier,
      );
      await controller.loadSettings();

      final success = await controller.saveBadgeNames(
        archer: '',
        kudum: 'Kudum',
        kherwal: 'Kherwal',
      );

      expect(success, isFalse);
      expect(
        container.read(adminSettingsControllerProvider).status,
        AdminSettingsStatus.validationFailure,
      );
    });

    test(
      'Case 19: saveBadgeNames stores values in SharedPreferences and Riverpod state',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        await waitForLoaded(container);
        final controller = container.read(
          adminSettingsControllerProvider.notifier,
        );

        final success = await controller.saveBadgeNames(
          archer: 'Hero Archer',
          kudum: 'Hero Kudum',
          kherwal: 'Hero Kherwal',
        );

        expect(success, isTrue);
        expect(prefs.getString('badge_traditional_archer_name'), 'Hero Archer');
        expect(prefs.getString('badge_traditional_kudum_name'), 'Hero Kudum');
        expect(
          prefs.getString('badge_traditional_kherwal_name'),
          'Hero Kherwal',
        );
      },
    );

    test('Case 20: markDirty updates isDirty flag correctly', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        adminSettingsControllerProvider.notifier,
      );
      await controller.loadSettings();

      expect(container.read(adminSettingsControllerProvider).isDirty, isFalse);

      controller.markDirty(true);
      expect(container.read(adminSettingsControllerProvider).isDirty, isTrue);

      controller.markDirty(false);
      expect(container.read(adminSettingsControllerProvider).isDirty, isFalse);
    });
  });
}
