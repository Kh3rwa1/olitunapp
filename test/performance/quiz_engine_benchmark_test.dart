import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/quiz_engine/quiz_engine.dart';

void main() {
  group('QuizEngine performance', () {
    test('compiles a realistic catalog within an interactive budget', () {
      final words = List<WordModel>.generate(
        240,
        (index) => WordModel(
          id: 'word_$index',
          wordOlChiki: 'ᱡᱚᱦᱟᱨ$index',
          wordLatin: 'word $index',
          meaning: 'meaning $index',
          category: const [
            'greeting',
            'basic',
            'family',
            'daily',
            'colors',
            'nature',
            'time',
            'trending',
            'body',
          ][index % 9],
          order: index,
        ),
      );
      final sentences = List<SentenceModel>.generate(
        160,
        (index) => SentenceModel(
          id: 'sentence_$index',
          sentenceOlChiki: 'ᱡᱚᱦᱟᱨ ᱢᱤ$index',
          sentenceLatin: 'Johar mi $index',
          meaning: 'Hello friend $index',
          category: const [
            'basics',
            'conversations',
            'polite',
            'time_weather',
          ][index % 4],
          order: index,
        ),
      );

      final stopwatch = Stopwatch()..start();
      final compiled = QuizEngine.compile(
        baseQuizzes: QuizCatalog.defaultQuizzes,
        words: words,
        sentences: sentences,
      );
      stopwatch.stop();

      expect(compiled.length, greaterThanOrEqualTo(14));
      expect(
        compiled.expand((quiz) => quiz.questions).length,
        greaterThanOrEqualTo(80),
      );
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason:
            'Quiz generation runs while users browse learning content, so it needs to stay comfortably sub-frame-batch fast.',
      );
    });
  });
}
