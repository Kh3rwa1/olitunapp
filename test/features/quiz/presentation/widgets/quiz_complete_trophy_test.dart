import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_complete_trophy.dart';

void main() {
  Widget host({required bool isPassing}) => MaterialApp(
    home: Center(
      child: QuizCompleteTrophy(isPassing: isPassing, reduceEffects: true),
    ),
  );

  testWidgets('passing score renders the golden trophy', (tester) async {
    await tester.pumpWidget(host(isPassing: true));

    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
  });

  testWidgets('failing score renders the retry trophy', (tester) async {
    await tester.pumpWidget(host(isPassing: false));

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
  });

  testWidgets('reduced effects render a static (non-repeating) trophy', (
    tester,
  ) async {
    await tester.pumpWidget(host(isPassing: true));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // A second frame exists and the widget is still the plain trophy
    // container (no infinite animation controller left running).
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
