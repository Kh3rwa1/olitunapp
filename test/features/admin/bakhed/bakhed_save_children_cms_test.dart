import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/shared/media/media_uploader.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/features/admin/data/gamification_cms_api.dart';
import 'package:itun/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements BakhedRepository {}

class _Cms extends Mock implements GamificationCmsApi {}

class _Uploader extends Mock implements MediaUploader {}

class _FakeItem extends Fake implements ContentItem {}

const _bakhedId = 'bk1';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeItem());
    registerFallbackValue(<String, dynamic>{});
  });

  late _Repo repo;
  late _Cms cms;
  late ProviderContainer container;

  setUp(() async {
    repo = _Repo();
    cms = _Cms();
    final rhyme = ContentItem(
      id: _bakhedId,
      kind: ContentKind.rhyme,
      categoryId: 'karam',
      title: 'Karam Bakhed',
      blocks: const [],
      updatedAt: DateTime(2026),
      durationMs: 9000,
    );
    when(() => repo.get(_bakhedId)).thenAnswer((_) async => right(rhyme));
    when(() => repo.upsert(any())).thenAnswer((_) async => right(unit));
    when(() => repo.getLyrics(_bakhedId)).thenAnswer(
      (_) async => right(const [
        BakhedLyricLine(
          id: 'l1',
          lineIndex: 0,
          startMs: 0,
          endMs: 2000,
          olChiki: '',
          latin: 'old one',
          meaning: '',
        ),
        BakhedLyricLine(
          id: 'l2',
          lineIndex: 1,
          startMs: 2000,
          endMs: 4000,
          olChiki: '',
          latin: 'two',
          meaning: '',
        ),
      ]),
    );
    when(
      () => repo.getVocabulary(_bakhedId),
    ).thenAnswer((_) async => right(const []));
    when(() => repo.getCulturalNotes(_bakhedId)).thenAnswer(
      (_) async => right(const [
        BakhedCulturalNote(
          noteId: 'n1',
          title: 'Old note',
          body: 'x',
          source: '',
        ),
      ]),
    );
    when(
      () => cms.upsertRow(
        any(),
        any(),
        any(),
        createOnly: any(named: 'createOnly'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(() => cms.deleteRow(any(), any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        bakhedRepositoryProvider.overrideWithValue(repo),
        gamificationCmsApiProvider.overrideWithValue(cms),
        mediaUploaderProvider.overrideWithValue(_Uploader()),
      ],
    );
    container.read(bakhedEditorControllerProvider(_bakhedId).notifier);
    await container
        .read(bakhedLyricsEditorProvider(_bakhedId).notifier)
        .ensureLoaded();
    await container
        .read(bakhedVocabularyEditorProvider(_bakhedId).notifier)
        .ensureLoaded();
    await container
        .read(bakhedNotesEditorProvider(_bakhedId).notifier)
        .ensureLoaded();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  tearDown(() => container.dispose());

  test('save writes lyric and note diffs to the Worker CMS', () async {
    final lyrics = container.read(bakhedLyricsEditorProvider(_bakhedId));
    expect(lyrics.isLoaded, isTrue);
    final kept = lyrics.currentLines[1].copyWith(latin: 'two edited');
    container.read(bakhedLyricsEditorProvider(_bakhedId).notifier).updateLines([
      kept,
      const BakhedLyricLine(
        id: '',
        lineIndex: 0,
        startMs: 6000,
        endMs: 0,
        olChiki: '',
        latin: 'new line',
        meaning: '',
      ),
    ]);
    final notes = container.read(bakhedNotesEditorProvider(_bakhedId).notifier);
    notes.removeNote('n1');
    notes.addNote(
      const BakhedCulturalNote(
        noteId: '',
        title: 'Karam festival',
        body: 'Celebrated in Bhado.',
        source: '',
        isPublished: true,
      ),
    );

    final result = await container
        .read(bakhedEditorControllerProvider(_bakhedId).notifier)
        .save();

    expect(result, SaveResult.success);
    verify(() => cms.deleteRow('bakhed_lyrics', 'l1')).called(1);

    final created = verify(
      () => cms.upsertRow(
        'bakhed_lyrics',
        captureAny(),
        captureAny(),
        createOnly: true,
      ),
    ).captured;
    final newId = created[0] as String;
    final newPayload = created[1] as Map<String, dynamic>;
    expect(newId, isNotEmpty);
    expect(newPayload['bakhedId'], _bakhedId);
    expect(newPayload['latin'], 'new line');
    // Last line ends at the Bakhed duration.
    expect(newPayload['endMs'], 9000);

    final updated = verify(
      () => cms.upsertRow('bakhed_lyrics', 'l2', captureAny()),
    ).captured;
    final updatePayload = updated.single as Map<String, dynamic>;
    expect(updatePayload['latin'], 'two edited');
    expect(updatePayload['bakhedId'], _bakhedId);
    // endMs is re-derived from the next line's start.
    expect(updatePayload['endMs'], 6000);

    verify(() => cms.deleteRow('bakhed_cultural_notes', 'n1')).called(1);
    final note = verify(
      () => cms.upsertRow(
        'bakhed_cultural_notes',
        captureAny(),
        captureAny(),
        createOnly: true,
      ),
    ).captured;
    final notePayload = note[1] as Map<String, dynamic>;
    expect(notePayload['noteId'], note[0]);
    expect(notePayload['bakhedId'], _bakhedId);
    expect(notePayload['isPublished'], isTrue);

    verifyNever(
      () => cms.upsertRow(
        'bakhed_vocabulary',
        any(),
        any(),
        createOnly: any(named: 'createOnly'),
      ),
    );
    verify(() => repo.upsert(any())).called(1);
  });

  test('a failed child write aborts before the parent upsert', () async {
    when(
      () => cms.deleteRow('bakhed_lyrics', 'l1'),
    ).thenThrow(const CmsApiException('boom', statusCode: 500));
    container
        .read(bakhedLyricsEditorProvider(_bakhedId).notifier)
        .removeLine('l1', 0);

    final result = await container
        .read(bakhedEditorControllerProvider(_bakhedId).notifier)
        .save();

    expect(result, SaveResult.failure);
    verifyNever(() => repo.upsert(any()));
  });
}
