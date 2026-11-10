import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/config/app_settings_provider.dart';
import 'package:itun/core/config/app_update_config.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/core/update/update_gate.dart';
import 'package:itun/core/update/update_required_screen.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late List<Map<String, dynamic>> writes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    writes = [];
    UpdateRequiredScreen.resetShownLog();
  });

  Widget harness(Widget child, {List<Override> extra = const []}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        learningAnalyticsServiceProvider.overrideWithValue(
          LearningAnalyticsService(
            prefs: prefs,
            remoteWriter: (_, payload) async => writes.add(payload),
          ),
        ),
        appSettingsProvider.overrideWith(
          (ref) async => {'min_supported_build': 26110205},
        ),
        currentBuildNumberProvider.overrideWith((ref) async => 26101708),
        ...extra,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('shows the localized copy and opens the Play Store', (
    tester,
  ) async {
    final launched = <Uri>[];
    await tester.pumpWidget(
      harness(
        UpdateRequiredScreen(
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update Olitun to continue'), findsOneWidget);
    expect(find.text('Update on Google Play'), findsOneWidget);

    await tester.tap(find.byKey(const Key('update_required_store_button')));
    await tester.pumpAndSettle();
    expect(launched, [AppUpdatePolicy.playMarketUri]);
  });

  testWidgets('falls back to the web listing when market:// cannot open', (
    tester,
  ) async {
    final launched = <Uri>[];
    await tester.pumpWidget(
      harness(
        UpdateRequiredScreen(
          launcher: (uri) async {
            launched.add(uri);
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('update_required_store_button')));
    await tester.pumpAndSettle();
    expect(launched, [
      AppUpdatePolicy.playMarketUri,
      AppUpdatePolicy.playWebUri,
    ]);
  });

  testWidgets('logs update_required_shown once per run', (tester) async {
    await tester.pumpWidget(
      harness(UpdateRequiredScreen(launcher: (_) async => true)),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(harness(const SizedBox()));
    await tester.pumpWidget(
      harness(UpdateRequiredScreen(launcher: (_) async => true)),
    );
    await tester.pumpAndSettle();

    final shown = writes
        .where(
          (w) => w['eventName'] == LearningAnalyticsEvents.updateRequiredShown,
        )
        .toList();
    expect(shown, hasLength(1));
  });

  testWidgets('UpdateGate replaces the app below the minimum build', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const UpdateGate(child: Text('app body'))));
    await tester.pumpAndSettle();
    expect(find.text('app body'), findsNothing);
    expect(find.byType(UpdateRequiredScreen), findsOneWidget);
  });

  testWidgets('UpdateGate shows the app when the build is supported', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const UpdateGate(child: Text('app body')),
        extra: [
          currentBuildNumberProvider.overrideWith((ref) async => 26110205),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('app body'), findsOneWidget);
    expect(find.byType(UpdateRequiredScreen), findsNothing);
  });

  testWidgets('UpdateGate shows the app when the policy cannot be read', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateRequiredProvider.overrideWith((ref) => throw StateError('x')),
        ],
        child: const MaterialApp(home: UpdateGate(child: Text('app body'))),
      ),
    );
    await tester.pump();
    expect(find.text('app body'), findsOneWidget);
  });
}
