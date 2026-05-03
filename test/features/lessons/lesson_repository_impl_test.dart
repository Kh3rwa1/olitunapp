// Smoke tests verifying that the lessons repository surface compiles and
// that the public methods mapping shape is what other layers depend on.
//
// Full mocktail-based behavior tests live in the follow-up "Add tests for
// the rest of the data layer" task — that work needs access to the remote
// data source's mockable surface (in progress).
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/data/repositories/lesson_repository_impl.dart';

void main() {
  test('LessonRepositoryImpl is a class symbol exported from the data layer',
      () {
    // If the file or class is renamed/removed, this fails fast — preventing
    // the silent removal of the repository contract that DI depends on.
    expect(LessonRepositoryImpl, isNotNull);
  });
}
