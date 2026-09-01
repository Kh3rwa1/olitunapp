import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/presentation/widgets/target_language_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TargetLanguageTile & IndigenousLanguagesSheet Tests', () {
    testWidgets('renders TargetLanguageTile with default Santali selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TargetLanguageTile())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Language & Script'), findsOneWidget);
      expect(find.text('Santali (Ol Chiki) • ᱥᱟᱱᱛᱟᱲᱤ'), findsOneWidget);
    });

    testWidgets('opens IndigenousLanguagesSheet and selects Ho language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TargetLanguageTile())),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.byType(TargetLanguageTile));
      await tester.pumpAndSettle();

      expect(find.text('Indigenous Languages Platform'), findsOneWidget);
      expect(find.text('Ho • Warang Citi'), findsOneWidget);
      expect(find.text('Mundari • Bani Ceti'), findsOneWidget);
      expect(find.text('Kurukh (Oraon) • Tolong Siki'), findsOneWidget);

      // Select Ho
      await tester.ensureVisible(find.text('Ho • Warang Citi'));
      await tester.tap(find.text('Ho • Warang Citi'));
      await tester.pumpAndSettle();

      expect(find.text('Learning Language & Script'), findsOneWidget);
      expect(find.text('Ho (Warang Citi) • 𑢹𑣉 ᱡᱟᱜᱟᱨ'), findsOneWidget);
    });

    testWidgets(
      'shows coming soon snackbar when tapping coming soon language',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: TargetLanguageTile())),
          ),
        );
        await tester.pumpAndSettle();

        // Open sheet
        await tester.tap(find.byType(TargetLanguageTile));
        await tester.pumpAndSettle();

        // Tap Kurukh (Coming Soon)
        await tester.ensureVisible(find.text('Kurukh (Oraon) • Tolong Siki'));
        await tester.tap(find.text('Kurukh (Oraon) • Tolong Siki'));
        await tester.pump();

        expect(
          find.text('Kurukh (Oraon) content & audio packs are coming soon!'),
          findsOneWidget,
        );
      },
    );
  });
}
