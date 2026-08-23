import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/admin/presentation/lessons/content/widgets/edit_block_sheet.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/shared/models/content_models.dart';

class MockLettersNotifier extends LettersNotifier {
  @override
  AsyncValue<List<LetterModel>> build() => const AsyncValue.data([]);
}

class MockNumbersNotifier extends NumbersNotifier {
  @override
  AsyncValue<List<NumberModel>> build() => const AsyncValue.data([]);
}

class MockWordsNotifier extends WordsNotifier {
  @override
  AsyncValue<List<WordModel>> build() => const AsyncValue.data([]);
}

class MockSentencesNotifier extends SentencesNotifier {
  @override
  AsyncValue<List<SentenceModel>> build() => const AsyncValue.data([]);
}

void main() {
  testWidgets('EditBlockSheet renders without throwing', (
    WidgetTester tester,
  ) async {
    const block = LessonBlockEntity(
      type: 'text',
      textOlChiki: 'hbj',
      textLatin: 'hbj',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lettersProvider.overrideWith(MockLettersNotifier.new),
          numbersProvider.overrideWith(MockNumbersNotifier.new),
          wordsProvider.overrideWith(MockWordsNotifier.new),
          sentencesProvider.overrideWith(MockSentencesNotifier.new),
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
