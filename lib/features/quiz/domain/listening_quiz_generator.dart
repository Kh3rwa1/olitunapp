import '../../../shared/models/content_models.dart';
import '../../lessons/domain/entities/lesson_entity.dart';

import 'lesson_quiz_generator.dart';

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
  static QuizModel generate(
    LessonEntity lesson, {
    String teachingLanguage = 'en',
  }) {
    final questions = <QuizQuestion>[];

    final audioBlocks = _eligibleAudioBlocks(lesson);
    final isNumberCategory = lesson.categoryId.toLowerCase().contains('number');
    final isAlphabetCategory =
        lesson.categoryId.toLowerCase().contains('alphabet') ||
        lesson.categoryId.toLowerCase().contains('letter');

    final resolvedBlockOptions = <String>[];
    for (final b in audioBlocks) {
      final opt = LessonQuizGenerator.resolveBlockOption(
        b,
        teachingLanguage,
        isAlphabet: isAlphabetCategory,
        isNumber: isNumberCategory,
      );
      if (opt.isNotEmpty) {
        resolvedBlockOptions.add(opt);
      }
    }

    for (int i = 0; i < audioBlocks.length; i++) {
      final block = audioBlocks[i];
      final olChiki = block.textOlChiki!.trim();
      final audioUrl = block.audioUrl!.trim();

      final correctOption = LessonQuizGenerator.resolveBlockOption(
        block,
        teachingLanguage,
        isAlphabet: isAlphabetCategory,
        isNumber: isNumberCategory,
      );
      if (correctOption.isEmpty) continue;

      // High-quality distractors first: other meanings in this lesson.
      final otherBlockTranslations = resolvedBlockOptions
          .where((t) => t != correctOption)
          .toSet()
          .toList();

      final fallbackDistractors = LessonQuizGenerator.fallbackDistractors(
        teachingLanguage,
        isNumberCategory,
        isAlphabetCategory,
      );

      // A distractor identical to the answer makes a correct option textually
      // indistinguishable from a wrong one (picking it fails validation) —
      // filter it out and dedupe before sampling.
      final distractors = [
        ...otherBlockTranslations,
        ...fallbackDistractors,
      ].where((d) => d != correctOption).toSet().toList()..shuffle();

      final options = [correctOption, ...distractors.take(3)]..shuffle();
      final correctIndex = options.indexOf(correctOption);
      if (correctIndex < 0) continue;

      final prompt = _listeningPrompt(teachingLanguage);

      questions.add(
        QuizQuestion(
          type: 'listen_meaning',
          promptOlChiki: olChiki,
          promptLatin: prompt,
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

  static String _listeningPrompt(String lang) {
    switch (lang) {
      case 'hi':
        return 'ऑडियो सुनें और सही अर्थ चुनें:';
      case 'bn':
        return 'অডিও শুনুন এবং সঠিক অর্থ বেছে নিন:';
      case 'or':
        return 'ଅଡିଓ ଶୁଣନ୍ତୁ ଏବଂ ସଠିକ୍ ଅର୍ଥ ବାଛନ୍ତୁ:';
      case 'sat':
        return 'ᱟᱰᱤᱭᱳ ᱟᱸᱡᱚᱢ ᱢᱮ ᱟᱨ ᱥᱟᱹᱨᱤ ᱢᱮᱱᱮᱛ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:';
      case 'en':
      default:
        return 'Play the audio and choose the correct meaning:';
    }
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
