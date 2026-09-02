import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockBakhedRepository extends Mock implements BakhedRepository {}

class FakeBakhedEditorNotifier extends BakhedEditorNotifier {
  @override
  BakhedEditorState build(String arg) {
    bakhedId = arg;
    return BakhedEditorState(item: const AsyncValue.loading());
  }
}

BakhedLyricLine line(String id, int index, int startMs, String text) =>
    BakhedLyricLine(
      id: id,
      lineIndex: index,
      startMs: startMs,
      endMs: startMs + 4000,
      olChiki: text,
      latin: '$text-latin',
      meaning: '$text-meaning',
    );

void main() {
  late MockBakhedRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockBakhedRepository();
    container = ProviderContainer(
      overrides: [
        bakhedRepositoryProvider.overrideWithValue(repository),
        bakhedEditorControllerProvider.overrideWith(
          FakeBakhedEditorNotifier.new,
        ),
      ],
    );
  });

  tearDown(() => container.dispose);

  BakhedLyricsEditorNotifier notifier(String bakhedId) =>
      container.read(bakhedLyricsEditorProvider(bakhedId).notifier);

  BakhedLyricsState state(String bakhedId) =>
      container.read(bakhedLyricsEditorProvider(bakhedId));

  void stubLyrics(
    String bakhedId,
    Either<Failure, List<BakhedLyricLine>> result,
  ) {
    when(
      () => repository.getLyrics(bakhedId),
    ).thenAnswer((_) async => result);
  }

  test(
    'ensureLoaded populates original and current lines and reports not dirty',
    () async {
      stubLyrics('b1', Either.right([line('a', 0, 0, 'A'), line('b', 1, 5000, 'B')]));

      await notifier('b1').ensureLoaded();

      final state1 = state('b1');
      expect(state1.isLoaded, isTrue);
      expect(state1.isLoading, isFalse);
      expect(state1.error, isNull);
      expect(state1.originalLines, hasLength(2));
      expect(state1.currentLines, hasLength(2));
      expect(state1.isDirty, isFalse);
      verify(() => repository.getLyrics('b1')).called(1);
    },
  );

  test(
    'ensureLoaded is a no-op when lyrics are already loaded or loading',
    () async {
      stubLyrics('b1', Either.right([line('a', 0, 0, 'A')]));

      final controller = notifier('b1');
      await controller.ensureLoaded();
      await controller.ensureLoaded();

      verify(() => repository.getLyrics('b1')).called(1);
    },
  );

  test(
    'ensureLoaded records the failure message and allows a later retry',
    () async {
      stubLyrics(
        'b1',
        Either.left(const ServerFailure(message: 'Failed to load lyrics: boom')),
      );

      await notifier('b1').ensureLoaded();

      final failed = state('b1');
      expect(failed.isLoaded, isFalse);
      expect(failed.isLoading, isFalse);
      expect(failed.error, 'Failed to load lyrics: boom');

      stubLyrics('b1', Either.right([line('a', 0, 0, 'A')]));
      await notifier('b1').ensureLoaded();
      expect(state('b1').isLoaded, isTrue);
      verify(() => repository.getLyrics('b1')).called(2);
    },
  );

  test(
    'updateLines sorts by startMs, reindexes lineIndex, and marks the editor dirty',
    () async {
      stubLyrics(
        'b1',
        Either.right([line('a', 0, 0, 'A'), line('b', 1, 5000, 'B')]),
      );
      await notifier('b1').ensureLoaded();

      notifier('b1').updateLines([
        line('a', 0, 7000, 'A'),
        line('b', 1, 3000, 'B'),
      ]);

      final updated = state('b1').currentLines;
      expect(updated.map((l) => l.id).toList(), ['b', 'a']);
      expect(updated.map((l) => l.lineIndex).toList(), [0, 1]);
      expect(updated.map((l) => l.startMs).toList(), [3000, 7000]);
      expect(state('b1').isDirty, isTrue);
      expect(
        container.read(bakhedEditorControllerProvider('b1')).isDirty,
        isTrue,
      );
    },
  );

  test(
    'reorderLines moves the line and keeps the startMs sequence sorted',
    () async {
      stubLyrics(
        'b1',
        Either.right([
          line('a', 0, 0, 'A'),
          line('b', 1, 5000, 'B'),
          line('c', 2, 10000, 'C'),
        ]),
      );
      await notifier('b1').ensureLoaded();

      notifier('b1').reorderLines(1, 3);

      final reordered = state('b1').currentLines;
      expect(reordered.map((l) => l.id).toList(), ['a', 'c', 'b']);
      expect(reordered.map((l) => l.lineIndex).toList(), [0, 1, 2]);
      expect(
        reordered.map((l) => l.startMs).toList(),
        [0, 10000, 12500],
      );
    },
  );

  test('removeLine drops the matching line and reindexes the rest', () async {
    stubLyrics(
      'b1',
      Either.right([
        line('a', 0, 0, 'A'),
        line('b', 1, 5000, 'B'),
        line('c', 2, 10000, 'C'),
      ]),
    );
    await notifier('b1').ensureLoaded();

    notifier('b1').removeLine('b', 1);

    final remaining = state('b1').currentLines;
    expect(remaining.map((l) => l.id).toList(), ['a', 'c']);
    expect(remaining.map((l) => l.lineIndex).toList(), [0, 1]);
    expect(remaining.map((l) => l.startMs).toList(), [0, 10000]);
  });

  test(
    'bulkPaste appends parsed lines with continuing indices and skips blanks',
    () async {
      stubLyrics('b1', Either.right([line('a', 0, 0, 'A')]));
      await notifier('b1').ensureLoaded();

      notifier('b1').bulkPaste('x|y|z\n\nplain', replace: false);

      final lines = state('b1').currentLines;
      expect(lines, hasLength(3));
      expect(lines[1].id, isEmpty);
      expect(lines[1].lineIndex, 1);
      expect(lines[1].startMs, 5000);
      expect(lines[1].endMs, 10000);
      expect(lines[1].olChiki, 'x');
      expect(lines[1].latin, 'y');
      expect(lines[1].meaning, 'z');
      expect(lines[2].olChiki, 'plain');
      expect(lines[2].lineIndex, 2);
    },
  );

  test(
    'bulkPaste with replace clears existing lines and restarts indexing',
    () async {
      stubLyrics(
        'b1',
        Either.right([line('a', 0, 0, 'A'), line('b', 1, 5000, 'B')]),
      );
      await notifier('b1').ensureLoaded();

      notifier('b1').bulkPaste('n1|l1\nn2', replace: true);

      final lines = state('b1').currentLines;
      expect(lines, hasLength(2));
      expect(lines[0].olChiki, 'n1');
      expect(lines[0].lineIndex, 0);
      expect(lines[0].startMs, 0);
      expect(lines[1].olChiki, 'n2');
      expect(lines[1].startMs, 5000);
      expect(state('b1').originalLines, hasLength(2));
    },
  );

  test('markClean syncs the baseline so edits are no longer dirty', () async {
    stubLyrics('b1', Either.right([line('a', 0, 0, 'A')]));
    await notifier('b1').ensureLoaded();

    notifier('b1').updateLines([line('a', 0, 0, 'A'), line('b', 1, 5000, 'B')]);
    expect(state('b1').isDirty, isTrue);

    notifier('b1').markClean();
    expect(state('b1').isDirty, isFalse);

    notifier('b1').updateLines([line('a', 0, 0, 'A')]);
    expect(state('b1').isDirty, isTrue);
  });

  test('a fresh state is never reported as dirty', () {
    expect(const BakhedLyricsState().isDirty, isFalse);
    expect(state('b1').isDirty, isFalse);
  });
}
