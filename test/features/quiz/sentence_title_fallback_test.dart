import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_generator.dart';
import 'package:itun/shared/models/content/quiz_model.dart';

/// Sentence quiz generation: real meaning questions from block data, and
/// fail-closed behavior for invalid lesson content.
///
/// Regression coverage for the "Modern Conversational Exchanges" bug where
/// sentence lessons with missing/malformed blocks finished with a single
/// meaningless "Choose the correct Hindi title for this lesson" question.
LessonEntity _sentenceLesson({
  required String id,
  required List<LessonBlockEntity> blocks,
  String categoryId = 'cat_sentences',
}) {
  return LessonEntity(
    id: id,
    categoryId: categoryId,
    titleLatin: 'Modern Conversational Exchanges III',
    titleOlChiki: 'ᱱᱟᱦᱟᱜ ᱨᱚᱲ',
    blocks: blocks,
  );
}

const _meaningsHi = [
  'क्या आप आज देश की यात्रा पर जा रहे हैं?',
  'हाँ, मैं नया गाँव और नए लोग देखने जा रहा हूँ।',
  'देश भ्रमण से बहुत ज्ञान मिलता है।',
  'धैर्य रखो, जीत तुम्हें मिलेगी।',
  'आओ मिलकर नया काम शुरू करें।',
  'सुबह जल्दी उठना अच्छी आदत है।',
];

const _meaningsEn = [
  'Are you going to travel the country today?',
  'Yes, I am going to see new villages and new people.',
  'Travelling the country brings great knowledge.',
  'Be patient, victory will be yours.',
  'Come, let us start new work together.',
  'Waking up early in the morning is a good habit.',
];

const _meaningsBn = [
  'আপনি কি আজ দেশ ভ্রমণ করতে যাচ্ছেন?',
  'হ্যাঁ, আমি নতুন গ্রাম এবং নতুন মানুষ দেখতে যাচ্ছি।',
  'দেশ ভ্রমণে অনেক জ্ঞান পাওয়া যায়।',
  'ধৈর্য ধরো, জয় তোমারই হবে।',
  'এসো, একসঙ্গে নতুন কাজ শুরু করি।',
  'সকালে তাড়াতাড়ি ওঠা ভালো অভ্যাস।',
];

const _meaningsOr = [
  'ଆପଣ ଆଜି ଦେଶ ଭ୍ରମଣ କରିବାକୁ ଯାଉଛନ୍ତି କି?',
  'ହଁ, ମୁଁ ନୂଆ ଗାଁ ଏବଂ ନୂଆ ଲୋକ ଦେଖିବାକୁ ଯାଉଛି |',
  'ଦେଶ ଭ୍ରମଣରେ ବହୁତ ଜ୍ଞାନ ମିଳେ |',
  'ଧୈର୍ଯ୍ୟ ରଖ, ବିଜୟ ତୁମର ହେବ |',
  'ଆସ, ମିଶି ନୂଆ କାମ ଆରମ୍ଭ କରିବା |',
  'ସକାଳୁ ଶୀଘ୍ର ଉଠିବା ଭଲ ଅଭ୍ୟାସ |',
];

LessonBlockEntity _sentenceBlock(
  int i, {
  String? meaningHi,
  String? meaningBn,
  String? meaningOr,
}) {
  return LessonBlockEntity(
    type: 'sentence',
    textOlChiki: 'ᱥᱮᱸᱫᱨᱟ ᱠᱟᱛᱷᱟ $i',
    textLatin: 'Sendra katha number $i',
    data: {
      'meaning_en': _meaningsEn[i],
      'meaning_hi': meaningHi ?? _meaningsHi[i],
      if (meaningBn case final meaningBnValue) 'meaning_bn': meaningBnValue,
      if (meaningOr case final meaningOrValue) 'meaning_or': meaningOrValue,
      'sourceSentenceId': 'sent_conv3_$i',
    },
  );
}

void _expectWellFormedMcq(QuizModel quiz) {
  expect(quiz.questions, isNotEmpty);
  final prompts = <String>{};
  for (final q in quiz.questions) {
    expect(q.optionsLatin, hasLength(4));
    expect(q.optionsLatin.toSet(), hasLength(4));
    expect(q.optionsLatin.every((o) => o.trim().isNotEmpty), isTrue);
    expect(q.correctIndex, inInclusiveRange(0, 3));
    // Lesson titles are never learning questions.
    expect(q.promptLatin ?? '', isNot(contains('title for this lesson')));
    expect(prompts.add(q.promptOlChiki), isTrue, reason: 'duplicate prompt');
  }
}

