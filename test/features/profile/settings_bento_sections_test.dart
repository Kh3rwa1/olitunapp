import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/practice/data/typing_practice_settings.dart';
import 'package:itun/features/profile/presentation/widgets/settings_bento_sections.dart';
import 'package:itun/features/profile/presentation/widgets/settings_widgets.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpSections(
  WidgetTester tester, {
  required Widget Function(bool isDark) builder,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
          FallbackWidgetsLocalizationsDelegate(),
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: SingleChildScrollView(child: builder(false))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mobile bento renders all settings cards', (tester) async {
    await pumpSections(
      tester,
      builder: (isDark) => SettingsBentoMobile(
        themeMode: 'system',
        scriptMode: 'both',
        appLanguage: 'en',
        soundEnabled: true,
        reduceVisualEffects: false,
        isDark: isDark,
      ),
    );

    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('SCRIPT DISPLAY'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('NOTIFICATIONS & HABITS'), findsOneWidget);
    expect(find.text('Daily Study Reminder'), findsOneWidget);
    expect(find.text('DANGER ZONE'), findsOneWidget);
    expect(find.text('LEGAL'), findsOneWidget);
    expect(find.text('Reset Progress'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
  });

  testWidgets('desktop bento renders the grouped cards on a wide surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSections(
      tester,
      builder: (isDark) => SettingsBentoDesktop(
        themeMode: 'dark',
        scriptMode: 'latin',
        appLanguage: 'en',
        soundEnabled: false,
        reduceVisualEffects: true,
        isDark: isDark,
      ),
    );

    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('SCRIPT DISPLAY'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('NOTIFICATIONS & HABITS'), findsOneWidget);
    expect(find.text('DANGER ZONE'), findsOneWidget);
  });

  testWidgets('typing practice toggle flips the setting provider', (
    tester,
  ) async {
    await pumpSections(
      tester,
      builder: (isDark) => SettingsBentoMobile(
        themeMode: 'system',
        scriptMode: 'both',
        appLanguage: 'en',
        soundEnabled: true,
        reduceVisualEffects: false,
        isDark: isDark,
      ),
    );

    expect(find.text('Vocabulary & Sentence Practice'), findsOneWidget);
    final context = tester.element(find.text('Vocabulary & Sentence Practice'));
    final container = ProviderScope.containerOf(context);
    expect(container.read(typingPracticeSettingsProvider).enabled, isTrue);

    final typingTile = find.ancestor(
      of: find.text('Vocabulary & Sentence Practice'),
      matching: find.byType(ToggleTile),
    );
    await tester.ensureVisible(typingTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: typingTile, matching: find.byType(Switch)),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(container.read(typingPracticeSettingsProvider).enabled, isFalse);
  });
}
