import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_fill_blank_options.dart';
import 'package:itun/shared/models/content_models.dart';

QuizQuestion _fillBlank() => QuizQuestion(
  promptOlChiki: 'ᱤᱧ ᱫᱟᱜ __',
  promptLatin: 'I ___ water',
  optionsOlChiki: ['ᱧᱩᱟ', 'ᱡᱚᱢ', 'ᱠᱟᱹᱢᱤ', 'ᱥᱮᱬ'],
  optionsLatin: ['drink', 'eat', 'work', 'go'],
  type: 'fill_blank',
);

Widget _host({
  required QuizSessionState state,
  required ValueChanged<int> onSelect,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: QuizFillBlankOptions(
        question: _fillBlank(),
        state: state,
        isDark: false,
        onSelect: onSelect,
      ),
    ),
  ),
);

void main() {
  testWidgets('renders every missing-word option chip', (tester) async {
    await tester.pumpWidget(
      _host(state: const QuizSessionState(), onSelect: (_) {}),
    );

    expect(find.text('Select the missing word:'), findsOneWidget);
    expect(find.text('ᱧᱩᱟ'), findsOneWidget);
    expect(find.text('ᱡᱚᱢ'), findsOneWidget);
    expect(find.text('ᱠᱟᱹᱢᱤ'), findsOneWidget);
    expect(find.text('ᱥᱮᱬ'), findsOneWidget);

    // Each chip exposes an accessible button label.
    expect(find.bySemanticsLabel('Missing word option 1: ᱧᱩᱟ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('tapping an un-answered option reports the selection', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      _host(
        state: const QuizSessionState(),
        onSelect: (index) => selected = index,
      ),
    );

    await tester.tap(find.text('ᱡᱚᱢ'));
    await tester.pump();

    expect(selected, 1);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('answered state locks all chips', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        state: const QuizSessionState(selectedAnswer: 2, isAnswered: true),
        onSelect: (_) => taps++,
      ),
    );

    await tester.tap(find.text('ᱧᱩᱟ'), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.text('ᱡᱚᱢ'), warnIfMissed: false);
    await tester.pump();

    expect(taps, 0);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
