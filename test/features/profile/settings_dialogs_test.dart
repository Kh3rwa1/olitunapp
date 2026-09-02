import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/presentation/widgets/settings_dialogs.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Host extends ConsumerStatefulWidget {
  const _Host();

  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => showThemeDialog(context, ref, 'light'),
              child: const Text('open-theme'),
            ),
            ElevatedButton(
              onPressed: () => showScriptDialog(context, ref, 'both'),
              child: const Text('open-script'),
            ),
            ElevatedButton(
              onPressed: () => showLanguageDialog(context, ref, 'en'),
              child: const Text('open-language'),
            ),
            ElevatedButton(
              onPressed: () => showResetDialog(context, ref),
              child: const Text('open-reset'),
            ),
            ElevatedButton(
              onPressed: () => showDeleteAccountDialog(context, ref),
              child: const Text('open-delete'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> pumpHost(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
          FallbackWidgetsLocalizationsDelegate(),
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: _Host(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('showThemeDialog presents the three theme options', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text('open-theme'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Theme'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('showScriptDialog presents the three script options', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text('open-script'));
    await tester.pumpAndSettle();

    expect(find.text('Script Display'), findsOneWidget);
    expect(find.text('Both scripts'), findsOneWidget);
    expect(find.text('Ol Chiki only'), findsOneWidget);
    expect(find.text('Latin only'), findsOneWidget);
  });

  testWidgets('showLanguageDialog presents the five app languages', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text('open-language'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Santali'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Bengali'), findsOneWidget);
    expect(find.text('Odia'), findsOneWidget);
  });

  testWidgets('showResetDialog warns and cancels without touching stats', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text('open-reset'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Progress'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Progress'), findsNothing);
  });

  testWidgets('showDeleteAccountDialog presents a destructive confirmation', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text('open-delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Delete Permanently'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Permanently'), findsNothing);
  });
}
