import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/rhymes/presentation/widgets/rhyme_segmented_control.dart';

void main() {
  Widget host({required int currentTab, required ValueChanged<int> onSelect}) =>
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              RhymeSegmentedControl(
                isDark: false,
                isTablet: false,
                currentTab: currentTab,
                onTabSelect: onSelect,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 400)),
            ],
          ),
        ),
      );

  testWidgets('renders both tab labels', (tester) async {
    await tester.pumpWidget(host(currentTab: 0, onSelect: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('Bakhed Audio'), findsOneWidget);
    expect(find.text('Binti Guru'), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
  });

  testWidgets('tapping a segment selects the matching tab', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(host(currentTab: 0, onSelect: selected.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Binti Guru'));
    await tester.pumpAndSettle();
    expect(selected, [1]);

    await tester.tap(find.text('Bakhed Audio'));
    await tester.pumpAndSettle();
    expect(selected, [1, 0]);
  });

  testWidgets('slide-in entrance animation completes without hanging', (
    tester,
  ) async {
    await tester.pumpWidget(host(currentTab: 1, onSelect: (_) {}));
    await tester.pumpAndSettle();

    // After settling, the control is laid out and tappable.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
