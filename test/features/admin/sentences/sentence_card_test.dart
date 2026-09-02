import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/sentences/widgets/sentence_card.dart';
import 'package:itun/shared/models/content/sentence_model.dart';

SentenceModel _sentence({String? category}) => SentenceModel(
  id: 'sentence_1',
  sentenceOlChiki: 'ᱡᱚᱦᱟᱨ ᱢᱮᱬᱮᱫ',
  sentenceLatin: 'johar mend',
  meaning: 'Good morning',
  category: category,
);

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required SentenceModel sentence,
    required bool isDark,
    bool canDelete = true,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            child: SentenceCard(
              sentence: sentence,
              isDark: isDark,
              onEdit: onEdit ?? () {},
              onDelete: onDelete ?? () {},
              canDelete: canDelete,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders Ol Chiki sentence, latin, and arrow meaning', (
    tester,
  ) async {
    await pumpCard(tester, sentence: _sentence(), isDark: false);

    expect(find.text('ᱡᱚᱦᱟᱨ ᱢᱮᱬᱮᱫ'), findsOneWidget);
    expect(find.text('johar mend'), findsOneWidget);
    expect(find.text('-> Good morning'), findsOneWidget);
    expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
  });

  testWidgets('shows category badge only when category is present', (
    tester,
  ) async {
    await pumpCard(
      tester,
      sentence: _sentence(category: 'greetings'),
      isDark: false,
    );
    expect(find.text('greetings'), findsOneWidget);

    await pumpCard(tester, sentence: _sentence(), isDark: false);
    expect(find.text('greetings'), findsNothing);
  });

  testWidgets('chevron fallback triggers onEdit', (tester) async {
    var edited = false;
    await pumpCard(
      tester,
      sentence: _sentence(),
      isDark: false,
      onEdit: () => edited = true,
    );

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    expect(edited, isTrue);
  });

  testWidgets('hovering shows the delete action which fires onDelete', (
    tester,
  ) async {
    var deleted = false;
    await pumpCard(
      tester,
      sentence: _sentence(),
      isDark: false,
      onDelete: () => deleted = true,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text('johar mend')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(deleted, isTrue);
  });

  testWidgets('hovering hides the delete action when canDelete is false', (
    tester,
  ) async {
    await pumpCard(
      tester,
      sentence: _sentence(),
      isDark: false,
      canDelete: false,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text('johar mend')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
  });
}
