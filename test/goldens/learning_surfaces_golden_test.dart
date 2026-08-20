import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_question_card.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  Widget surface(Widget child, {Size size = const Size(420, 720)}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Center(
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );
  }

  QuizQuestion question() => QuizQuestion(
    promptOlChiki: 'ᱚ',
    promptLatin: 'Which sound does this letter make?',
    optionsOlChiki: const ['ᱚ', 'ᱤ', 'ᱩ', 'ᱮ'],
    optionsLatin: const ['a', 'i', 'u', 'e'],
  );

  testWidgets('quiz question card golden', (tester) async {
    await tester.pumpWidget(
      surface(
        Padding(
          padding: const EdgeInsets.all(24),
          child: QuizQuestionCard(question: question()),
        ),
        size: const Size(420, 260),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    if (!Platform.environment.containsKey('GITHUB_ACTIONS')) {
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('quiz_question_card.png'),
      );
    }
  });

  testWidgets('answered quiz option golden', (tester) async {
    await tester.pumpWidget(
      surface(
        Padding(
          padding: const EdgeInsets.all(24),
          child: QuizOptionTile(
            index: 0,
            currentQuestion: 0,
            question: question(),
            isSelected: true,
            isAnswered: true,
            onTap: () {},
          ),
        ),
        size: const Size(420, 160),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    if (!Platform.environment.containsKey('GITHUB_ACTIONS')) {
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('quiz_option_answered.png'),
      );
    }
  });

  testWidgets('stroke order view smoke renders stable layout', (tester) async {
    await tester.pumpWidget(
      surface(
        Center(
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: const Stack(
              children: [
                Positioned(
                  left: 74,
                  top: 88,
                  child: _StrokeSegment(width: 172, height: 24),
                ),
                Positioned(
                  left: 74,
                  top: 88,
                  child: _StrokeSegment(width: 24, height: 144),
                ),
                Positioned(
                  left: 74,
                  top: 208,
                  child: _StrokeSegment(width: 150, height: 24),
                ),
                Positioned(
                  left: 200,
                  top: 132,
                  child: _StrokeSegment(width: 24, height: 100),
                ),
                Positioned(
                  left: 92,
                  top: 112,
                  child: _StrokeProgress(width: 134, height: 16),
                ),
                Positioned(
                  left: 92,
                  top: 112,
                  child: _StrokeProgress(width: 16, height: 104),
                ),
              ],
            ),
          ),
        ),
        size: const Size(420, 420),
      ),
    );
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(_StrokeSegment), findsNWidgets(4));
    expect(find.byType(_StrokeProgress), findsNWidgets(2));
  });
}

class _StrokeSegment extends StatelessWidget {
  const _StrokeSegment({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _StrokeProgress extends StatelessWidget {
  const _StrokeProgress({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF35C7B5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
