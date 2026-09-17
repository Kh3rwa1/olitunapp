// WS4 canonical identity: every invariant combination — whitespace,
// aliases, tombstones, fake IDs, both IDs, wrong type, non-memory with ID,
// old serialized questions.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/domain/quiz_identity_validation.dart';
import 'package:itun/features/quiz/domain/quiz_memory_resolver.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/shared/models/content/quiz_model.dart';

void main() {
  ReviewCorpusIdentityMap testMap() => ReviewCorpusIdentityMap(
    activeWordIds: {'w_hello', 'w_both'},
    activeSentenceIds: {'s_morning', 'w_both'},
    aliases: [
      const ReviewIdAlias(
        itemType: ReviewItemType.word,
        from: 'w_old',
        to: 'w_hello',
      ),
      const ReviewIdAlias(
        itemType: ReviewItemType.word,
        from: 'w_cycle_a',
        to: 'w_cycle_b',
      ),
      const ReviewIdAlias(
        itemType: ReviewItemType.word,
        from: 'w_cycle_b',
        to: 'w_cycle_a',
      ),
    ],
    tombstones: [
      const ReviewIdTombstone(itemType: ReviewItemType.word, id: 'w_dead'),
    ],
  );

  QuizQuestion q({String? word, String? sentence, bool nonMemory = false}) =>
      QuizQuestion(
        promptOlChiki: 'x',
        sourceWordId: word,
        sourceSentenceId: sentence,
        isNonMemory: nonMemory,
      );

  group('WS4 identity invariants', () {
    test('exactly one valid word ID is valid', () {
      final v = validateQuestionIdentity(
        q(word: 'w_hello'),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.valid);
      expect(v.canonicalId, 'w_hello');
      expect(v.canonicalType, ReviewItemType.word);
      expect(v.isPublishable, isTrue);
      expect(v.isTrackable, isTrue);
    });

    test('exactly one valid sentence ID is valid', () {
      final v = validateQuestionIdentity(
        q(sentence: 's_morning'),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.valid);
      expect(v.canonicalType, ReviewItemType.sentence);
    });

    test('whitespace-only IDs count as absent', () {
      final v = validateQuestionIdentity(q(word: '   '), corpusMap: testMap());
      expect(v.status, QuizIdentityStatus.missingAttribution);
      expect(v.isPublishable, isFalse);
    });

    test('no ID without non-memory flag is rejected', () {
      final v = validateQuestionIdentity(q(), corpusMap: testMap());
      expect(v.status, QuizIdentityStatus.missingAttribution);
    });

    test('both IDs are rejected (never silently prioritized)', () {
      final v = validateQuestionIdentity(
        q(word: 'w_hello', sentence: 's_morning'),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.bothIds);
      expect(v.isPublishable, isFalse);
      // Runtime resolver refuses to guess.
      expect(
        resolveQuizMemoryItem(
          q(word: 'w_hello', sentence: 's_morning'),
          corpusMap: testMap(),
        ),
        isNull,
      );
    });

    test('fake ID is rejected', () {
      final v = validateQuestionIdentity(
        q(word: 'w_nope'),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.unknownId);
      expect(
        resolveQuizMemoryItem(q(word: 'w_nope'), corpusMap: testMap()),
        isNull,
      );
    });

    test('alias resolves to canonical with a warning flag', () {
      final v = validateQuestionIdentity(
        q(word: 'w_old'),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.valid);
      expect(v.canonicalId, 'w_hello');
      expect(v.resolvedViaAlias, isTrue);
    });

    test('alias cycle is rejected', () {
      final v = validateQuestionIdentity(
        q(word: 'w_cycle_a'),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.aliasCycle);
      expect(
        resolveQuizMemoryItem(q(word: 'w_cycle_a'), corpusMap: testMap()),
        isNull,
      );
    });

    test('tombstoned ID is rejected', () {
      final v = validateQuestionIdentity(
        q(word: 'w_dead'),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.tombstonedId);
      expect(
        resolveQuizMemoryItem(q(word: 'w_dead'), corpusMap: testMap()),
        isNull,
      );
    });

    test('cross-type collision is rejected', () {
      // w_both lives in both sets: word field must still resolve to a word.
      final v = validateQuestionIdentity(
        q(word: 'w_both'),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.typeMismatch);
      // Sentence field for a word-only id is rejected too.
      final v2 = validateQuestionIdentity(
        q(sentence: 'w_hello'),
        corpusMap: testMap(),
      );
      expect(v2.status, QuizIdentityStatus.typeMismatch);
    });

    test('explicit non-memory without IDs is publishable, never tracked', () {
      final v = validateQuestionIdentity(
        q(nonMemory: true),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.explicitNonMemory);
      expect(v.isPublishable, isTrue);
      expect(v.isTrackable, isFalse);
      expect(resolveQuizMemoryItem(q(nonMemory: true)), isNull);
    });

    test('non-memory WITH an ID is rejected', () {
      final v = validateQuestionIdentity(
        q(word: 'w_hello', nonMemory: true),
        corpusMap: testMap(),
      );
      expect(v.status, QuizIdentityStatus.nonMemoryWithId);
      expect(v.isPublishable, isFalse);
    });

    test('unverified without corpus map (fail closed for publish)', () {
      final v = validateQuestionIdentity(q(word: 'w_hello'));
      expect(v.status, QuizIdentityStatus.unverified);
      expect(v.isPublishable, isFalse);
    });

    test('old serialized questions decode and validate', () {
      final legacy = QuizQuestion.fromMap({
        'type': 'mcq',
        'promptOlChiki': 'x',
        // legacy records predate attribution entirely
      });
      expect(legacy.isNonMemory, isFalse);
      final v = validateQuestionIdentity(legacy, corpusMap: testMap());
      // Unattributed legacy memory questions are NOT auto-linked by text.
      expect(v.status, QuizIdentityStatus.missingAttribution);
    });

    test('legacy non-memory serialized form stays non-memory', () {
      final legacy = QuizQuestion.fromMap({
        'type': 'mcq',
        'promptOlChiki': 'x',
        'isNonMemory': true,
      });
      final v = validateQuestionIdentity(legacy, corpusMap: testMap());
      expect(v.status, QuizIdentityStatus.explicitNonMemory);
    });

    test('resolver without map preserves offline-first raw attribution', () {
      final r = resolveQuizMemoryItem(q(word: 'w_hello'));
      expect(r, isNotNull);
      expect(r!.itemId, 'w_hello');
      expect(r.itemType, ReviewItemType.word);
    });

    test('normalizeSourceAttribution enforces exactly one', () {
      final both = normalizeSourceAttribution(
        sourceWordId: 'w_hello',
        sourceSentenceId: 's_morning',
      );
      expect(both.wordId, 'w_hello');
      expect(both.sentenceId, isNull);
      expect(both.hasCanonical, isTrue);
      final none = normalizeSourceAttribution();
      expect(none.hasCanonical, isFalse);
    });

    test('quiz publish validation aggregates per-question errors', () {
      final quiz = QuizModel(
        id: 'quiz_t',
        questions: [
          q(word: 'w_hello'),
          q(),
          q(word: 'w_nope'),
        ],
      );
      final errors = validateQuizForPublish(quiz, corpusMap: testMap());
      expect(errors, hasLength(2));
      expect(errors[0], contains('Q2'));
      expect(errors[1], contains('Q3'));
    });
  });
}
