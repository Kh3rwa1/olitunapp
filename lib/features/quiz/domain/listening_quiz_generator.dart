import '../../../shared/models/content_models.dart';
import '../../lessons/domain/entities/lesson_entity.dart';

/// Generates a listening quiz from a lesson's playable audio blocks.
///
/// Phase 7 (spec §14): every question is built ONLY from blocks that have
/// both a playable `audioUrl` and target text — incomplete questions are
/// excluded from the pool rather than shown with a broken play button.
/// The learner hears the Santali audio and picks the matching meaning,
/// mirroring the proven [LessonQuizGenerator] distractor strategy so no
/// new admin content is required.
class ListeningQuizGenerator {
  const ListeningQuizGenerator._();

  static const int maxQuestions = 10;

  /// True when at least one block has playable audio + target text, i.e.
  /// [generate] will produce at least one question. Callers use this to
  /// decide whether to offer a listening CTA at all (graceful fallback —
  /// audio-less lessons simply keep the regular quiz experience).
  static bool canGenerate(LessonEntity lesson) =>
      _eligibleAudioBlocks(lesson).isNotEmpty;

  /// Generates a [QuizModel] whose questions are of type 'listen_meaning'.
  /// Lessons without playable audio yield a quiz with NO questions —
  /// callers check `questions.isEmpty` and treat that as "no listening
  /// quiz available" (spec §14: exclude incomplete questions from the
  /// pool; never ship a placeholder question).
  static QuizModel generate(LessonEntity lesson) {
    final questions = <QuizQuestion>[];

    final audioBlocks = _eligibleAudioBlocks(lesson);

    for (int i = 0; i < audioBlocks.length; i++) {
      final block = audioBlocks[i];
      final olChiki = block.textOlChiki!.trim();
      final latin = block.textLatin!.trim();
      final audioUrl = block.audioUrl!.trim();

      // High-quality distractors first: other meanings in this lesson.
      final otherBlockTranslations = audioBlocks
          .map((b) => b.textLatin!.trim())
          .where((t) => t != latin)
          .toSet()
          .toList();

      final isNumberCategory = lesson.categoryId.toLowerCase().contains(
        'number',
      );
      final fallbackDistractors = isNumberCategory
          ? ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight']
          : ['water', 'food', 'house', 'tree', 'hand', 'leg', 'head', 'eye'];

      final distractors = [...otherBlockTranslations, ...fallbackDistractors]
        ..shuffle();

      final options = [latin, ...distractors.take(3)]..shuffle();
      final correctIndex = options.indexOf(latin);
      if (correctIndex < 0) continue;

      questions.add(
        QuizQuestion(
          type: 'listen_meaning',
          promptOlChiki: olChiki,
          promptLatin: 'Play the audio and choose the correct meaning:',
          optionsOlChiki: options,
          optionsLatin: options,
          correctIndex: correctIndex,
          audioUrl: audioUrl,
          explanation: olChiki,
        ),
      );
    }

    return QuizModel(
      id: 'listening_quiz_${lesson.id}',
      categoryId: lesson.categoryId,
      title: '${lesson.titleLatin} Listening Quiz',
      questions: questions.take(maxQuestions).toList(),
    );
  }

  static List<LessonBlockEntity> _eligibleAudioBlocks(LessonEntity lesson) {
    return lesson.blocks
        .where((b) => b.type != 'quiz')
        .where(
          (b) =>
              (b.audioUrl ?? '').trim().isNotEmpty &&
              (b.textOlChiki ?? '').trim().isNotEmpty &&
              (b.textLatin ?? '').trim().isNotEmpty,
        )
        .toList();
  }

  /// Convenience: id convention for a lesson's listening quiz.
  static String quizIdFor(String lessonId) => 'listening_quiz_$lessonId';

  /// True if [quizId] denotes a lesson-generated listening quiz.
  static bool isListeningQuizId(String quizId) =>
      quizId.startsWith('listening_quiz_');

  /// Extracts the lesson id from a listening-quiz id.
  static String lessonIdFromQuizId(String quizId) =>
      quizId.substring('listening_quiz_'.length);
}
