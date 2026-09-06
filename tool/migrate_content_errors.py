"""One-off, assertion-checked migration on the content-error review branch."""
from pathlib import Path


def patch(path, old, new, count=1):
    target = Path(path)
    text = target.read_text()
    actual = text.count(old)
    if actual != count:
        raise RuntimeError(f'{path}: expected {count} anchors, got {actual}')
    target.write_text(text.replace(old, new))


helper = 'lib/shared/widgets/content_load_guard.dart'
Path(helper).write_text('''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_widgets.dart';

/// Keeps dependency failures distinct from genuine empty content.
Widget? buildContentLoadGuard(
  List<AsyncValue<Object?>> dependencies, {
  required VoidCallback onRetry,
}) {
  if (dependencies.any((value) => value.hasError)) {
    return AppErrorState(
      message: 'Content could not be loaded. Please try again.',
      onRetry: onRetry,
    );
  }
  if (dependencies.any((value) => value.isLoading)) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
  return null;
}
''')

for filename, model, kind in [
    ('letter_grid_content.dart', 'Letters', 'letter'),
    ('number_grid_content.dart', 'Numbers', 'number'),
    ('sentence_list_content.dart', 'Sentences', 'sentence'),
    ('vocabulary_list_content.dart', 'Words', 'word'),
]:
    path = 'lib/features/lessons/presentation/widgets/lesson_content/' + filename
    patch(path, "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:itun/shared/widgets/content_load_guard.dart';")
    patch(path,
          f'    final all{model} = ref.watch(learner{model}Provider).value ?? [];\n    final lessons = ref.watch(learnerLessonsProvider).value ?? [];',
          f'''    final contentAsync = ref.watch(learner{model}Provider);
    final lessonsAsync = ref.watch(learnerLessonsProvider);
    final loadState = buildContentLoadGuard(
      [contentAsync, lessonsAsync],
      onRetry: () {{
        ref.invalidate(contentListProvider((ContentKind.{kind}, null)));
        ref.invalidate(contentListProvider((ContentKind.lesson, null)));
      }},
    );
    if (loadState != null) return loadState;
    final all{model} = contentAsync.requireValue;
    final lessons = lessonsAsync.requireValue;''')

home = 'lib/features/home/presentation/home_screen.dart'
patch(home, "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:itun/shared/widgets/content_load_guard.dart';")
patch(home, '    final allLessons = ref.watch(learnerLessonsProvider).value ?? [];', '    final lessonsAsync = ref.watch(learnerLessonsProvider);\n    final allLessons = lessonsAsync.valueOrNull ?? [];')
patch(home, '                    child: NextBestActionCard(nextLessonId: nextLesson?.id),', '''                    child: buildContentLoadGuard(
                      [lessonsAsync],
                      onRetry: () => ref.invalidate(
                        contentListProvider((ContentKind.lesson, null)),
                      ),
                    ) ?? NextBestActionCard(nextLessonId: nextLesson?.id),''')

# Optional navigation may be unavailable; never throw while resolving a link.
for path in [
    'lib/features/lessons/presentation/lesson_block_detail_screen.dart',
    'lib/features/lessons/presentation/widgets/dynamic_blocks/dynamic_text_block.dart',
    'lib/features/lessons/presentation/widgets/dynamic_blocks/dynamic_universal_media_block.dart',
    'lib/features/lessons/presentation/widgets/lesson_content/dynamic_block_grid_cell.dart',
]:
    target = Path(path)
    text = target.read_text()
    import re
    text, count = re.subn(r'(ref\.(?:read|watch)\(learner(?:Lessons|Letters|Numbers|Words|Sentences)Provider\))\.value\b', r'\1.valueOrNull', text)
    if count == 0:
        raise RuntimeError(f'{path}: no navigation reads found')
    target.write_text(text)

quiz = 'lib/features/quiz/data/quiz_repository.dart'
patch(quiz, '''        if (lessonsAsync.isLoading) {
          return const AsyncValue.loading();
        }''', '''        if (lessonsAsync.hasError) {
          return AsyncValue.error(
            lessonsAsync.error!,
            lessonsAsync.stackTrace ?? StackTrace.current,
          );
        }
        if (lessonsAsync.isLoading) {
          return const AsyncValue.loading();
        }''', count=2)

patch('lib/shared/providers/quizzes_provider.dart', '''    final words = ref.read(learnerWordsProvider).value;
    final sentences = ref.read(learnerSentencesProvider).value;''', '''    final wordsAsync = ref.read(learnerWordsProvider);
    final sentencesAsync = ref.read(learnerSentencesProvider);
    if (wordsAsync.hasError || sentencesAsync.hasError) {
      // Base quizzes are independently valid cached/bundled content. Do not
      // discard them, but do not invent empty success if no fallback exists.
      if (_baseQuizzes.isNotEmpty) {
        state = AsyncValue.data(_baseQuizzes);
      } else {
        final failed = wordsAsync.hasError ? wordsAsync : sentencesAsync;
        state = AsyncValue.error(
          failed.error!,
          failed.stackTrace ?? StackTrace.current,
        );
      }
      return;
    }
    final words = wordsAsync.valueOrNull;
    final sentences = sentencesAsync.valueOrNull;''')

prefetch = 'lib/features/home/presentation/providers/home_prefetch_provider.dart'
patch(prefetch, "import '../../../../shared/providers/learner_content_providers.dart';", "import '../../../../shared/repositories/content_repository.dart';\nimport '../../../../shared/models/content_item.dart';")
patch(prefetch, '''    // 1. Trigger reading of core learner content providers
    ref.read(learnerWordsProvider);
    ref.read(learnerNumbersProvider);
    ref.read(learnerSentencesProvider);
    ref.read(learnerLettersProvider);''', '''    if (_disposed) return;
    // Observe each background Future immediately, including failures arriving
    // after disposal. This handles only the prefetch task: provider error
    // states remain available to visible screens and their retry controls.
    final loads = <Future<void>>[];
    for (final kind in [
      ContentKind.word,
      ContentKind.number,
      ContentKind.sentence,
      ContentKind.letter,
    ]) {
      final provider = contentListProvider((kind, null));
      if (forceRefresh) ref.invalidate(provider);
      loads.add(
        ref.read(provider.future).then<void>(
          (_) {},
          onError: (Object error, StackTrace stack) {
            AppLogger.debug('HomePrefetch: ${kind.name} unavailable: $error');
          },
        ),
      );
    }''')
patch(prefetch, '''    }
  }
}

final homePrefetchProvider''', '''    }
    await Future.wait(loads);
  }
}

final homePrefetchProvider''')
print('Content-error consumer migration applied with exact source assertions.')