void main() {
  group('sentence quiz generation', () {
    test('valid Hindi sentence lesson generates meaning_hi questions', () {
      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: List.generate(5, _sentenceBlock),
      );

      final quiz = LessonQuizGenerator.generate(lesson, teachingLanguage: 'hi');

      expect(quiz.questions, hasLength(5));
      for (final q in quiz.questions) {
        expect(q.promptLatin, 'Choose the correct Hindi meaning:');
      }
      final correctOptions = quiz.questions
          .map((q) => q.optionsLatin[q.correctIndex])
          .toSet();
      expect(
        correctOptions,
        contains('क्या आप आज देश की यात्रा पर जा रहे हैं?'),
      );
      _expectWellFormedMcq(quiz);
    });

    test('valid English sentence lesson generates meaning questions', () {
      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: List.generate(5, _sentenceBlock),
      );

      final quiz = LessonQuizGenerator.generate(lesson);

      expect(quiz.questions, hasLength(5));
      for (final q in quiz.questions) {
        expect(q.promptLatin, 'Choose the correct English meaning:');
      }
      _expectWellFormedMcq(quiz);
    });

    test('valid Bengali and Odia lessons use localized meanings', () {
      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: List.generate(
          5,
          (i) => _sentenceBlock(
            i,
            meaningBn: _meaningsBn[i],
            meaningOr: _meaningsOr[i],
          ),
        ),
      );

      final quizBn = LessonQuizGenerator.generate(
        lesson,
        teachingLanguage: 'bn',
      );
      expect(quizBn.questions, hasLength(5));
      expect(
        quizBn.questions.map((q) => q.optionsLatin[q.correctIndex]).toSet(),
        contains('আপনি কি আজ দেশ ভ্রমণ করতে যাচ্ছেন?'),
      );
      _expectWellFormedMcq(quizBn);

      final quizOr = LessonQuizGenerator.generate(
        lesson,
        teachingLanguage: 'or',
      );
      expect(quizOr.questions, hasLength(5));
      expect(
        quizOr.questions.map((q) => q.optionsLatin[q.correctIndex]).toSet(),
        contains('ଆପଣ ଆଜି ଦେଶ ଭ୍ରମଣ କରିବାକୁ ଯାଉଛନ୍ତି କି?'),
      );
      _expectWellFormedMcq(quizOr);
    });

    test(
      'missing blocks fail closed with an empty quiz, never a title quiz',
      () {
        final lesson = _sentenceLesson(id: 'lesson_conv3', blocks: const []);

        final result = LessonQuizGenerator.generateResult(
          lesson,
          teachingLanguage: 'hi',
        );

        expect(result.isFailure, isTrue);
        expect(result.quiz.questions, isEmpty);
        expect(result.validBlockCount, 0);
      },
    );

    test('blocks missing textOlChiki are rejected as missing_ol_chiki', () {
      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: const [
          LessonBlockEntity(
            type: 'sentence',
            textLatin: 'Sendra katha',
            data: {'meaning_hi': 'कुछ अर्थ'},
          ),
        ],
      );

      final result = LessonQuizGenerator.generateResult(
        lesson,
        teachingLanguage: 'hi',
      );

      expect(result.isFailure, isTrue);
      expect(result.quiz.questions, isEmpty);
      expect(
        result.rejections.expand((r) => r.reasons),
        contains(QuizRejectionReason.missingOlChiki),
      );
    });

    test('blocks missing textLatin are rejected as missing_latin', () {
      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: const [
          LessonBlockEntity(
            type: 'sentence',
            textOlChiki: 'ᱥᱮᱸᱫᱨᱟ',
            data: {'meaning_hi': 'कुछ अर्थ'},
          ),
        ],
      );

      final result = LessonQuizGenerator.generateResult(
        lesson,
        teachingLanguage: 'hi',
      );

      expect(result.isFailure, isTrue);
      expect(
        result.rejections.expand((r) => r.reasons),
        contains(QuizRejectionReason.missingLatin),
      );
    });

    test(
      'blocks missing the localized meaning are rejected as missing_meaning',
      () {
        final lesson = _sentenceLesson(
          id: 'lesson_conv3',
          blocks: [
            const LessonBlockEntity(
              type: 'sentence',
              textOlChiki: 'ᱥᱮᱸᱫᱨᱟ',
              textLatin: 'Sendra katha',
              data: {'meaning_en': 'A sentence.'},
            ),
          ],
        );

        final result = LessonQuizGenerator.generateResult(
          lesson,
          teachingLanguage: 'hi',
        );

        // Romanized Santali must never be presented as a Hindi meaning.
        expect(result.isFailure, isTrue);
        expect(
          result.rejections.expand((r) => r.reasons),
          contains(QuizRejectionReason.missingMeaning),
        );
      },
    );

    test('malformed blocks JSON fails closed at parse time', () {
      final model = LessonModel.fromJson({
        'id': 'lesson_conv3',
        'categoryId': 'cat_sentences',
        'titleOlChiki': 'ᱱᱟᱦᱟᱜ ᱨᱚᱲ',
        'titleLatin': 'Modern Conversational Exchanges III',
        'blocks': '[not valid json',
      });

      expect(model.blocks, isEmpty);
      final result = LessonQuizGenerator.generateResult(
        model.toEntity(),
        teachingLanguage: 'hi',
      );
      expect(result.isFailure, isTrue);
      expect(result.quiz.questions, isEmpty);
    });

    test('malformed block data is rejected as malformed_data', () {
      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: [
          const LessonBlockEntity(
            type: 'sentence',
            textOlChiki: 'ᱥᱮᱸᱫᱨᱟ',
            textLatin: 'Sendra katha',
            dataMalformed: true,
          ),
        ],
      );

      final result = LessonQuizGenerator.generateResult(
        lesson,
        teachingLanguage: 'hi',
      );

      expect(result.isFailure, isTrue);
      expect(
        result.rejections.expand((r) => r.reasons),
        contains(QuizRejectionReason.malformedData),
      );
    });

    test('duplicate prompts are rejected as duplicate_content', () {
      final block = _sentenceBlock(0);
      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: [block, block, _sentenceBlock(1)],
      );

      final result = LessonQuizGenerator.generateResult(
        lesson,
        teachingLanguage: 'hi',
      );

      expect(
        result.rejections.expand((r) => r.reasons),
        contains(QuizRejectionReason.duplicateContent),
      );
      final prompts = result.quiz.questions
          .map((q) => q.promptOlChiki)
          .toList();
      expect(prompts.toSet(), hasLength(prompts.length));
    });

    test('sourceSentenceId survives parsing and generation', () {
      final model = LessonBlockModel.fromJson({
        'type': 'sentence',
        'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ',
        'textLatin': 'Sendra katha',
        'data': {'meaning_hi': 'कुछ अर्थ', 'sentenceId': 'sent_legacy_7'},
      });

      // Legacy alias is normalized to the canonical key at parse time.
      expect(model.data?['sourceSentenceId'], 'sent_legacy_7');

      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: List.generate(
          5,
          (i) => i == 0
              ? LessonBlockEntity(
                  type: 'sentence',
                  textOlChiki: model.textOlChiki,
                  textLatin: 'Sendra katha zero',
                  data: model.data,
                )
              : _sentenceBlock(i),
        ),
      );

      final quiz = LessonQuizGenerator.generate(lesson, teachingLanguage: 'hi');
      final ids = quiz.questions
          .map((q) => q.sourceSentenceId)
          .whereType<String>()
          .toSet();
      expect(ids, contains('sent_legacy_7'));
      expect(ids, contains('sent_conv3_1'));
    });

    test('diagnostics carry lessonId and block index only', () {
      final lesson = _sentenceLesson(
        id: 'lesson_conv3',
        blocks: const [LessonBlockEntity(type: 'sentence')],
      );

      final result = LessonQuizGenerator.generateResult(
        lesson,
        teachingLanguage: 'hi',
      );

      expect(result.lessonId, 'lesson_conv3');
      expect(result.rejections, hasLength(1));
      expect(result.rejections.single.blockIndex, 0);
    });

    test('production meta-shaped blocks generate real meaning questions', () {
      // Production stores meanings under block `meta`, not `data`.
      final blocks = List.generate(5, (i) {
        final parsed = LessonBlockModel.fromJson({
          'id': '',
          'order': i,
          'type': 'text',
          'markdown': 'Sendra katha number $i',
          'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ ᱠᱟᱛᱷᱟ $i',
          'textLatin': 'Sendra katha number $i',
          'audioUrl': 'https://example.com/audio/$i.mp3',
          'meta': {
            'meaning': _meaningsEn[i],
            'meaning_en': _meaningsEn[i],
            'meaning_hi': _meaningsHi[i],
            'meaning_bn': _meaningsBn[i],
            'meaning_or': _meaningsOr[i],
          },
        });
        return LessonBlockEntity(
          type: parsed.type,
          textOlChiki: parsed.textOlChiki,
          textLatin: parsed.textLatin,
          audioUrl: parsed.audioUrl,
          data: parsed.data,
        );
      });
      final lesson = _sentenceLesson(id: 'lesson_conv3', blocks: blocks);

      final quiz = LessonQuizGenerator.generate(lesson, teachingLanguage: 'hi');

      expect(quiz.questions, hasLength(5));
      for (final q in quiz.questions) {
        expect(q.promptLatin, 'Choose the correct Hindi meaning:');
      }
      expect(
        quiz.questions.map((q) => q.optionsLatin[q.correctIndex]).toSet(),
        contains('क्या आप आज देश की यात्रा पर जा रहे हैं?'),
      );
      _expectWellFormedMcq(quiz);
    });
  });
}
