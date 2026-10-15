import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/quiz/data/quizzes_provider.dart';
import 'package:itun/features/quiz/presentation/mistake_review_screen.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import '../../../test_utils.dart';

void main() {
  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  final wordWater = WordModel(
    id: 'w_water',
    wordOlChiki: 'ᱫᱟᱜ',
    wordLatin: 'Dak',
    meaning: 'Water',
  );
  final wordFood = WordModel(
    id: 'w_food',
    wordOlChiki: 'ᱫᱟᱠᱟ',
    wordLatin: 'Daka',
    meaning: 'Food',
  );
  final wordHouse = WordModel(
    id: 'w_house',
    wordOlChiki: 'ᱚᱲᱟᱜ',
    wordLatin: 'Orak',
    meaning: 'House',
  );
  final wordTree = WordModel(
    id: 'w_tree',
    wordOlChiki: 'ᱫᱟᱨᱮ',
    wordLatin: 'Dare',
    meaning: 'Tree',
  );

  final mockWords = [wordWater, wordFood, wordHouse, wordTree];

  testWidgets(
    'MistakeReviewScreen dynamically localizes Hindi mistake into Bengali when teaching language is Bengali',
    (tester) async {
      // Historical mistake snapshot recorded in Hindi
      final hindiMistake = MistakeItem(
        quizId: 'quiz_dynamic_vocab_basics',
        questionIndex: 0,
        question: QuizQuestion(
          promptOlChiki: 'ᱫᱟᱜ',
          promptLatin: 'इस शब्द का सही अर्थ चुनें:',
          optionsOlChiki: ['ᱫᱟᱜ', 'ᱫᱟᱠᱟ', 'ᱚᱲᱟᱜ', 'ᱫᱟᱨᱮ'],
          optionsLatin: ['पानी', 'खाना', 'घर', 'पेड़'],
          sourceWordId: 'w_water',
        ),
        addedAt: '2026-05-01T10:00:00Z',
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const MistakeReviewScreen(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            mistakeProvider.overrideWith(
              () => _MockMistakeNotifier([hindiMistake]),
            ),
            effectiveTeachingLanguageProvider.overrideWith((ref) => 'bn'),
            learnerWordsProvider.overrideWith(
              (ref) => AsyncValue.data(mockWords),
            ),
            quizzesByIdProvider.overrideWith(
              (ref) => const AsyncValue.data(<String, QuizModel>{}),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Ol Chiki prompt is displayed
      expect(find.text('ᱫᱟᱜ'), findsOneWidget);

      // Prompt must be in Bengali, NOT Hindi
      expect(find.text('এই শব্দটির সঠিক অর্থ বেছে নিন:'), findsOneWidget);
      expect(find.text('इस शब्द का सही अर्थ चुनें:'), findsNothing);

      // Options must be in Bengali, NOT Hindi
      expect(find.text('জল'), findsOneWidget);
      expect(find.text('খাবার'), findsOneWidget);
      expect(find.text('বাড়ি'), findsOneWidget);
      expect(find.text('গাছ'), findsOneWidget);

      expect(find.text('पानी'), findsNothing);
      expect(find.text('खाना'), findsNothing);
      expect(find.text('घर'), findsNothing);
      expect(find.text('पेड़'), findsNothing);

      // Selecting the correct answer triggers Bengali feedback
      await tester.tap(find.text('জল'));
      await tester.pumpAndSettle();

      expect(find.text('জল'), findsWidgets);
    },
  );
}

class _MockMistakeNotifier extends MistakeNotifier {
  final List<MistakeItem> _initial;
  _MockMistakeNotifier(this._initial);

  @override
  List<MistakeItem> build() => _initial;

  @override
  Future<void> resolveMistake({
    required String quizId,
    required int questionIndex,
  }) async {
    state = state
        .where((m) => !(m.quizId == quizId && m.questionIndex == questionIndex))
        .toList();
  }
}
