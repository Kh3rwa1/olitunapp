import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/core/api/admin_content_client.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/features/quiz/data/quizzes_provider.dart';
import 'package:itun/shared/quiz_engine/quiz_engine.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/core/auth/auth_providers.dart';

import '../../../helpers/fake_admin_worker.dart';

/// Test data served by the fake Worker (quizzes) and the learner
/// words/sentences providers.
class FakeQuizBackend {
  List<Map<String, dynamic>> wordsData = [];
  List<Map<String, dynamic>> sentencesData = [];
  List<Map<String, dynamic>> quizzesData = [];

  /// Worker `/api/v1/quizzes` reads.
  int quizListRequests = 0;
}

void main() {
  group('Dynamic Hybrid Quizzes Generator Tests', () {
    late FakeQuizBackend backend;
    late FakeAdminWorker worker;
    late SharedPreferences prefs;

    setUpAll(() async {
      Hive.init(
        (await Directory.systemTemp.createTemp('test_hive_quizzes_v2_')).path,
      );
      CacheService.resetForTesting();
    });

    tearDownAll(() async {
      await CacheService.clear();
    });

    setUp(() async {
      backend = FakeQuizBackend();
      worker = FakeAdminWorker();
      await CacheService.clear();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    final dummyWords = [
      // Beginner Words
      WordModel(
        id: 'w1',
        wordOlChiki: 'ᱡᱚᱦᱟᱨ',
        wordLatin: 'Johar',
        meaning: 'Hello',
        category: 'greeting',
        order: 1,
      ),
      WordModel(
        id: 'w2',
        wordOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
        wordLatin: 'Sarhaw',
        meaning: 'Thank you',
        category: 'greeting',
        order: 2,
      ),
      WordModel(
        id: 'w3',
        wordOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
        wordLatin: 'Sagun Daram',
        meaning: 'Welcome',
        category: 'greeting',
        order: 3,
      ),
      WordModel(
        id: 'w4',
        wordOlChiki: 'ᱦᱮᱸ',
        wordLatin: 'Hẽ',
        meaning: 'Yes',
        category: 'basic',
        order: 4,
      ),
      WordModel(
        id: 'w5',
        wordOlChiki: 'ᱵᱟᱝ',
        wordLatin: 'Bang',
        meaning: 'No',
        category: 'basic',
        order: 5,
      ),
      WordModel(
        id: 'w6',
        wordOlChiki: 'ᱵᱟᱵᱟ',
        wordLatin: 'Baba',
        meaning: 'Father',
        category: 'family',
        order: 6,
      ),
      WordModel(
        id: 'w7',
        wordOlChiki: 'ᱟᱭᱳ',
        wordLatin: 'Ayo',
        meaning: 'Mother',
        category: 'family',
        order: 7,
      ),
      WordModel(
        id: 'w8',
        wordOlChiki: 'ᱦᱟᱹᱨᱤᱭᱟᱹᱲ',
        wordLatin: 'Hariar',
        meaning: 'Green',
        category: 'colors',
        order: 8,
      ),
      WordModel(
        id: 'w9',
        wordOlChiki: 'ᱟᱨᱟᱜ',
        wordLatin: 'Arag',
        meaning: 'Red',
        category: 'colors',
        order: 9,
      ),

      // Intermediate Words
      WordModel(
        id: 'w10',
        wordOlChiki: 'ᱡᱚᱢ',
        wordLatin: 'Jom',
        meaning: 'Eat',
        category: 'daily',
        order: 10,
      ),
      WordModel(
        id: 'w11',
        wordOlChiki: 'ᱧᱩ',
        wordLatin: 'Nju',
        meaning: 'Drink',
        category: 'daily',
        order: 11,
      ),
      WordModel(
        id: 'w12',
        wordOlChiki: 'ᱥᱮᱱ',
        wordLatin: 'Sen',
        meaning: 'Go',
        category: 'daily',
        order: 12,
      ),
      WordModel(
        id: 'w13',
        wordOlChiki: 'ᱫᱟᱨᱮ',
        wordLatin: 'Dare',
        meaning: 'Tree',
        category: 'nature',
        order: 13,
      ),
      WordModel(
        id: 'w14',
        wordOlChiki: 'ᱦᱚᱲᱢᱚ',
        wordLatin: 'Hormo',
        meaning: 'Body',
        category: 'body',
        order: 14,
      ),

      // Advanced Words
      WordModel(
        id: 'w15',
        wordOlChiki: 'ᱥᱤᱝᱜᱮ',
        wordLatin: 'Singge',
        meaning: 'Sunday',
        category: 'time',
        order: 15,
      ),
      WordModel(
        id: 'w16',
        wordOlChiki: 'ᱧᱤᱫᱟᱹ',
        wordLatin: 'Njida',
        meaning: 'Night',
        category: 'time',
        order: 16,
      ),
      WordModel(
        id: 'w17',
        wordOlChiki: 'ᱥᱮᱨᱢᱟ',
        wordLatin: 'Serma',
        meaning: 'Year',
        category: 'time',
        order: 17,
      ),
      WordModel(
        id: 'w18',
        wordOlChiki: 'ᱠᱷᱮᱹᱨᱣᱟᱲ',
        wordLatin: 'Kherwar',
        meaning: 'Santali community',
        category: 'trending',
        order: 18,
      ),
    ];

    final dummySentences = [
      // Beginner Sentences
      SentenceModel(
        id: 's1',
        sentenceOlChiki: 'ᱡᱚᱦᱟᱨ ᱜᱮ ᱵᱟᱵᱟ',
        sentenceLatin: 'Johar ge baba',
        meaning: 'Hello father',
        pronunciation: 'Jo-har ge ba-ba',
        category: 'basics',
        order: 1,
      ),
      SentenceModel(
        id: 's2',
        sentenceOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ ᱟᱭᱳ',
        sentenceLatin: 'Sagun setag ayo',
        meaning: 'Good morning mother',
        pronunciation: 'Sa-gun se-tag a-yo',
        category: 'basics',
        order: 2,
      ),
      SentenceModel(
        id: 's3',
        sentenceOlChiki: 'ᱤᱠᱟᱹ ᱠᱟᱹᱧ ᱢᱮ',
        sentenceLatin: 'Ika kanj me',
        meaning: 'Excuse me / Sorry',
        pronunciation: 'I-ka kanj me',
        category: 'polite',
        order: 3,
      ),

      // Intermediate Sentences
      SentenceModel(
        id: 's4',
        sentenceOlChiki: 'ᱟᱢ ᱫᱚ ᱪᱮᱫ ᱮᱢ ᱡᱚᱢ ᱮᱫᱟ?',
        sentenceLatin: 'Am do ched em jomedada?',
        meaning: 'What are you eating?',
        pronunciation: 'Am do ched em jom-e-da?',
        category: 'conversations',
        order: 4,
      ),

      // Advanced Sentences
      SentenceModel(
        id: 's5',
        sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱥᱤᱝᱜᱮ ᱠᱟᱱᱟ',
        sentenceLatin: 'Tehenj do singge kana',
        meaning: 'Today is Sunday',
        pronunciation: 'Te-henj do sing-ge ka-na',
        category: 'time_weather',
        order: 5,
      ),
    ];

    Future<List<QuizModel>> waitForQuizzes(ProviderContainer container) =>
        container.read(quizzesProvider.future);

    ProviderContainer createContainer(FakeQuizBackend backend) {
      return ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          adminContentClientProvider.overrideWithValue(worker.adminClient),
          quizzesHttpClientProvider.overrideWithValue(
            MockClient((request) async {
              if (!request.url.path.endsWith('/api/v1/quizzes')) {
                return http.Response('Not Found', 404);
              }
              backend.quizListRequests++;
              return http.Response.bytes(
                utf8.encode(
                  jsonEncode({'ok': true, 'quizzes': backend.quizzesData}),
                ),
                200,
                headers: const {'content-type': 'application/json'},
              );
            }),
          ),
          isAuthenticatedProvider.overrideWith((ref) => true),
          learnerWordsProvider.overrideWith((ref) {
            final list = backend.wordsData.map(WordModel.fromJson).toList();
            return AsyncValue.data(list);
          }),
          learnerSentencesProvider.overrideWith((ref) {
            final list = backend.sentencesData
                .map(SentenceModel.fromJson)
                .toList();
            return AsyncValue.data(list);
          }),
        ],
      );
    }

    test(
      'initializes with default alphabets and numbers quizzes when database is empty',
      () async {
        final container = createContainer(backend);
        addTearDown(container.dispose);

        // Read quizzes notifier initial state
        final quizzesState = container.read(quizzesProvider);
        expect(quizzesState, const AsyncValue<List<QuizModel>>.loading());

        // Wait for data load
        final quizzes = await waitForQuizzes(container);
        expect(quizzes, isNotEmpty);
        expect(quizzes.any((q) => q.categoryId == 'alphabets'), isTrue);
        expect(quizzes.any((q) => q.categoryId == 'numbers'), isTrue);
      },
    );

    test(
      'compiles hybrid quizzes with dynamic MCQ & Fill-Blank combinations',
      () async {
        backend.wordsData = dummyWords.map((w) => w.toJson()).toList();
        backend.sentencesData = dummySentences.map((s) => s.toJson()).toList();

        final container = createContainer(backend);
        addTearDown(container.dispose);

        // Wait specifically for the dynamic hybrid quizzes to be compiled
        AsyncValue<List<QuizModel>> state = const AsyncValue.loading();
        for (var i = 0; i < 20; i++) {
          await Future.delayed(Duration.zero);
          container.read(quizzesProvider);
          state = container.read(quizzesProvider);
          if (state.value?.any((q) => q.id == 'quiz_dynamic_hybrid_beginner') ??
              false) {
            break;
          }
        }
        final quizzes = state.value!;

        // Verify the beginner hybrid challenge exists
        final beginnerHybrid = quizzes.firstWhere(
          (q) => q.id == 'quiz_dynamic_hybrid_beginner',
        );
        expect(beginnerHybrid.title, 'Daily Mixed Challenge');
        expect(beginnerHybrid.categoryId, 'cat_vocab');
        expect(beginnerHybrid.level, 'beginner');
        expect(beginnerHybrid.order, 14);
        expect(beginnerHybrid.questions.length, 10);

        // Verify that it contains both 'mcq' and 'fill_blank' questions
        final hasMcq = beginnerHybrid.questions.any((q) => q.type == 'mcq');
        final hasFillBlank = beginnerHybrid.questions.any(
          (q) => q.type == 'fill_blank',
        );
        expect(
          hasMcq,
          isTrue,
          reason: 'Beginner hybrid quiz should contain vocabulary MCQs',
        );
        expect(
          hasFillBlank,
          isTrue,
          reason:
              'Beginner hybrid quiz should contain sentence fill-in-the-blank questions',
        );

        // Verify intermediate hybrid challenge exists
        final intermediateHybrid = quizzes.firstWhere(
          (q) => q.id == 'quiz_dynamic_hybrid_intermediate',
        );
        expect(intermediateHybrid.title, 'Mastery Mixed Challenge');
        expect(intermediateHybrid.categoryId, 'cat_sentences');
        expect(intermediateHybrid.level, 'intermediate');
        expect(intermediateHybrid.order, 15);
        expect(intermediateHybrid.questions.length, 10);
        expect(
          intermediateHybrid.questions.any((q) => q.type == 'mcq'),
          isTrue,
        );
        expect(
          intermediateHybrid.questions.any((q) => q.type == 'fill_blank'),
          isTrue,
        );

        // Verify advanced hybrid challenge exists
        final advancedHybrid = quizzes.firstWhere(
          (q) => q.id == 'quiz_dynamic_hybrid_advanced',
        );
        expect(advancedHybrid.title, 'Grand Mixed Challenge');
        expect(advancedHybrid.categoryId, 'cat_sentences');
        expect(advancedHybrid.level, 'advanced');
        expect(advancedHybrid.order, 16);
        expect(advancedHybrid.questions.length, 12);
        expect(advancedHybrid.questions.any((q) => q.type == 'mcq'), isTrue);
        expect(
          advancedHybrid.questions.any((q) => q.type == 'fill_blank'),
          isTrue,
        );
      },
    );

    test(
      'safety fallback handles empty database gracefully without crashing',
      () async {
        backend.wordsData = [];
        backend.sentencesData = [];

        final container = createContainer(backend);
        addTearDown(container.dispose);

        final quizzes = await waitForQuizzes(container);
        expect(quizzes, isNotEmpty);

        // Verify no hybrid quizzes are added when pools are completely empty
        final hybridIds = [
          'quiz_dynamic_hybrid_beginner',
          'quiz_dynamic_hybrid_intermediate',
          'quiz_dynamic_hybrid_advanced',
        ];
        for (final id in hybridIds) {
          expect(quizzes.any((q) => q.id == id), isFalse);
        }
      },
    );

    test('quiz engine can be tested directly without Riverpod or Appwrite', () {
      final quizzes = QuizEngine.compile(
        baseQuizzes: const [],
        words: dummyWords,
        sentences: dummySentences,
      );

      expect(quizzes.any((q) => q.categoryId == 'alphabets'), isTrue);
      expect(quizzes.any((q) => q.categoryId == 'numbers'), isTrue);
      expect(
        quizzes.where((q) => q.id.startsWith('quiz_dynamic_vocab_')).length,
        greaterThanOrEqualTo(5),
      );
      expect(
        quizzes
            .expand((q) => q.questions)
            .where((q) => q.type == 'fill_blank')
            .length,
        greaterThan(0),
      );
    });

    test(
      'admin CRUD updates quizzes optimistically without full reloads',
      () async {
        backend.quizzesData = [
          QuizModel(
            id: 'existing_quiz',
            categoryId: 'custom',
            title: 'Existing Quiz',
          ).toJson(),
        ];

        final container = createContainer(backend);
        addTearDown(container.dispose);

        await waitForQuizzes(container);
        expect(backend.quizListRequests, 1);

        final notifier = container.read(quizzesProvider.notifier);
        await notifier.add(
          QuizModel(id: 'new_quiz', categoryId: 'custom', title: 'New Quiz'),
        );
        final created = worker.requestsWith('PUT').single;
        expect(created.url.path, '/api/v1/admin/content/quizzes/new_quiz');
        expect(
          created.headers['Authorization'],
          'Bearer ${FakeAdminWorker.jwt}',
        );
        expect(worker.bodyOf(created)['title'], 'New Quiz');
        expect(worker.bodyOf(created)['questions'], isA<String>());
        expect(backend.quizListRequests, 1);
        expect(
          container
              .read(quizzesProvider)
              .value!
              .any((quiz) => quiz.id == 'new_quiz'),
          isTrue,
        );

        await notifier.updateItem(
          QuizModel(
            id: 'new_quiz',
            categoryId: 'custom',
            title: 'Updated Quiz',
          ),
        );
        expect(worker.requestsWith('PUT'), hasLength(2));
        expect(worker.rows['quizzes']!['new_quiz']!['title'], 'Updated Quiz');
        expect(backend.quizListRequests, 1);
        expect(
          container
              .read(quizzesProvider)
              .value!
              .firstWhere((quiz) => quiz.id == 'new_quiz')
              .title,
          'Updated Quiz',
        );

        await notifier.delete('new_quiz');
        expect(
          worker.requestsWith('DELETE').single.url.path,
          '/api/v1/admin/content/quizzes/new_quiz',
        );
        expect(worker.rows['quizzes'], isNot(contains('new_quiz')));
        expect(backend.quizListRequests, 1);
        expect(
          container
              .read(quizzesProvider)
              .value!
              .any((quiz) => quiz.id == 'new_quiz'),
          isFalse,
        );
      },
    );

    test(
      'quizzesByIdProvider returns a cached map for fast O(1) lookups',
      () async {
        final container = createContainer(backend);
        addTearDown(container.dispose);

        final quizzes = await waitForQuizzes(container);
        expect(quizzes, isNotEmpty);

        final quizzesMapAsync = container.read(quizzesByIdProvider);
        expect(quizzesMapAsync.hasValue, isTrue);

        final quizzesMap = quizzesMapAsync.value!;
        for (final quiz in quizzes) {
          expect(quizzesMap[quiz.id], equals(quiz));
        }
      },
    );

    test('a failed Worker write rolls back and rethrows', () async {
      final container = createContainer(backend);
      addTearDown(container.dispose);
      await waitForQuizzes(container);
      worker.failStatus = 403;

      await expectLater(
        container
            .read(quizzesProvider.notifier)
            .add(QuizModel(id: 'denied', categoryId: 'custom', title: 'No')),
        throwsA(isA<Exception>()),
      );
      expect(
        container.read(quizzesProvider).value!.any((q) => q.id == 'denied'),
        isFalse,
      );
    });
  });
}
