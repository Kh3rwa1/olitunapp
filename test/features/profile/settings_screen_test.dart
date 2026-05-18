import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/profile/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

import 'package:itun/main.dart';

class LocalizedSettingsTestWrapper extends ConsumerWidget {
  const LocalizedSettingsTestWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(appLanguageProvider);
    Locale locale;
    if (languageCode == 'sat') {
      locale = const Locale('sat');
    } else {
      locale = const Locale('en');
    }

    return MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const SettingsScreen(),
    );
  }
}

void main() {
  testWidgets('SettingsScreen changes language and theme without exceptions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const LocalizedSettingsTestWrapper(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial layout in English
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('App Language'), findsOneWidget);

    // Tap on App Language setting to open language dialog
    await tester.tap(find.text('App Language'));
    await tester.pumpAndSettle();

    // Verify language choices are shown
    expect(find.text('English'), findsWidgets);
    expect(find.text('Santali'), findsWidgets);

    // Change language to Santali
    await tester.tap(find.text('Santali'));
    await tester.pumpAndSettle();

    // App should now be in Santali locale!
    // In sat, 'Dark Mode' is 'Andhar Mode' (from app_sat.arb).
    expect(find.text('Andhar Mode'), findsOneWidget);
    expect(find.text('App Bhasa'), findsOneWidget);

    // Now try to tap 'App Bhasa' to change it back
    await tester.tap(find.text('App Bhasa'));
    await tester.pumpAndSettle();

    // Tap English to change it back
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Verify it is back to English
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('App Language'), findsOneWidget);
  });
}
