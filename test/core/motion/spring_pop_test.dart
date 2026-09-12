import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/motion/motion.dart';

void main() {
  testWidgets('SpringPop plays on mount and settles fully visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpringPop(trigger: 'a', child: Text('pop')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('pop'), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 1.0);
    expect(find.text('pop'), findsOneWidget);
  });

  testWidgets('SpringPop replays when the trigger changes', (tester) async {
    var trigger = 'a';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                SpringPop(trigger: trigger, child: const Text('pop')),
                TextButton(
                  onPressed: () => setState(() => trigger = 'b'),
                  child: const Text('flip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('flip'));
    await tester.pumpAndSettle();
    expect(find.text('pop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
