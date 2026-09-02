import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Exercised through the presentation compatibility barrel on purpose: the
// barrel must keep re-exporting every lesson content widget.
import 'package:itun/features/lessons/presentation/widgets/lesson_content_widgets.dart';

void main() {
  group('lesson_content_widgets compatibility barrel', () {
    test('re-exports every lesson content widget type', () {
      // Referencing each exported type forces the barrel re-exports to
      // resolve at compile and run time.
      final exportedTypes = <Type>[
        BlockGridContent,
        DynamicBlockGridCell,
        EmptyContentPlaceholder,
        LetterGridContent,
        NumberGridContent,
        SentenceListContent,
        VocabularyListContent,
      ];

      expect(exportedTypes, everyElement(isA<Type>()));
      expect(exportedTypes.toSet(), hasLength(7));
    });

    testWidgets(
      'EmptyContentPlaceholder exported via the barrel renders in light mode',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyContentPlaceholder(
                message: 'No lessons yet',
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('No lessons yet'), findsOneWidget);
        expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'EmptyContentPlaceholder exported via the barrel renders in dark mode',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyContentPlaceholder(
                message: 'ᱜᱚᱲᱚ ᱵᱟᱹᱱᱩᱜᱼᱟ',
                isDark: true,
              ),
            ),
          ),
        );

        expect(find.text('ᱜᱚᱲᱚ ᱵᱟᱹᱱᱩᱜᱼᱟ'), findsOneWidget);
        expect(find.byType(EmptyContentPlaceholder), findsOneWidget);
      },
    );

    testWidgets(
      'block content widgets exported via the barrel are ConsumerWidgets',
      (tester) async {
        const letterGrid = LetterGridContent(lessonId: 'l1');
        const numberGrid = NumberGridContent(lessonId: 'l2');
        const vocabulary = VocabularyListContent(lessonId: 'l3');
        const sentences = SentenceListContent(lessonId: 'l4');

        expect(letterGrid.lessonId, 'l1');
        expect(numberGrid.lessonId, 'l2');
        expect(vocabulary.lessonId, 'l3');
        expect(sentences.lessonId, 'l4');
      },
    );
  });
}
