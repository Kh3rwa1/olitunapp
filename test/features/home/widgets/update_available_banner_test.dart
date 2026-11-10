import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/app_settings_provider.dart';
import 'package:itun/core/config/app_update_config.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/widgets/update_available_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit_test_support.dart';

void main() {
  const current = 26110205;
  const latest = 26120101;

  Future<SharedPreferences> prefs([Map<String, Object> values = const {}]) {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  testWidgets('shows when a newer build exists; Update launches Play', (
    tester,
  ) async {
    final p = await prefs();
    var launched = 0;
    await tester.pumpWidget(
      routerHost(
        child: const UpdateAvailableBanner(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(p),
          appSettingsProvider.overrideWith(
            (ref) async => {AppUpdatePolicy.latestBuildKey: '$latest'},
          ),
          currentBuildNumberProvider.overrideWith((ref) async => current),
          updateLauncherProvider.overrideWithValue(() async => launched++),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A new version of Olitun is ready.'), findsOneWidget);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(launched, 1);
  });

  testWidgets('dismiss hides it and remembers per latest build', (
    tester,
  ) async {
    final p = await prefs();
    await tester.pumpWidget(
      routerHost(
        child: const UpdateAvailableBanner(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(p),
          appSettingsProvider.overrideWith(
            (ref) async => {AppUpdatePolicy.latestBuildKey: latest},
          ),
          currentBuildNumberProvider.overrideWith((ref) async => current),
          updateLauncherProvider.overrideWithValue(() async {}),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.text('Update'), findsNothing);
    expect(p.getBool(updateBannerDismissedKey(latest)), isTrue);
  });

  testWidgets('hidden when already dismissed for this build', (tester) async {
    final p = await prefs({updateBannerDismissedKey(latest): true});
    await tester.pumpWidget(
      routerHost(
        child: const UpdateAvailableBanner(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(p),
          appSettingsProvider.overrideWith(
            (ref) async => {AppUpdatePolicy.latestBuildKey: latest},
          ),
          currentBuildNumberProvider.overrideWith((ref) async => current),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update'), findsNothing);
  });

  testWidgets('hidden when the running build is the latest', (tester) async {
    final p = await prefs();
    await tester.pumpWidget(
      routerHost(
        child: const UpdateAvailableBanner(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(p),
          appSettingsProvider.overrideWith(
            (ref) async => {AppUpdatePolicy.latestBuildKey: current},
          ),
          currentBuildNumberProvider.overrideWith((ref) async => current),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update'), findsNothing);
  });
}
