import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/content_badge_resolver.dart';
import 'package:itun/features/admin/presentation/widgets/content_type_badge.dart';
import 'package:itun/shared/models/content_item.dart';

void main() {
  group('resolveBadgeType Resolver Tests (20+ Cases)', () {
    test('1. ContentKind.letter maps to letters', () {
      expect(
        resolveBadgeType(kind: ContentKind.letter),
        ContentBadgeType.letters,
      );
    });

    test('2. ContentKind.number maps to numbers', () {
      expect(
        resolveBadgeType(kind: ContentKind.number),
        ContentBadgeType.numbers,
      );
    });

    test('3. ContentKind.word maps to words', () {
      expect(resolveBadgeType(kind: ContentKind.word), ContentBadgeType.words);
    });

    test('4. ContentKind.sentence maps to sentences', () {
      expect(
        resolveBadgeType(kind: ContentKind.sentence),
        ContentBadgeType.sentences,
      );
    });

    test(
      '5. ContentKind.rhyme maps to audio (as rhymes are audio play-along)',
      () {
        expect(
          resolveBadgeType(kind: ContentKind.rhyme),
          ContentBadgeType.audio,
        );
      },
    );

    test('6. Lesson with cat_alphabets maps to tracing', () {
      expect(
        resolveBadgeType(kind: ContentKind.lesson, categoryId: 'cat_alphabets'),
        ContentBadgeType.tracing,
      );
    });

    test('7. Lesson with cat_numbers maps to tracing', () {
      expect(
        resolveBadgeType(kind: ContentKind.lesson, categoryId: 'cat_numbers'),
        ContentBadgeType.tracing,
      );
    });

    test('8. Lesson with cat_vocabulary maps to typing', () {
      expect(
        resolveBadgeType(
          kind: ContentKind.lesson,
          categoryId: 'cat_vocabulary',
        ),
        ContentBadgeType.typing,
      );
    });

    test('9. Lesson with cat_sentences maps to typing', () {
      expect(
        resolveBadgeType(kind: ContentKind.lesson, categoryId: 'cat_sentences'),
        ContentBadgeType.typing,
      );
    });

    test('10. Lesson with cat_greetings maps to typing', () {
      expect(
        resolveBadgeType(kind: ContentKind.lesson, categoryId: 'cat_greetings'),
        ContentBadgeType.typing,
      );
    });

    test('11. BlockType audio maps to audio overriding lesson context', () {
      expect(
        resolveBadgeType(
          kind: ContentKind.lesson,
          categoryId: 'cat_alphabets',
          blockType: 'audio',
        ),
        ContentBadgeType.audio,
      );
    });

    test('12. BlockType video maps to video overriding lesson context', () {
      expect(
        resolveBadgeType(
          kind: ContentKind.lesson,
          categoryId: 'cat_alphabets',
          blockType: 'video',
        ),
        ContentBadgeType.video,
      );
    });

    test('13. BlockType quiz maps to quiz overriding lesson context', () {
      expect(
        resolveBadgeType(
          kind: ContentKind.lesson,
          categoryId: 'cat_alphabets',
          blockType: 'quiz',
        ),
        ContentBadgeType.quiz,
      );
    });

    test('14. BlockType tracing maps to tracing overriding lesson context', () {
      expect(
        resolveBadgeType(
          kind: ContentKind.lesson,
          categoryId: 'cat_alphabets',
          blockType: 'tracing',
        ),
        ContentBadgeType.tracing,
      );
    });

    test(
      '15. Structural blocks (e.g. text) in Letters lesson fallback to tracing',
      () {
        expect(
          resolveBadgeType(
            kind: ContentKind.lesson,
            categoryId: 'cat_alphabets',
            blockType: 'text',
          ),
          ContentBadgeType.tracing,
        );
      },
    );

    test(
      '16. Empty categoryId + empty categorySlug + lesson kind -> lesson generic',
      () {
        expect(
          resolveBadgeType(
            kind: ContentKind.lesson,
            categoryId: '',
            categorySlug: '',
          ),
          ContentBadgeType.lesson,
        );
      },
    );

    test(
      '17. Null categoryId + valid categorySlug -> resolves correctly via slug',
      () {
        expect(
          resolveBadgeType(kind: ContentKind.lesson, categorySlug: 'numbers'),
          ContentBadgeType.tracing,
        );
      },
    );

    test(
      '18. Valid categoryId + null categorySlug -> resolves correctly via ID',
      () {
        expect(
          resolveBadgeType(
            kind: ContentKind.lesson,
            categoryId: 'cat_vocabulary',
          ),
          ContentBadgeType.typing,
        );
      },
    );

    test('19. Mixed-case slugs normalized correctly', () {
      expect(
        resolveBadgeType(kind: ContentKind.lesson, categorySlug: 'VOCABULARY'),
        ContentBadgeType.typing,
      );
    });

    test('20. Slug with whitespace trimmed and normalized correctly', () {
      expect(
        resolveBadgeType(kind: ContentKind.lesson, categorySlug: '  letters  '),
        ContentBadgeType.tracing,
      );
    });

    test('21. Unknown blockType falls through to parent category typing', () {
      expect(
        resolveBadgeType(
          kind: ContentKind.lesson,
          categoryId: 'cat_vocabulary',
          blockType: 'unknown_block',
        ),
        ContentBadgeType.typing,
      );
    });

    test(
      '22. blockType null + lesson kind with no category -> lesson generic',
      () {
        expect(
          resolveBadgeType(kind: ContentKind.lesson),
          ContentBadgeType.lesson,
        );
      },
    );

    test('23. Rhyme kind + non-empty blockType audio -> audio badge', () {
      expect(
        resolveBadgeType(kind: ContentKind.rhyme, blockType: 'audio'),
        ContentBadgeType.audio,
      );
    });
  });

  group('ContentTypeBadge Widget UI Tests', () {
    testWidgets('Renders letters badge with correct icon & semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentTypeBadge(type: ContentBadgeType.letters),
          ),
        ),
      );

      // Verify Semantics label
      final semanticsFinder = find.bySemanticsLabel('Content type: Letters');
      expect(semanticsFinder, findsOneWidget);

      // Verify the correct Icon is rendered
      expect(find.byIcon(Icons.abc_rounded), findsOneWidget);
    });

    testWidgets('Renders numbers badge with correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentTypeBadge(type: ContentBadgeType.numbers),
          ),
        ),
      );

      expect(find.byIcon(Icons.numbers_rounded), findsOneWidget);
    });

    testWidgets('Renders quiz badge with correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ContentTypeBadge(type: ContentBadgeType.quiz)),
        ),
      );

      expect(find.byIcon(Icons.quiz_rounded), findsOneWidget);
    });

    testWidgets(
      'Renders with pill shape and textual label when showLabel is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ContentTypeBadge(
                type: ContentBadgeType.words,
                showLabel: true,
              ),
            ),
          ),
        );

        // Check text label is shown using the proper const map
        expect(find.text('Words'), findsOneWidget);
        expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);

        // Verify the typography font size (size * 0.4 = 32 * 0.4 = 12.8)
        final textWidget = tester.widget<Text>(find.text('Words'));
        expect(textWidget.style?.fontSize, 12.8);
        expect(textWidget.style?.fontWeight, FontWeight.w600);
        expect(textWidget.style?.letterSpacing, 0.3);
      },
    );

    testWidgets('Renders overlay shadow when hasShadowRing is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentTypeBadge(
              type: ContentBadgeType.audio,
              hasShadowRing: true,
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final containerWidget = tester.widget<Container>(containerFinder);
      final boxDecoration = containerWidget.decoration as BoxDecoration;

      // Verify shadow parameters (blurRadius: 4, opacity: 0.15)
      expect(boxDecoration.boxShadow, isNotNull);
      expect(boxDecoration.boxShadow!.length, 1);

      final shadow = boxDecoration.boxShadow!.first;
      expect(shadow.blurRadius, 4.0);
      expect(shadow.offset, const Offset(0, 1));
      expect(shadow.color.a, closeTo(0.15, 0.01)); // opacity 0.15
    });
  });
}
