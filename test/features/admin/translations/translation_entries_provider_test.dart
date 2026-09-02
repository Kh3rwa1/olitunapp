import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/translations/models/translation_entry.dart';
import 'package:itun/features/admin/presentation/translations/providers/translation_entries_provider.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';
import 'package:itun/features/rhymes/domain/rhyme_model.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/rhymes_providers.dart';
import 'package:itun/shared/providers/sentences_provider.dart';
import 'package:itun/shared/providers/words_provider.dart';

class FakeWordsNotifier extends WordsNotifier {
  FakeWordsNotifier(this.items, {this.loading = false});
  final List<WordModel> items;
  final bool loading;

  @override
  AsyncValue<List<WordModel>> build() =>
      loading ? const AsyncValue.loading() : AsyncValue.data(items);
}

class FakeSentencesNotifier extends SentencesNotifier {
  FakeSentencesNotifier(this.items, {this.loading = false});
  final List<SentenceModel> items;
  final bool loading;

  @override
  AsyncValue<List<SentenceModel>> build() =>
      loading ? const AsyncValue.loading() : AsyncValue.data(items);
}

class FakeLessonNotifier extends LessonNotifier {
  FakeLessonNotifier(this.items, {this.loading = false});
  final List<LessonEntity> items;
  final bool loading;

  @override
  AsyncValue<List<LessonEntity>> build() =>
      loading ? const AsyncValue.loading() : AsyncValue.data(items);
}

class FakeCategoryNotifier extends CategoryNotifier {
  FakeCategoryNotifier(this.items, {this.loading = false});
  final List<CategoryEntity> items;
  final bool loading;

  @override
  AsyncValue<List<CategoryEntity>> build() =>
      loading ? const AsyncValue.loading() : AsyncValue.data(items);
}

class FakeRhymesNotifier extends RhymesNotifier {
  FakeRhymesNotifier(this.items, {this.loading = false});
  final List<RhymeModel> items;
  final bool loading;

  @override
  AsyncValue<List<RhymeModel>> build() =>
      loading ? const AsyncValue.loading() : AsyncValue.data(items);
}

ProviderContainer createContainer({
  List<WordModel> words = const [],
  List<SentenceModel> sentences = const [],
  List<LessonEntity> lessons = const [],
  List<CategoryEntity> categories = const [],
  List<RhymeModel> rhymes = const [],
  bool allLoading = false,
}) {
  return ProviderContainer(
    overrides: [
      wordsProvider.overrideWith(
        () => FakeWordsNotifier(words, loading: allLoading),
      ),
      sentencesProvider.overrideWith(
        () => FakeSentencesNotifier(sentences, loading: allLoading),
      ),
      lessonNotifierProvider.overrideWith(
        () => FakeLessonNotifier(lessons, loading: allLoading),
      ),
      categoryNotifierProvider.overrideWith(
        () => FakeCategoryNotifier(categories, loading: allLoading),
      ),
      rhymesProvider.overrideWith(
        () => FakeRhymesNotifier(rhymes, loading: allLoading),
      ),
    ],
  );
}

WordModel word(String id) => WordModel(
  id: id,
  wordOlChiki: 'ᱚ',
  wordLatin: '$id-latin',
  meaning: '$id meaning',
  category: 'animals',
  pronunciation: 'o',
);

