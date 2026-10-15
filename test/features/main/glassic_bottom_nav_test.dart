import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/main/presentation/main_shell/widgets/glassic_bottom_nav.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

void main() {
  Future<List<int>> pumpNav(WidgetTester tester, {required bool isDark}) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: GlassicBottomNav(
            selectedIndex: 0,
            onItemTapped: taps.add,
            isDark: isDark,
            isTablet: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return taps;
  }

  for (final isDark in [false, true]) {
    testWidgets('persistent nav paints no BackdropFilter (dark: $isDark)', (
      tester,
    ) async {
      final taps = await pumpNav(tester, isDark: isDark);

      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        find.descendant(
          of: find.byType(GlassicBottomNav),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );

      await tester.tap(find.byIcon(Icons.person_rounded));
      expect(taps, [2]);
    });
  }
}
