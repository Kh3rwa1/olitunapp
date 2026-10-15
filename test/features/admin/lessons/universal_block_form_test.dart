import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/lessons/content/widgets/universal_block_form.dart';
import 'package:itun/shared/models/catalog/lesson_entity.dart';

void main() {
  test('load canonicalises legacy media keys and toEntity keeps extras', () {
    final form = UniversalBlockForm()
      ..load(
        const LessonBlockEntity(
          type: 'video',
          textOlChiki: 'ᱚ',
          textLatin: 'a',
          data: {
            'videoUrl': 'https://cdn.example/clip.mp4',
            'posterUrl': 'https://cdn.example/poster.png',
            'quizRefId': '',
            'custom': 42,
          },
        ),
      );
    addTearDown(form.dispose);

    expect(form.mediaUrl, 'https://cdn.example/clip.mp4');
    expect(form.resolveType(tracingAllowed: false), 'video');

    final entity = form.toEntity(existing: null, tracingAllowed: false);
    expect(entity.type, 'video');
    expect(entity.imageUrl, 'https://cdn.example/poster.png');
    expect(entity.data!['media'], {
      'url': 'https://cdn.example/clip.mp4',
      'kind': 'video',
    });
    expect(entity.data!.containsKey('videoUrl'), isFalse);
  });

  test('tracing only resolves when allowed; quiz id wins over media', () {
    final form = UniversalBlockForm()..tracingEnabled = true;
    addTearDown(form.dispose);

    expect(form.resolveType(tracingAllowed: true), 'tracing');
    expect(form.resolveType(tracingAllowed: false), 'text');

    form
      ..mediaUrl = 'https://cdn.example/a.png'
      ..quizRefCtrl.text = 'quiz_1';
    expect(form.resolveType(tracingAllowed: false), 'quiz');
    final entity = form.toEntity(
      existing: const LessonBlockEntity(type: 'text', data: {'keep': true}),
      tracingAllowed: false,
    );
    expect(entity.data!['quizId'], 'quiz_1');
    expect(entity.data!['keep'], isTrue);
  });
}
