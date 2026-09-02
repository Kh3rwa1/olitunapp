import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/words/widgets/word_card.dart';
import 'package:itun/shared/models/content/word_model.dart';

WordModel _word({String? category}) => WordModel(
  id: 'word_1',
  wordOlChiki: 'ᱡᱚᱦᱟᱨ',
  wordLatin: 'johar',
  meaning: 'hello',
  category: category,
);

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required WordModel word,
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
            child: WordCard(
              word: word,
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

  testWidgets('renders Ol Chiki word, latin form, and meaning', (tester) async {
    await pumpCard(tester, word: _word(), isDark: false);

    expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
    expect(find.text('johar'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('ᱡ'), findsOneWidget);
  });

  testWidgets('shows category badge only when category is present', (
    tester,
  ) async {
    await pumpCard(tester, word: _word(category: 'greetings'), isDark: false);
    expect(find.text('greetings'), findsOneWidget);

    await pumpCard(tester, word: _word(), isDark: false);
    expect(find.text('greetings'), findsNothing);
  });

  testWidgets('tapping the card opens edit via chevron fallback', (
    tester,
  ) async {
    var edited = false;
    await pumpCard(
      tester,
      word: _word(),
      isDark: false,
      onEdit: () => edited = true,
    );

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    expect(edited, isTrue);
  });

  testWidgets('hovering reveals delete only when canDelete is true', (
    tester,
  ) async {
    var deleted = false;
    await pumpCard(
      tester,
      word: _word(),
      isDark: false,
      onDelete: () => deleted = true,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('hello')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(deleted, isTrue);
  });

  testWidgets('hovering hides delete action when canDelete is false', (
    tester,
  ) async {
    await pumpCard(tester, word: _word(), isDark: true, canDelete: false);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('hello')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
  });
}