void main() {
  test(
    'flattens words, sentences, lessons with blocks, categories, and rhymes in source order',
    () {
      final container = createContainer(
        words: [word('w1')],
        sentences: [
          SentenceModel(
            id: 's1',
            sentenceOlChiki: 'ᱥ',
            sentenceLatin: 'sentence latin',
            meaning: 'a sentence',
          ),
        ],
        lessons: [
          const LessonEntity(
            id: 'l1',
            categoryId: 'cat1',
            titleOlChiki: 'ᱞ',
            titleLatin: 'Lesson One',
            description: 'Learn the basics',
            blocks: [
              LessonBlockEntity(
                type: 'text',
                textOlChiki: 'ᱛ',
                textLatin: 'block text',
              ),
            ],
          ),
        ],
        categories: [
          const CategoryEntity(
            id: 'cat1',
            titleOlChiki: 'ᱠ',
            titleLatin: 'Animals',
            description: 'All about animals',
          ),
        ],
        rhymes: [
          RhymeModel(
            id: 'r1',
            titleOlChiki: 'ᱵ',
            titleLatin: 'Sohrai Bakhed',
            contentOlChiki: 'ᱵᱟ',
            contentLatin: 'Sohrai story content',
            categoryId: 'cat1',
          ),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(translationEntriesProvider);

      expect(entries, hasLength(6));
      expect(
        entries.map((e) => e.kind).toList(),
        [
          TranslationKind.word,
          TranslationKind.sentence,
          TranslationKind.lesson,
          TranslationKind.lesson,
          TranslationKind.category,
          TranslationKind.rhyme,
        ],
      );
      expect(entries[0].id, 'w1');
      expect(entries[1].id, 's1');
      expect(entries[2].id, 'l1');
      expect(entries[3].id, 'l1_block_0');
      expect(entries[4].id, 'cat1');
      expect(entries[5].id, 'r1');
    },
  );

  test(
    'lesson entries fall back to the latin title for meaning and only include blocks with text',
    () {
      final container = createContainer(
        lessons: [
          const LessonEntity(
            id: 'l2',
            categoryId: 'cat1',
            titleOlChiki: 'ᱞ',
            titleLatin: 'Numbers',
            blocks: [
              LessonBlockEntity(
                type: 'text',
                textLatin: 'one',
                data: {'meaning': 'ek meaning', 'pronunciation': 'ek'},
              ),
              LessonBlockEntity(type: 'image', imageUrl: 'https://x/y.png'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(translationEntriesProvider);

      expect(entries, hasLength(2));
      final lessonEntry = entries[0];
      expect(lessonEntry.englishMeaning, 'Numbers');
      expect(lessonEntry.category, 'cat1');

      final blockEntry = entries[1];
      expect(blockEntry.id, 'l2_block_0');
      expect(blockEntry.textOlChiki, isEmpty);
      expect(blockEntry.textLatin, 'one');
      expect(blockEntry.englishMeaning, 'ek meaning');
      expect(blockEntry.pronunciation, 'ek');
      expect(blockEntry.category, 'Numbers');
    },
  );

  test(
    'category entries prefer the description for meaning and rhymes prefer the latin content',
    () {
      final container = createContainer(
        categories: [
          const CategoryEntity(
            id: 'catA',
            titleOlChiki: 'ᱮ',
            titleLatin: 'Colors',
            description: 'Learn colors',
          ),
          const CategoryEntity(
            id: 'catB',
            titleOlChiki: 'ᱯ',
            titleLatin: 'Shapes',
          ),
        ],
        rhymes: [
          RhymeModel(
            id: 'r2',
            titleOlChiki: 'ᱥ',
            titleLatin: 'Bakhed',
            contentOlChiki: 'ᱥᱟ',
            contentLatin: 'Story body',
            category: 'Stories',
          ),
          RhymeModel(
            id: 'r3',
            titleOlChiki: 'ᱴ',
            titleLatin: 'Kudum',
            contentOlChiki: 'ᱴᱮ',
            contentLatin: '',
            categoryId: 'catB',
          ),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(translationEntriesProvider);

      expect(entries[0].englishMeaning, 'Learn colors');
      expect(entries[1].englishMeaning, 'Shapes');
      expect(entries[1].category, 'Category');
      expect(entries[2].englishMeaning, 'Story body');
      expect(entries[2].category, 'Stories');
      expect(entries[3].englishMeaning, 'Kudum');
      expect(entries[3].category, 'catB');
    },
  );

  test(
    'maps Ol Chiki and latin text plus optional metadata for words and sentences',
    () {
      final container = createContainer(
        words: [
          WordModel(
            id: 'w9',
            wordOlChiki: 'ᱦ',
            wordLatin: 'hor',
            meaning: 'person',
            pronunciation: 'hor-pron',
            category: 'people',
          ),
        ],
        sentences: [
          SentenceModel(
            id: 's9',
            sentenceOlChiki: 'ᱥᱟ',
            sentenceLatin: 'saale',
            meaning: 'greeting',
            pronunciation: 'saale-pron',
            audioUrl: 'https://example.com/s9.mp3',
          ),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(translationEntriesProvider);

      expect(entries.first.kindLabel, 'Word');
      expect(entries.first.textOlChiki, 'ᱦ');
      expect(entries.first.textLatin, 'hor');
      expect(entries.first.englishMeaning, 'person');
      expect(entries.first.pronunciation, 'hor-pron');
      expect(entries.first.category, 'people');

      final sentence = entries[1];
      expect(sentence.kindLabel, 'Sentence');
      expect(sentence.pronunciation, 'saale-pron');
      expect(sentence.audioUrl, 'https://example.com/s9.mp3');
    },
  );

  test('yields an empty list while every source is still loading', () {
    final container = createContainer(allLoading: true);
    addTearDown(container.dispose);

    expect(container.read(translationEntriesProvider), isEmpty);
  });
}
