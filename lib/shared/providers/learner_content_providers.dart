import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/lessons/domain/entities/lesson_entity.dart';
import '../models/content_models.dart';
import '../repositories/content_repository.dart';

final learnerLessonsProvider = Provider<AsyncValue<List<LessonEntity>>>((ref) {
  return ref.watch(contentListProvider((ContentKind.lesson, null))).whenData(
    (list) => list.map((item) => item.toLessonEntity()).toList(),
  );
});

final learnerWordsProvider = Provider<AsyncValue<List<WordModel>>>((ref) {
  return ref.watch(contentListProvider((ContentKind.word, null))).whenData(
    (list) => list.map((item) => item.toWordModel()).toList(),
  );
});

final learnerLettersProvider = Provider<AsyncValue<List<LetterModel>>>((ref) {
  return ref.watch(contentListProvider((ContentKind.letter, null))).whenData(
    (list) => list.map((item) => item.toLetterModel()).toList(),
  );
});

final learnerNumbersProvider = Provider<AsyncValue<List<NumberModel>>>((ref) {
  return ref.watch(contentListProvider((ContentKind.number, null))).whenData(
    (list) => list.map((item) => item.toNumberModel()).toList(),
  );
});

final learnerSentencesProvider = Provider<AsyncValue<List<SentenceModel>>>((ref) {
  return ref.watch(contentListProvider((ContentKind.sentence, null))).whenData(
    (list) => list.map((item) => item.toSentenceModel()).toList(),
  );
});
