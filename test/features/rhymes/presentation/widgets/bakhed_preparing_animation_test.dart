import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/rhymes/presentation/widgets/bakhed_preparing_animation.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

void main() {
  Widget host({bool isDark = false}) => ProviderScope(
    overrides: [
      // Disable visual effects so the EnchantedVisualizer particles and
      // pulse animation never leave timers running in the fake-async zone.
      reduceVisualEffectsProvider.overrideWithValue(true),
    ],
    child: MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(body: BakhedPreparingAnimation(isDark: isDark)),
    ),
  );

  testWidgets('explains that bakhed are being prepared', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Bakhed are being prepared'), findsOneWidget);
    expect(
      find.text('New listening stories will appear here after publishing.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });

  testWidgets('renders the dark variant without pending timers', (
    tester,
  ) async {
    await tester.pumpWidget(host(isDark: true));
    await tester.pumpAndSettle();

    expect(find.text('Bakhed are being prepared'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
