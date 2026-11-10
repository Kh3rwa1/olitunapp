import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/app_settings_provider.dart';
import 'package:itun/core/config/app_update_config.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdatePolicy', () {
    test('parses admin-entered build numbers defensively', () {
      expect(AppUpdatePolicy.parseBuild('26110205'), 26110205);
      expect(AppUpdatePolicy.parseBuild(' 26110205 '), 26110205);
      expect(AppUpdatePolicy.parseBuild(26110205), 26110205);
      expect(AppUpdatePolicy.parseBuild(26110205.0), 26110205);
      expect(AppUpdatePolicy.parseBuild(''), isNull);
      expect(AppUpdatePolicy.parseBuild('abc'), isNull);
      expect(AppUpdatePolicy.parseBuild('0'), isNull);
      expect(AppUpdatePolicy.parseBuild(-5), isNull);
      expect(AppUpdatePolicy.parseBuild(null), isNull);
      expect(AppUpdatePolicy.parseBuild(true), isNull);
    });

    test('requires an update only when both numbers are known', () {
      expect(
        AppUpdatePolicy.requiresUpdate(
          current: 26101708,
          minSupported: 26110205,
        ),
        isTrue,
      );
      expect(
        AppUpdatePolicy.requiresUpdate(
          current: 26110205,
          minSupported: 26110205,
        ),
        isFalse,
      );
      expect(
        AppUpdatePolicy.requiresUpdate(current: null, minSupported: 26110205),
        isFalse,
      );
      expect(
        AppUpdatePolicy.requiresUpdate(current: 26110205, minSupported: null),
        isFalse,
      );
      expect(
        AppUpdatePolicy.hasNewerBuild(current: 26110205, latest: 26111010),
        isTrue,
      );
      expect(
        AppUpdatePolicy.hasNewerBuild(current: 26111010, latest: 26111010),
        isFalse,
      );
    });

    test('store links point at the Play listing', () {
      expect(
        AppUpdatePolicy.playMarketUri.toString(),
        'market://details?id=com.ol.itun',
      );
      expect(
        AppUpdatePolicy.playWebUri.toString(),
        'https://play.google.com/store/apps/details?id=com.ol.itun',
      );
    });
  });

  group('update providers', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer makeContainer({
      required Map<String, dynamic> settings,
      int? currentBuild = 26110205,
      bool settingsFail = false,
    }) {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appSettingsProvider.overrideWith((ref) async {
            if (settingsFail) throw StateError('offline');
            return settings;
          }),
          currentBuildNumberProvider.overrideWith((ref) async => currentBuild),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<void> settle(ProviderContainer container) async {
      await container.read(currentBuildNumberProvider.future);
      try {
        await container.read(appSettingsProvider.future);
      } catch (_) {}
    }

    test('gates an old build and caches the minimum', () async {
      final container = makeContainer(
        settings: {'min_supported_build': '26110205', 'latest_build': 26111010},
        currentBuild: 26101708,
      );
      await settle(container);

      expect(container.read(minSupportedBuildProvider), 26110205);
      expect(container.read(latestBuildProvider), 26111010);
      expect(container.read(updateRequiredProvider), isTrue);
      expect(container.read(updateAvailableProvider), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(
        prefs.getInt(AppUpdatePolicy.cachedMinSupportedBuildKey),
        26110205,
      );
    });

    test(
      'a supported build is never gated, even with a newer build out',
      () async {
        final container = makeContainer(
          settings: {'min_supported_build': 26110205, 'latest_build': 26111010},
        );
        await settle(container);
        expect(container.read(updateRequiredProvider), isFalse);
        expect(container.read(updateAvailableProvider), isTrue);
      },
    );

    test('an offline cold start honours the cached minimum', () async {
      await prefs.setInt(AppUpdatePolicy.cachedMinSupportedBuildKey, 26110205);
      final container = makeContainer(
        settings: const {},
        currentBuild: 26101708,
      );
      await settle(container);
      expect(container.read(minSupportedBuildProvider), 26110205);
      expect(container.read(updateRequiredProvider), isTrue);
    });

    test('nothing configured and nothing cached never blocks', () async {
      final container = makeContainer(settings: const {}, currentBuild: 1);
      await settle(container);
      expect(container.read(updateRequiredProvider), isFalse);
      expect(container.read(updateAvailableProvider), isFalse);
    });

    test(
      'a loaded settings map without the key lifts the gate and clears the cache',
      () async {
        await prefs.setInt(
          AppUpdatePolicy.cachedMinSupportedBuildKey,
          26110205,
        );
        final container = makeContainer(
          settings: {'onboarding_video_url': 'https://x/video.mp4'},
          currentBuild: 26101708,
        );
        await settle(container);
        expect(container.read(minSupportedBuildProvider), isNull);
        expect(container.read(updateRequiredProvider), isFalse);
        await Future<void>.delayed(Duration.zero);
        expect(
          prefs.getInt(AppUpdatePolicy.cachedMinSupportedBuildKey),
          isNull,
        );
      },
    );

    test('an unknown build number disables the gate', () async {
      final container = makeContainer(
        settings: {'min_supported_build': 26110205},
        currentBuild: null,
      );
      await settle(container);
      expect(container.read(updateRequiredProvider), isFalse);
    });

    test('survives a missing prefs provider', () async {
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) async => {'min_supported_build': 26110205},
          ),
          currentBuildNumberProvider.overrideWith((ref) async => 26101708),
        ],
      );
      addTearDown(container.dispose);
      await settle(container);
      expect(container.read(updateRequiredProvider), isTrue);
    });
  });
}
