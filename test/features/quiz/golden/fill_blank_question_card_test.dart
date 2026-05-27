import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/fill_blank_question_card.dart';
import 'package:itun/shared/models/content_models.dart';
import '../../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockQuestion = QuizQuestion(
    promptOlChiki: 'Fill in the blank',
    promptLatin: 'Translate the sentence below',
    optionsLatin: ['o', 'a'],
    optionsOlChiki: ['ᱚ', 'ᱟ'],
    blankSentenceOlChiki: 'ᱱᱩᱭ ᱫᱚ ___ ᱠᱟᱱᱟᱭ᱾',
    blankSentenceLatin: 'This is O.',
    type: 'fill_blank',
  );

  group('FillBlankQuestionCard Golden Tests', () {
    testWidgets('renders empty blank state (no selection)', (tester) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: FillBlankQuestionCard(
                  question: mockQuestion,
                  selectedAnswer: null,
                  isAnswered: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Settle animations
      await tester.pumpAndSettle();

      if (!Platform.environment.containsKey('GITHUB_ACTIONS')) {
        await expectLater(
          find.byType(FillBlankQuestionCard),
          matchesGoldenFile('../../../goldens/fill_blank_empty.png'),
        );
      }
    });

    testWidgets('renders correct selected state', (tester) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: FillBlankQuestionCard(
                  question: mockQuestion,
                  selectedAnswer: 0,
                  isAnswered: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Settle animations
      await tester.pumpAndSettle();

      if (!Platform.environment.containsKey('GITHUB_ACTIONS')) {
        await expectLater(
          find.byType(FillBlankQuestionCard),
          matchesGoldenFile('../../../goldens/fill_blank_correct.png'),
        );
      }
    });
  });
}
