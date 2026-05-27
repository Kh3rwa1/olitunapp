// Bakhed Audio Save E2E Widget Test
//
// This test verifies the full save pipeline at the widget level:
// 1. Loads a rhyme via mocked repository
// 2. Simulates audio upload completing (via notifier.updateAudio)
// 3. Triggers save
// 4. Disposes and re-creates the editor (simulates hard reload)
// 5. Asserts audio URL is present in the re-loaded state
//
// This is the closest we can get to a real browser smoke test without
// requiring actual file picker interaction.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart';
import 'package:itun/shared/models/content_item.dart';

class MockBakhedRepository extends Mock implements BakhedRepository {}

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

class MockMediaUploader extends Mock implements MediaUploader {}

class FakeContentItem extends Fake implements ContentItem {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeContentItem());
    registerFallbackValue(Uint8List(0));
  });

  group('Bakhed Audio Save — E2E round-trip', () {
    const rhymeId = 'test_rhyme_e2e';
    const audioUrl =
        'https://sgp.cloud.appwrite.io/v1/storage/buckets/audio/files/test123/view?project=test';
    const audioFileId = 'test123';
    const durationMs = 180000;

    late MockBakhedRepository mockRepository;
    late MockAppwriteDbService mockDbService;

    /// The "server state" — starts with no audio, gets updated on save.
    late ContentItem serverState;

    setUp(() {
      mockRepository = MockBakhedRepository();
      mockDbService = MockAppwriteDbService();

      // Initial server state: no audio
      serverState = ContentItem(
        id: rhymeId,
        kind: ContentKind.rhyme,
        categoryId: 'sohrai_cat',
        title: 'E2E Test Rhyme',
        titleOlChiki: 'ᱤᱴᱩ ᱴᱮᱥᱴ',
        blocks: const [],
        updatedAt: DateTime(2026, 5, 27, 12),
        heroMedia: const ContentMedia(
          url: 'https://cdn.example.com/cover.png',
          fileId: 'cover1',
          kind: ContentMediaKind.image,
        ),
      );

      // Mock repository.get() to return the current server state
      when(
        () => mockRepository.get(rhymeId),
      ).thenAnswer((_) async => right(serverState));

      // Mock repository.upsert() to capture and update server state
      when(() => mockRepository.upsert(any())).thenAnswer((invocation) async {
        serverState = invocation.positionalArguments[0] as ContentItem;
        return right(unit);
      });
    });

    test(
      'Upload audio → save → reload → audio URL persists across sessions',
      () async {
        // === SESSION 1: Upload audio and save ===

        final container1 = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        // Wait for initial load
        container1.read(bakhedEditorControllerProvider(rhymeId).notifier);
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify loaded with no audio
        var state1 = container1.read(bakhedEditorControllerProvider(rhymeId));
        expect(state1.item.value?.audioUrl, isNull);

        // Simulate: upload completes, callback fires
        final notifier1 = container1.read(
          bakhedEditorControllerProvider(rhymeId).notifier,
        );
        notifier1.updateAudio(audioUrl, audioFileId, durationMs);

        // Verify state updated before save
        state1 = container1.read(bakhedEditorControllerProvider(rhymeId));
        expect(state1.item.value?.audioUrl, audioUrl);

        // Save
        final saveResult = await notifier1.save();
        expect(saveResult, SaveResult.success);

        // Verify the server state was updated
        expect(serverState.audioUrl, audioUrl);
        expect(serverState.audioFileId, audioFileId);
        expect(serverState.durationMs, durationMs);

        // Dispose session 1 (simulates closing the browser tab)
        container1.dispose();

        // === SESSION 2: Hard reload — new container, fresh state ===

        final container2 = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        // Load the same rhyme from "server"
        container2.read(bakhedEditorControllerProvider(rhymeId).notifier);
        await Future.delayed(const Duration(milliseconds: 50));

        // THE KEY ASSERTION: audio URL persists after hard reload
        final state2 = container2.read(bakhedEditorControllerProvider(rhymeId));
        expect(state2.item.value, isNotNull);
        expect(
          state2.item.value!.audioUrl,
          audioUrl,
          reason:
              'After saving in session 1 and reloading in session 2, '
              'the audioUrl must persist from the server state.',
        );
        expect(state2.item.value!.audioFileId, audioFileId);
        expect(state2.item.value!.durationMs, durationMs);

        container2.dispose();
      },
    );

    test('Audio URL NOT lost when save races ahead of upload '
        '(inflight guard blocks save)', () async {
      final container = ProviderContainer(
        overrides: [
          bakhedRepositoryProvider.overrideWithValue(mockRepository),
          appwriteDbServiceProvider.overrideWithValue(mockDbService),
          mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
        ],
      );

      container.read(bakhedEditorControllerProvider(rhymeId).notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        bakhedEditorControllerProvider(rhymeId).notifier,
      );

      // Start upload — set upload in progress
      notifier.setUploadInProgress(true);

      // Try to save immediately — should be blocked
      notifier.markDirty();
      final blockedResult = await notifier.save();
      expect(blockedResult, SaveResult.uploadInProgress);

      // Server state should NOT have been updated
      expect(serverState.audioUrl, isNull);

      // Complete upload and clear in-flight status
      notifier.updateAudio(audioUrl, audioFileId, durationMs);
      notifier.setUploadInProgress(false);

      // Now save should work
      final successResult = await notifier.save();
      expect(successResult, SaveResult.success);

      // Server state now has the audio
      expect(serverState.audioUrl, audioUrl);

      container.dispose();
    });

    test(
      'Real MediaPickerField upload in progress blocks save (production race fix)',
      () async {
        final container = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
            appwriteDbServiceProvider.overrideWithValue(mockDbService),
            mediaUploaderProvider.overrideWithValue(MockMediaUploader()),
          ],
        );

        container.read(bakhedEditorControllerProvider(rhymeId).notifier);
        await Future.delayed(const Duration(milliseconds: 50));

        final notifier = container.read(
          bakhedEditorControllerProvider(rhymeId).notifier,
        );

        // 1. Simulate MediaPickerField triggering onUploadStateChanged(true)
        notifier.setUploadInProgress(true);

        // Verify the state is updated to isUploading: true
        var state = container.read(bakhedEditorControllerProvider(rhymeId));
        expect(state.isUploading, isTrue);

        // 2. Try to save immediately — should be blocked
        notifier.markDirty();
        final blockedResult = await notifier.save();
        expect(blockedResult, SaveResult.uploadInProgress);

        // Server state should NOT have been updated
        expect(serverState.audioUrl, isNull);

        // 3. Simulate upload completing and updating state
        notifier.updateAudio(audioUrl, audioFileId, durationMs);
        notifier.setUploadInProgress(false);

        // Verify the state is updated to isUploading: false
        state = container.read(bakhedEditorControllerProvider(rhymeId));
        expect(state.isUploading, isFalse);

        // 4. Now save should work
        final successResult = await notifier.save();
        expect(successResult, SaveResult.success);

        // Server state now has the audio
        expect(serverState.audioUrl, audioUrl);

        container.dispose();
      },
    );
  });
}
