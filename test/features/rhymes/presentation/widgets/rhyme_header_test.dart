import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/rhymes/presentation/widgets/rhyme_header.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    required Map<String, Object> prefs,
    bool isDark = false,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RhymeHeader(isDark: isDark)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('latin script mode shows the Santali eyebrow and Bakhed title', (
    tester,
  ) async {
    await pumpHeader(tester, prefs: {'app_language': 'en'});

    expect(find.text('Santali'), findsOneWidget);
    expect(find.text('Bakhed'), findsOneWidget);
    expect(find.text('Unlock the magic of stories & songs'), findsOneWidget);
  });

  testWidgets('olchiki script mode switches eyebrow and localized title', (
    tester,
  ) async {
    await pumpHeader(tester, prefs: {'script_mode': 'olchiki'});

    expect(find.text('ᱥᱟᱱᱛᱟᱲᱤ'), findsOneWidget);
    expect(find.text('Bakhed'), findsOneWidget);
    // The localized rhymes title replaces the latin display title.
    expect(find.text('Unlock the magic of stories & songs'), findsOneWidget);
  });

  testWidgets('renders in dark mode', (tester) async {
    await pumpHeader(tester, prefs: {}, isDark: true);

    expect(find.text('Santali'), findsOneWidget);
    expect(find.text('Bakhed'), findsOneWidget);
  });
}
