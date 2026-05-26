import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/admin/presentation/lessons/content/widgets/edit_block_sheet.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/shared/models/content_models.dart';

class MockLettersNotifier extends StateNotifier<AsyncValue<List<LetterModel>>>
    with Mock
    implements LettersNotifier {
  MockLettersNotifier() : super(const AsyncValue.data([]));
}

class MockNumbersNotifier extends StateNotifier<AsyncValue<List<NumberModel>>>
    with Mock
    implements NumbersNotifier {
  MockNumbersNotifier() : super(const AsyncValue.data([]));
}

class MockWordsNotifier extends StateNotifier<AsyncValue<List<WordModel>>>
    with Mock
    implements WordsNotifier {
  MockWordsNotifier() : super(const AsyncValue.data([]));
}

class MockSentencesNotifier extends StateNotifier<AsyncValue<List<SentenceModel>>>
    with Mock
    implements SentencesNotifier {
  MockSentencesNotifier() : super(const AsyncValue.data([]));
}

void main() {
  testWidgets('EditBlockSheet renders without throwing', (WidgetTester tester) async {
    const block = LessonBlockEntity(
      type: 'text',
      textOlChiki: 'hbj',
      textLatin: 'hbj',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lettersProvider.overrideWith((ref) => MockLettersNotifier()),
          numbersProvider.overrideWith((ref) => MockNumbersNotifier()),
          wordsProvider.overrideWith((ref) => MockWordsNotifier()),
          sentencesProvider.overrideWith((ref) => MockSentencesNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    EditBlockSheet.show(
                      context: context,
                      block: block,
                      onUpdate: (updatedBlock) {},
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Click show button to display the sheet
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    // Verify it renders
    expect(find.byType(EditBlockSheet), findsOneWidget);
  });
}
