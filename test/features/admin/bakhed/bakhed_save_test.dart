import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart';
import 'package:itun/shared/models/content_models.dart';

import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/core/error/failures.dart';

// ── Mocks ──────────────────────────────────────────────────

class MockBakhedRepository extends Mock implements BakhedRepository {}

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockStorage extends Mock implements Storage {}

class FakeContentItem extends Fake implements ContentItem {}

class MockMediaUploader extends Mock implements MediaUploader {}

// ── Helpers ────────────────────────────────────────────────

/// Constructs a minimal ContentItem for rhymes with the given audio fields.
ContentItem _makeRhyme({
  String id = 'rhyme_test_123',
  String? audioUrl,
  String? audioFileId,
  int? durationMs,
  DateTime? updatedAt,
}) {
  return ContentItem(
    id: id,
    kind: ContentKind.rhyme,
    categoryId: 'sohrai_cat',
    title: 'Test Rhyme',
    titleOlChiki: 'ᱴᱮᱥᱴ',
    blocks: const [],
    isPublished: true,
    updatedAt: updatedAt ?? DateTime(2026),
    audioUrl: audioUrl,
    audioFileId: audioFileId,
    durationMs: durationMs,
    heroMedia: const ContentMedia(
      url: 'https://cdn.example.com/cover.png',
      fileId: 'cover1',
      kind: ContentMediaKind.image,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeContentItem());
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      const ReferenceCheck(databaseId: '', collectionId: '', fieldNames: []),
    );
  });

  // ────────────────────────────────────────────────────────────
  // Group 1: Serialization round-trip tests
  // ────────────────────────────────────────────────────────────
  group('ContentItem serialization round-trip', () {
    const rhymeId = 'rhyme_test_123';

    final legacyDocData = {
      '\$id': rhymeId,
      'titleLatin': 'Legacy Rhyme Title',
      'titleOlChiki': 'ᱞᱮᱜᱮᱥᱤ ᱨᱟᱭᱤᱢ',
      'thumbnailUrl': 'https://cdn.example.com/cover.png',
      'categoryId': 'sohrai_cat',
      'blocks':
          '[{"id":"b1","order":0,"type":"audio","media":{"url":"https://cdn.example.com/audio.mp3","fileId":"a1","kind":"audio"}}]',
      'is_published': true,
      'isPremium': false,
    };

    final modernDocData = {
      '\$id': rhymeId,
      'titleLatin': 'Modern Rhyme Title',
      'titleOlChiki': 'ᱢᱚᱰᱟᱨᱱ ᱨᱟᱭᱤᱢ',
      'thumbnailUrl': 'https://cdn.example.com/cover.png',
      'audioUrl': 'https://cdn.example.com/audio.mp3',
      'audioFileId': 'a1',
      'durationMs': 120000,
      'categoryId': 'sohrai_cat',
      'blocks': '[]',
      'is_published': true,
      'isPremium': false,
    };

    test('Legacy audio block derives effectiveAudioUrl', () {
      final item = ContentItem.fromJson(
        legacyDocData,
        rhymeId,
        ContentKind.rhyme,
      );
      expect(item.audioUrl, isNull);
      expect(item.effectiveAudioUrl, 'https://cdn.example.com/audio.mp3');
      expect(item.heroMedia?.url, 'https://cdn.example.com/cover.png');
      expect(item.heroMedia?.kind, ContentMediaKind.image);
    });

    test('Modern top-level audioUrl flows through', () {
      final item = ContentItem.fromJson(
        modernDocData,
        rhymeId,
        ContentKind.rhyme,
      );
      expect(item.audioUrl, 'https://cdn.example.com/audio.mp3');
      expect(item.effectiveAudioUrl, 'https://cdn.example.com/audio.mp3');
    });

    test(
      'toAppwrite() for rhyme includes audio fields and strips audio blocks',
      () {
        final item = ContentItem.fromJson(
          modernDocData,
          rhymeId,
          ContentKind.rhyme,
        );
        final payload = item.toAppwrite();

        expect(payload['audioUrl'], 'https://cdn.example.com/audio.mp3');
        expect(payload['audioFileId'], 'a1');
        expect(payload['durationMs'], 120000);
        expect(payload['thumbnailUrl'], 'https://cdn.example.com/cover.png');
        expect(payload['blocks'], '[]');
      },
    );

    test(
      'toAppwrite() for new rhyme with category but empty categoryId writes category and omits categoryId',
      () {
        final item = ContentItem(
          id: 'new_rhyme_1',
          kind: ContentKind.rhyme,
          categoryId: '',
          category: 'Baha',
          title: 'Title',
          blocks: const [],
          updatedAt: DateTime(2026),
        );
        final payload = item.toAppwrite();

        expect(payload['category'], 'Baha');
        expect(payload.containsKey('categoryId'), isFalse);
      },
    );

    test(
      'toAppwrite() for existing rhyme with both category and categoryId writes both fields',
      () {
        final item = ContentItem(
          id: 'existing_rhyme_1',
          kind: ContentKind.rhyme,
          categoryId: 'cat_sohrai',
          category: 'Sohrai',
          title: 'Title',
          blocks: const [],
          updatedAt: DateTime(2026),
        );
        final payload = item.toAppwrite();

        expect(payload['category'], 'Sohrai');
        expect(payload['categoryId'], 'cat_sohrai');
      },
    );
  });

  // ────────────────────────────────────────────────────────────
  // Group 2: Repository upsert payload verification
  // ────────────────────────────────────────────────────────────
  group('BakhedRepository.upsert payload', () {
    late MockAppwriteDbService mockDbService;
    late MockNetworkInfo mockNetworkInfo;
    late BakhedRepository repository;

    setUp(() {
      mockDbService = MockAppwriteDbService();
      mockNetworkInfo = MockNetworkInfo();
      repository = BakhedRepository(
        dbService: mockDbService,
        storage: MockStorage(),
        networkInfo: mockNetworkInfo,
      );
    });

    test('upsert sends audioUrl in the payload to Appwrite', () async {
      final item = _makeRhyme(
        audioUrl: 'https://cdn.example.com/audio.mp3',
        audioFileId: 'file_abc',
        durationMs: 180000,
      );

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      Map<String, dynamic>? capturedPayload;
      when(() => mockDbService.updateDocument(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        capturedPayload =
            invocation.positionalArguments[2] as Map<String, dynamic>;
      });

      final result = await repository.upsert(item);

      expect(result.isRight(), isTrue);
      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['audioUrl'], 'https://cdn.example.com/audio.mp3');
      expect(capturedPayload!['audioFileId'], 'file_abc');
      expect(capturedPayload!['durationMs'], 180000);
    });

    test('upsert sends null audioUrl when audio has not been set', () async {
      final item = _makeRhyme();

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      Map<String, dynamic>? capturedPayload;
      when(() => mockDbService.updateDocument(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        capturedPayload =
            invocation.positionalArguments[2] as Map<String, dynamic>;
      });

      final result = await repository.upsert(item);

      expect(result.isRight(), isTrue);
      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['audioUrl'], isNull);
      expect(capturedPayload!['audioFileId'], isNull);
    });
  });

  // ────────────────────────────────────────────────────────────
  // Group 3: Audio upload / save race condition
  //
  // PHASE A — Prove the bug existed (regression test)
  // PHASE B — Prove the fix works (inflight guard)
  // ────────────────────────────────────────────────────────────
  group('Audio upload/save race condition', () {
    late MockBakhedRepository mockRepository;
    late MockAppwriteDbService mockDbService;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockBakhedRepository();
      mockDbService = MockAppwriteDbService();
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper: creates a ProviderContainer with mocked providers
    /// and waits for the editor notifier to finish loading.
    Future<ProviderContainer> setupContainer({
      required ContentItem initialRhyme,
    }) async {
      when(
        () => mockRepository.get(initialRhyme.id),
      ).thenAnswer((_) async => right(initialRhyme));

      when(
        () => mockRepository.upsert(any()),
      ).thenAnswer((_) async => right(unit));

      final c = ProviderContainer(
        overrides: [
          bakhedRepositoryProvider.overrideWithValue(mockRepository),
          appwriteDbServiceProvider.overrideWithValue(mockDbService),
          mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
        ],
      );

      // Trigger load() in the notifier constructor
      c.read(bakhedEditorControllerProvider(initialRhyme.id).notifier);

      // Wait for the async load() to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify it loaded
      final state = c.read(bakhedEditorControllerProvider(initialRhyme.id));
      expect(state.item, isA<AsyncData<ContentItem>>());

      return c;
    }

    // ── PHASE A: Regression proof ──────────────────────────
    //
    // This test proves that the OLD code path (calling updateAudio
    // directly after an async upload, with no inflight guard) would
    // persist null audioUrl when save() races ahead of the callback.
    //
    // The scenario:
    //   1. Rhyme loads with audioUrl == null
    //   2. Upload starts (slow, 200ms) → updateAudio hasn't been called
    //   3. Admin hits save → save() reads state.item.value.audioUrl == null
    //   4. Appwrite receives null audioUrl → AUDIO LOST
    //
    test('REGRESSION: save() without upload guard persists null audioUrl '
        '(proves the historical bug)', () async {
      final rhyme = _makeRhyme();

      container = await setupContainer(initialRhyme: rhyme);

      final notifier = container.read(
        bakhedEditorControllerProvider(rhyme.id).notifier,
      );

      // Simulate the OLD flow: upload starts but updateAudio hasn't
      // been called yet. The admin hits save immediately.
      // With the OLD code, save() would happily persist null.
      // With the NEW code, save() would block (tested in Phase B).
      //
      // To prove the historical bug, we bypass the inflight guard by
      // calling save() WITHOUT going through uploadAndSetAudio().
      // This simulates what the old MediaPickerField.onChanged path did.
      notifier.markDirty();
      final result = await notifier.save();

      expect(result, SaveResult.success);

      final captured = verify(
        () => mockRepository.upsert(captureAny()),
      ).captured;
      expect(captured, isNotEmpty);

      final savedItem = captured.last as ContentItem;

      // THE BUG: audioUrl is null because updateAudio() hasn't been
      // called yet — the upload was still in-flight when save() ran.
      expect(
        savedItem.audioUrl,
        isNull,
        reason:
            'Historical proof: without the inflight guard, save() persists '
            'null audioUrl because the upload callback (updateAudio) has not '
            'fired yet.',
      );
    });

    // ── PHASE B: Fix proof ─────────────────────────────────
    //
    // With the inflight counter, save() now returns
    // SaveResult.uploadInProgress if an upload is running.
    //
    test(
      'FIX: save() returns uploadInProgress while upload is running',
      () async {
        final rhyme = _makeRhyme();

        container = await setupContainer(initialRhyme: rhyme);

        final notifier = container.read(
          bakhedEditorControllerProvider(rhyme.id).notifier,
        );

        // Simulate: MediaPickerField triggers upload
        notifier.setUploadInProgress(true);

        // Immediately try to save — should be blocked
        notifier.markDirty();
        final result = await notifier.save();

        // The guard fires: save() refuses to persist stale data
        expect(
          result,
          SaveResult.uploadInProgress,
          reason:
              'save() must return uploadInProgress when an audio upload '
              'is still in-flight, preventing null audioUrl from being persisted.',
        );

        // upsert should NOT have been called
        verifyNever(() => mockRepository.upsert(any()));

        // Simulate upload completing and updating audio
        notifier.updateAudio(
          'https://cdn.example.com/uploaded.mp3',
          'uploaded_file_id',
          60000,
        );
        notifier.setUploadInProgress(false);

        // Now save should succeed with the correct audioUrl
        final result2 = await notifier.save();
        expect(result2, SaveResult.success);

        final captured = verify(
          () => mockRepository.upsert(captureAny()),
        ).captured;
        final savedItem = captured.last as ContentItem;

        expect(
          savedItem.audioUrl,
          'https://cdn.example.com/uploaded.mp3',
          reason:
              'After upload completes, save() persists the correct audioUrl.',
        );
        expect(savedItem.audioFileId, 'uploaded_file_id');
      },
    );

    test('FIX: updateAudio() then save() correctly persists audioUrl '
        '(non-race happy path)', () async {
      final rhyme = _makeRhyme();

      container = await setupContainer(initialRhyme: rhyme);

      final notifier = container.read(
        bakhedEditorControllerProvider(rhyme.id).notifier,
      );

      // Upload completed, callback fires
      notifier.updateAudio(
        'https://cdn.example.com/uploaded.mp3',
        'uploaded_file_id',
        60000,
      );

      final result = await notifier.save();
      expect(result, SaveResult.success);

      final captured = verify(
        () => mockRepository.upsert(captureAny()),
      ).captured;
      final savedItem = captured.last as ContentItem;

      expect(savedItem.audioUrl, 'https://cdn.example.com/uploaded.mp3');
      expect(savedItem.audioFileId, 'uploaded_file_id');
      expect(savedItem.durationMs, 60000);
    });
  });

  // ────────────────────────────────────────────────────────────
  // Group 4: Optimistic concurrency & TOCTOU fix
  // ────────────────────────────────────────────────────────────
  group('Optimistic concurrency', () {
    late MockBakhedRepository mockRepository;
    late MockAppwriteDbService mockDbService;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockBakhedRepository();
      mockDbService = MockAppwriteDbService();
    });

    tearDown(() {
      container.dispose();
    });

    test('Concurrency conflict detected at initial check '
        '(server has newer version)', () async {
      final clientRhyme = _makeRhyme(
        updatedAt: DateTime(2026, 1, 1, 12),
        audioUrl: 'https://cdn.example.com/audio.mp3',
      );

      final serverRhyme = _makeRhyme(
        updatedAt: DateTime(2026, 1, 1, 12, 5),
        audioUrl: 'https://cdn.example.com/different-audio.mp3',
      );

      var callCount = 0;
      when(() => mockRepository.get(clientRhyme.id)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return right(clientRhyme); // load()
        return right(serverRhyme); // concurrency check
      });

      when(
        () => mockRepository.upsert(any()),
      ).thenAnswer((_) async => right(unit));

      container = ProviderContainer(
        overrides: [
          bakhedRepositoryProvider.overrideWithValue(mockRepository),
          appwriteDbServiceProvider.overrideWithValue(mockDbService),
          mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
        ],
      );

      container.read(bakhedEditorControllerProvider(clientRhyme.id).notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        bakhedEditorControllerProvider(clientRhyme.id).notifier,
      );
      notifier.markDirty();

      final result = await notifier.save();

      expect(result, SaveResult.concurrencyConflict);
      verifyNever(() => mockRepository.upsert(any()));
    });

    test('TOCTOU: save aborts if server doc changes between initial check '
        'and parent upsert (double-check catches late conflict)', () async {
      final clientRhyme = _makeRhyme(
        updatedAt: DateTime(2026, 1, 1, 12),
        audioUrl: 'https://cdn.example.com/audio.mp3',
      );

      // First check passes (same timestamp), but between subcollection
      // saves and the parent upsert, another admin saves → newer timestamp.
      final lateServerRhyme = _makeRhyme(
        updatedAt: DateTime(2026, 1, 1, 12, 0, 1), // 1 second later
        audioUrl: 'https://cdn.example.com/other-admin-audio.mp3',
      );

      var getCallCount = 0;
      when(() => mockRepository.get(clientRhyme.id)).thenAnswer((_) async {
        getCallCount++;
        if (getCallCount <= 2) {
          // Call 1 = load(), Call 2 = first concurrency check (passes)
          return right(clientRhyme);
        }
        // Call 3 = TOCTOU re-check right before parent upsert (FAILS)
        return right(lateServerRhyme);
      });

      when(
        () => mockRepository.upsert(any()),
      ).thenAnswer((_) async => right(unit));

      container = ProviderContainer(
        overrides: [
          bakhedRepositoryProvider.overrideWithValue(mockRepository),
          appwriteDbServiceProvider.overrideWithValue(mockDbService),
          mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
        ],
      );

      container.read(bakhedEditorControllerProvider(clientRhyme.id).notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        bakhedEditorControllerProvider(clientRhyme.id).notifier,
      );
      notifier.markDirty();

      final result = await notifier.save();

      // The TOCTOU double-check catches the late conflict
      expect(
        result,
        SaveResult.concurrencyConflict,
        reason:
            'The second concurrency check (right before parent upsert) '
            'catches a server modification that happened during '
            'subcollection saves.',
      );

      // upsert() on parent rhymes doc was NEVER called
      verifyNever(() => mockRepository.upsert(any()));

      // repository.get() was called 3 times:
      // 1: load(), 2: initial check, 3: TOCTOU re-check
      verify(() => mockRepository.get(clientRhyme.id)).called(3);
    });
  });

  // ────────────────────────────────────────────────────────────
  // Group 5: Legacy tags coercion regression tests
  // ────────────────────────────────────────────────────────────
  group('Legacy tags coercion regression tests', () {
    test(
      'REGRESSION: tags array is coerced to ≤50 char string for legacy schema',
      () {
        final item = ContentItem(
          id: 'r1',
          kind: ContentKind.rhyme,
          categoryId: 'cat1',
          title: 'x',
          titleOlChiki: 'x',
          tags: const ['culture', 'song', 'sohrai', 'traditional', 'folk'],
          blocks: const [],
          isPublished: true,
          updatedAt: DateTime(2026),
        );
        final payload = item.toAppwrite();
        expect(payload['tags'], isA<String>());
        expect((payload['tags'] as String).length, lessThanOrEqualTo(50));
      },
    );

    test(
      'REGRESSION: empty tags list emits no tags key (not empty string)',
      () {
        final item = ContentItem(
          id: 'r1',
          kind: ContentKind.rhyme,
          categoryId: 'cat1',
          title: 'x',
          titleOlChiki: 'x',
          blocks: const [],
          isPublished: true,
          updatedAt: DateTime(2026),
        );
        expect(item.toAppwrite().containsKey('tags'), isFalse);
      },
    );

    test('REGRESSION: round-trip preserves tag list via comma split', () {
      final original = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        categoryId: 'cat1',
        title: 'x',
        titleOlChiki: 'x',
        tags: const ['culture', 'song'],
        blocks: const [],
        isPublished: true,
        updatedAt: DateTime(2026),
      );
      final json = original.toAppwrite();
      final restored = ContentItem.fromJson({
        ...json,
        '\$id': 'r1',
        'kind': 'rhyme',
      });
      expect(restored.tags, equals(['culture', 'song']));
    });

    test('REGRESSION: long tag list under 50 chars total still fits', () {
      final item = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        categoryId: 'cat1',
        title: 'x',
        titleOlChiki: 'x',
        tags: const ['a', 'b', 'c'],
        blocks: const [],
        isPublished: true,
        updatedAt: DateTime(2026),
      );
      final payload = item.toAppwrite();
      expect(payload['tags'], equals('a,b,c'));
    });

    test('REGRESSION: tag values containing commas do not break round-trip', () {
      // Phase B tagsList preserves commas cleanly
      final item = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        categoryId: 'cat1',
        title: 'x',
        titleOlChiki: 'x',
        tags: const ['hello,world'],
        blocks: const [],
        isPublished: true,
        updatedAt: DateTime(2026),
      );
      final json = item.toAppwrite();
      final restored = ContentItem.fromJson({
        ...json,
        '\$id': 'r1',
        'kind': 'rhyme',
      });
      // Documents new behavior — restored will preserve the comma as ['hello,world']
      expect(restored.tags, equals(['hello,world']));
    });
  });

  // ────────────────────────────────────────────────────────────
  // Group 6: Deferred storage deletions (Pattern A)
  // ────────────────────────────────────────────────────────────
  group('Deferred storage deletions (Pattern A)', () {
    late MockBakhedRepository mockRepository;
    late MockAppwriteDbService mockDbService;
    late MockMediaUploader mockMediaUploader;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockBakhedRepository();
      mockDbService = MockAppwriteDbService();
      mockMediaUploader = MockMediaUploader();
    });

    tearDown(() {
      container.dispose();
    });

    Future<ProviderContainer> setupContainerWithMedia({
      required ContentItem initialRhyme,
    }) async {
      when(
        () => mockRepository.get(initialRhyme.id),
      ).thenAnswer((_) async => right(initialRhyme));
      when(
        () => mockRepository.upsert(any()),
      ).thenAnswer((_) async => right(unit));

      final c = ProviderContainer(
        overrides: [
          bakhedRepositoryProvider.overrideWithValue(mockRepository),
          appwriteDbServiceProvider.overrideWithValue(mockDbService),
          mediaUploaderProvider.overrideWithValue(mockMediaUploader),
        ],
      );

      c.read(bakhedEditorControllerProvider(initialRhyme.id).notifier);
      await Future.delayed(const Duration(milliseconds: 50));
      return c;
    }

    test('1. markForDeletion appends to state and sets isDirty', () async {
      final rhyme = _makeRhyme();
      container = await setupContainerWithMedia(initialRhyme: rhyme);

      final notifier = container.read(
        bakhedEditorControllerProvider(rhyme.id).notifier,
      );

      expect(
        container
            .read(bakhedEditorControllerProvider(rhyme.id))
            .pendingDeletions,
        isEmpty,
      );
      expect(
        container.read(bakhedEditorControllerProvider(rhyme.id)).isDirty,
        isFalse,
      );

      notifier.markForDeletion('file_to_delete');

      expect(
        container
            .read(bakhedEditorControllerProvider(rhyme.id))
            .pendingDeletions,
        equals(['file_to_delete']),
      );
      expect(
        container.read(bakhedEditorControllerProvider(rhyme.id)).isDirty,
        isTrue,
      );
    });

    test(
      '2. save() executes pending deletions after successful update',
      () async {
        final rhyme = _makeRhyme(
          audioFileId: 'old_audio',
          audioUrl: 'https://example.com/old_audio.mp3',
        );
        container = await setupContainerWithMedia(initialRhyme: rhyme);

        final notifier = container.read(
          bakhedEditorControllerProvider(rhyme.id).notifier,
        );

        when(
          () => mockMediaUploader.deleteIfUnreferenced(
            fileId: 'old_audio',
            checks: any(named: 'checks'),
          ),
        ).thenAnswer((_) async => right(unit));

        notifier.markForDeletion('old_audio');
        notifier.updateAudio(
          'https://example.com/new_audio.mp3',
          'new_audio',
          50000,
        );

        final result = await notifier.save();
        expect(result, SaveResult.success);

        // Verify repository updated doc
        verify(() => mockRepository.upsert(any())).called(1);

        // Wait a moment for background microtask to run
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify media uploader delete called
        verify(
          () => mockMediaUploader.deleteIfUnreferenced(
            fileId: 'old_audio',
            checks: any(named: 'checks'),
          ),
        ).called(1);
        expect(
          container
              .read(bakhedEditorControllerProvider(rhyme.id))
              .pendingDeletions,
          isEmpty,
        );
      },
    );

    test(
      '3. save() does NOT execute deletions if document update fails',
      () async {
        final rhyme = _makeRhyme(
          audioFileId: 'old_audio',
          audioUrl: 'https://example.com/old_audio.mp3',
        );
        container = await setupContainerWithMedia(initialRhyme: rhyme);

        final notifier = container.read(
          bakhedEditorControllerProvider(rhyme.id).notifier,
        );

        // Make upsert fail
        when(() => mockRepository.upsert(any())).thenAnswer(
          (_) async => left(const ServerFailure(message: 'Upsert failed')),
        );

        notifier.markForDeletion('old_audio');

        final result = await notifier.save();
        expect(result, SaveResult.failure);

        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify media uploader delete never called
        verifyNever(
          () => mockMediaUploader.deleteIfUnreferenced(
            fileId: any(named: 'fileId'),
            checks: any(named: 'checks'),
          ),
        );
        // Pending deletions remain in state
        expect(
          container
              .read(bakhedEditorControllerProvider(rhyme.id))
              .pendingDeletions,
          equals(['old_audio']),
        );
      },
    );

    test(
      '4. Deletion errors during save are logged but do not fail the save',
      () async {
        final rhyme = _makeRhyme(
          audioFileId: 'old_audio',
          audioUrl: 'https://example.com/old_audio.mp3',
        );
        container = await setupContainerWithMedia(initialRhyme: rhyme);

        final notifier = container.read(
          bakhedEditorControllerProvider(rhyme.id).notifier,
        );

        // Make deletion fail
        when(
          () => mockMediaUploader.deleteIfUnreferenced(
            fileId: 'old_audio',
            checks: any(named: 'checks'),
          ),
        ).thenAnswer(
          (_) async =>
              left(const ServerFailure(message: 'Appwrite deletion failed')),
        );

        notifier.markForDeletion('old_audio');
        notifier.updateAudio(
          'https://example.com/new_audio.mp3',
          'new_audio',
          50000,
        );

        final result = await notifier.save();
        expect(result, SaveResult.success);

        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify media uploader delete was still called, and save succeeded
        verify(
          () => mockMediaUploader.deleteIfUnreferenced(
            fileId: 'old_audio',
            checks: any(named: 'checks'),
          ),
        ).called(1);
        expect(
          container
              .read(bakhedEditorControllerProvider(rhyme.id))
              .pendingDeletions,
          isEmpty,
        );
      },
    );

    test(
      '5. Sequence: upload A -> remove A -> upload B -> save -> A is deleted, B referenced',
      () async {
        final rhyme = _makeRhyme();
        container = await setupContainerWithMedia(initialRhyme: rhyme);

        final notifier = container.read(
          bakhedEditorControllerProvider(rhyme.id).notifier,
        );

        when(
          () => mockMediaUploader.deleteIfUnreferenced(
            fileId: 'file_a',
            checks: any(named: 'checks'),
          ),
        ).thenAnswer((_) async => right(unit));

        // 1. Upload A
        notifier.updateAudio('https://example.com/a.mp3', 'file_a', 10000);

        // 2. Remove A (this calls markForDeletion('file_a') and sets audio to null in UI/controller)
        notifier.markForDeletion('file_a');
        notifier.updateAudio(null, null, null);

        // 3. Upload B
        notifier.updateAudio('https://example.com/b.mp3', 'file_b', 20000);

        // 4. Save
        final result = await notifier.save();
        expect(result, SaveResult.success);

        // Wait a moment for background microtask
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify file A was deleted
        verify(
          () => mockMediaUploader.deleteIfUnreferenced(
            fileId: 'file_a',
            checks: any(named: 'checks'),
          ),
        ).called(1);
        // Verify file B was NOT deleted
        verifyNever(
          () => mockMediaUploader.deleteIfUnreferenced(
            fileId: 'file_b',
            checks: any(named: 'checks'),
          ),
        );

        // Verify database updated with B
        final captured = verify(
          () => mockRepository.upsert(captureAny()),
        ).captured;
        final savedItem = captured.last as ContentItem;
        expect(savedItem.audioFileId, 'file_b');
        expect(savedItem.audioUrl, 'https://example.com/b.mp3');
        expect(savedItem.durationMs, 20000);
        expect(
          container
              .read(bakhedEditorControllerProvider(rhyme.id))
              .pendingDeletions,
          isEmpty,
        );
      },
    );
  });

  // ────────────────────────────────────────────────────────────
  // Group 4: New Rhyme 404 Load & isNewDraft tests
  // ────────────────────────────────────────────────────────────
  group('New Rhyme 404 Load & isNewDraft', () {
    late MockBakhedRepository mockRepository;
    late MockAppwriteDbService mockDbService;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockBakhedRepository();
      mockDbService = MockAppwriteDbService();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'load() with 404 failure initializes empty ContentItem draft and isNewDraft: true',
      () async {
        const draftId = 'new_rhyme_draft_123';

        when(() => mockRepository.get(draftId)).thenAnswer(
          (_) async => left(
            const ServerFailure(message: 'document_not_found', code: 404),
          ),
        );

        container = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        container.read(bakhedEditorControllerProvider(draftId).notifier);

        // Wait for load()
        await Future.delayed(const Duration(milliseconds: 50));

        final state = container.read(bakhedEditorControllerProvider(draftId));
        expect(state.item, isA<AsyncData<ContentItem>>());
        expect(state.item.value, isNotNull);
        expect(state.item.value!.id, draftId);
        expect(state.item.value!.title, isEmpty);
        expect(state.isNewDraft, isTrue);
      },
    );

    test(
      'load() with non-404 failure bubbles up error and sets isNewDraft: false',
      () async {
        const draftId = 'broken_rhyme_123';

        when(() => mockRepository.get(draftId)).thenAnswer(
          (_) async => left(
            const ServerFailure(message: 'Fatal connection error', code: 500),
          ),
        );

        container = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        container.read(bakhedEditorControllerProvider(draftId).notifier);

        // Wait for load()
        await Future.delayed(const Duration(milliseconds: 50));

        final state = container.read(bakhedEditorControllerProvider(draftId));
        expect(state.item, isA<AsyncError>());
        expect(state.isNewDraft, isFalse);
      },
    );

    test('load() with success loads data and sets isNewDraft: false', () async {
      final rhyme = _makeRhyme();

      when(
        () => mockRepository.get(rhyme.id),
      ).thenAnswer((_) async => right(rhyme));

      container = ProviderContainer(
        overrides: [
          bakhedRepositoryProvider.overrideWithValue(mockRepository),
          appwriteDbServiceProvider.overrideWithValue(mockDbService),
          mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
        ],
      );

      container.read(bakhedEditorControllerProvider(rhyme.id).notifier);

      // Wait for load()
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(bakhedEditorControllerProvider(rhyme.id));
      expect(state.item, isA<AsyncData<ContentItem>>());
      expect(state.item.value!.title, 'Test Rhyme');
      expect(state.isNewDraft, isFalse);
    });

    test(
      'save() after successful draft load clears isNewDraft back to false',
      () async {
        const draftId = 'new_rhyme_draft_123';

        when(() => mockRepository.get(draftId)).thenAnswer(
          (_) async => left(
            const ServerFailure(message: 'document_not_found', code: 404),
          ),
        );
        when(
          () => mockRepository.upsert(any()),
        ).thenAnswer((_) async => right(unit));

        container = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        final notifier = container.read(
          bakhedEditorControllerProvider(draftId).notifier,
        );

        // Wait for load()
        await Future.delayed(const Duration(milliseconds: 50));

        var state = container.read(bakhedEditorControllerProvider(draftId));
        expect(state.isNewDraft, isTrue);

        notifier.markDirty();
        final saveRes = await notifier.save();
        expect(saveRes, SaveResult.success);

        state = container.read(bakhedEditorControllerProvider(draftId));
        expect(state.isNewDraft, isFalse);
      },
    );
  });

  group('BakhedEditorNotifier string-based category updates', () {
    late MockBakhedRepository mockRepository;
    late MockAppwriteDbService mockDbService;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockBakhedRepository();
      mockDbService = MockAppwriteDbService();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'updateCategory("Baha") updates state.item.value.category and sets isDirty: true',
      () async {
        final rhyme = _makeRhyme(audioUrl: 'https://example.com/audio.mp3');

        when(
          () => mockRepository.get(rhyme.id),
        ).thenAnswer((_) async => right(rhyme));

        container = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        final notifier = container.read(
          bakhedEditorControllerProvider(rhyme.id).notifier,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        var state = container.read(bakhedEditorControllerProvider(rhyme.id));
        expect(state.item.value!.category, isNull);
        expect(state.isDirty, isFalse);

        notifier.updateCategory('Baha');

        state = container.read(bakhedEditorControllerProvider(rhyme.id));
        expect(state.item.value!.category, 'Baha');
        expect(state.isDirty, isTrue);
      },
    );

    test(
      'updateCategory(null) clears the category and sets isDirty: true',
      () async {
        final rhyme = ContentItem(
          id: 'rhyme_test_123',
          kind: ContentKind.rhyme,
          categoryId: 'sohrai_cat',
          category: 'Sohrai',
          title: 'Test Rhyme',
          blocks: const [],
          updatedAt: DateTime(2026),
        );

        when(
          () => mockRepository.get(rhyme.id),
        ).thenAnswer((_) async => right(rhyme));

        container = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        final notifier = container.read(
          bakhedEditorControllerProvider(rhyme.id).notifier,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        var state = container.read(bakhedEditorControllerProvider(rhyme.id));
        expect(state.item.value!.category, 'Sohrai');
        expect(state.isDirty, isFalse);

        notifier.updateCategory(null);

        state = container.read(bakhedEditorControllerProvider(rhyme.id));
        expect(state.item.value!.category, isNull);
        expect(state.isDirty, isTrue);
      },
    );

    test(
      'Loading a rhyme with category and categoryId sets category in notifier state',
      () async {
        final rhyme = ContentItem(
          id: 'rhyme_test_123',
          kind: ContentKind.rhyme,
          categoryId: 'cat_sohrai',
          category: 'Sohrai',
          title: 'Test Rhyme',
          blocks: const [],
          updatedAt: DateTime(2026),
        );

        when(
          () => mockRepository.get(rhyme.id),
        ).thenAnswer((_) async => right(rhyme));

        container = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        container.read(bakhedEditorControllerProvider(rhyme.id).notifier);
        await Future.delayed(const Duration(milliseconds: 50));

        final state = container.read(bakhedEditorControllerProvider(rhyme.id));
        expect(state.item.value!.categoryId, 'cat_sohrai');
        expect(state.item.value!.category, 'Sohrai');
      },
    );
  });

  group('BakhedEditorNotifier cover media switching tests', () {
    late MockBakhedRepository mockRepository;
    late MockAppwriteDbService mockDbService;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockBakhedRepository();
      mockDbService = MockAppwriteDbService();
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> setupEditor(ContentItem rhyme) async {
      when(
        () => mockRepository.get(rhyme.id),
      ).thenAnswer((_) async => right(rhyme));
      container = ProviderContainer(
        overrides: [
          bakhedRepositoryProvider.overrideWithValue(mockRepository),
          appwriteDbServiceProvider.overrideWithValue(mockDbService),
          mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
        ],
      );
      container.read(bakhedEditorControllerProvider(rhyme.id).notifier);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    test('updateCoverMedia with image sets media, type, and dirty', () async {
      final rhyme = _makeRhyme(); // starts with image cover1
      await setupEditor(rhyme);

      final notifier = container.read(
        bakhedEditorControllerProvider(rhyme.id).notifier,
      );
      const newMedia = ContentMedia(
        url: 'https://cdn.example.com/new_image.png',
        fileId: 'img456',
        kind: ContentMediaKind.image,
      );

      notifier.updateCoverMedia(newMedia, 'image');

      final state = container.read(bakhedEditorControllerProvider(rhyme.id));
      expect(state.item.value!.heroMedia, newMedia);
      expect(state.item.value!.coverMediaType, 'image');
      expect(state.isDirty, isTrue);
      // Changing to a new image queues the old image 'cover1' for deletion
      expect(state.pendingDeletions, contains('cover1'));
    });

    test('updateCoverMedia with video sets media, type, and dirty', () async {
      final rhyme = _makeRhyme(); // starts with image cover1
      await setupEditor(rhyme);

      final notifier = container.read(
        bakhedEditorControllerProvider(rhyme.id).notifier,
      );
      const videoMedia = ContentMedia(
        url: 'https://cdn.example.com/cover.mp4',
        fileId: 'vid789',
        kind: ContentMediaKind.video,
      );

      notifier.updateCoverMedia(videoMedia, 'video');

      final state = container.read(bakhedEditorControllerProvider(rhyme.id));
      expect(state.item.value!.heroMedia, videoMedia);
      expect(state.item.value!.coverMediaType, 'video');
      expect(state.isDirty, isTrue);
      // Switching from image to video queues the old image 'cover1' for deletion
      expect(state.pendingDeletions, contains('cover1'));
    });

    test(
      'clearCover clears cover media state and queues old cover file for deletion',
      () async {
        final rhyme = _makeRhyme(); // starts with image cover1
        await setupEditor(rhyme);

        final notifier = container.read(
          bakhedEditorControllerProvider(rhyme.id).notifier,
        );

        notifier.clearCover();

        final state = container.read(bakhedEditorControllerProvider(rhyme.id));
        expect(state.item.value!.heroMedia, isNull);
        expect(state.item.value!.coverMediaType, isNull);
        expect(state.isDirty, isTrue);
        expect(state.pendingDeletions, contains('cover1'));
      },
    );
  });

  group('effectiveAudioUrl and LetterModel block audio parsing', () {
    test('extracts audioUrl from GlyphBlock in ContentItem', () {
      const block = GlyphBlock(
        id: 'b1',
        order: 0,
        olChiki: 'ᱚ',
        latin: 'o',
        audioUrl: 'https://cdn.example.com/glyph-audio.mp3',
      );
      final item = ContentItem(
        id: 'o_letter',
        kind: ContentKind.letter,
        categoryId: 'cat_letters',
        title: 'O',
        blocks: const [block],
        updatedAt: DateTime(2026),
      );
      expect(item.effectiveAudioUrl, 'https://cdn.example.com/glyph-audio.mp3');
    });

    test(
      'extracts audioUrl from GlyphBlock in ContentItem when top-level audioUrl is empty string',
      () {
        const block = GlyphBlock(
          id: 'b1',
          order: 0,
          olChiki: 'ᱚ',
          latin: 'o',
          audioUrl: 'https://cdn.example.com/glyph-audio.mp3',
        );
        final item = ContentItem(
          id: 'o_letter',
          kind: ContentKind.letter,
          categoryId: 'cat_letters',
          title: 'O',
          audioUrl: '',
          blocks: const [block],
          updatedAt: DateTime(2026),
        );
        expect(
          item.effectiveAudioUrl,
          'https://cdn.example.com/glyph-audio.mp3',
        );
      },
    );

    test('LetterModel.fromJson parses blocks fallback for audioUrl', () {
      final json = {
        'id': 'o_letter',
        'charOlChiki': 'ᱚ',
        'transliterationLatin': 'O',
        'blocks':
            '[{"id":"b1","order":0,"type":"glyph","olChiki":"ᱚ","latin":"o","audioUrl":"https://cdn.example.com/glyph-audio.mp3"}]',
        'order': 0,
        'isActive': true,
      };
      final letter = LetterModel.fromJson(json);
      expect(letter.audioUrl, 'https://cdn.example.com/glyph-audio.mp3');
    });
  });
}
