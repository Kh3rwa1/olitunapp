import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
import '../../../../admin/data/bakhed_repository.dart';
import '../../../../../shared/models/content_item.dart';
import '../../../../../core/api/appwrite_db_service.dart';
import '../../../../../core/api/appwrite_query_builders.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/core/error/failures.dart';
import 'bakhed_lyrics_editor_controller.dart';
import 'bakhed_notes_editor_controller.dart';
import 'bakhed_vocabulary_editor_controller.dart';

// The lyrics, vocabulary, and notes editor controllers live in sibling
// files and are re-exported here so existing imports keep working.
export 'bakhed_lyrics_editor_controller.dart';
export 'bakhed_notes_editor_controller.dart';
export 'bakhed_vocabulary_editor_controller.dart';

enum SaveResult { success, concurrencyConflict, uploadInProgress, failure }

// ==========================================
// 1. Basics & Audio Editor Controller
// ==========================================
class BakhedEditorState {
  final AsyncValue<ContentItem> item;
  final bool isDirty;
  final bool isSaving;
  final String? errorMessage;
  final double uploadProgress;
  final bool isUploading;
  final List<String> pendingDeletions;
  final bool isNewDraft;

  BakhedEditorState({
    required this.item,
    this.isDirty = false,
    this.isSaving = false,
    this.errorMessage,
    this.uploadProgress = 0.0,
    this.isUploading = false,
    this.pendingDeletions = const [],
    this.isNewDraft = false,
  });

  BakhedEditorState copyWith({
    AsyncValue<ContentItem>? item,
    bool? isDirty,
    bool? isSaving,
    String? errorMessage,
    double? uploadProgress,
    bool? isUploading,
    List<String>? pendingDeletions,
    bool? isNewDraft,
  }) {
    return BakhedEditorState(
      item: item ?? this.item,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
      pendingDeletions: pendingDeletions ?? this.pendingDeletions,
      isNewDraft: isNewDraft ?? this.isNewDraft,
    );
  }
}

class BakhedEditorNotifier extends FamilyNotifier<BakhedEditorState, String> {
  late String bakhedId;
  bool _disposed = false;

  BakhedRepository get _repository => ref.read(bakhedRepositoryProvider);

  @override
  BakhedEditorState build(String arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    bakhedId = arg;
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(load);
    return BakhedEditorState(item: const AsyncValue.loading());
  }

  int _inflightUploads = 0;
  bool get hasInflightUpload => _inflightUploads > 0;

  void setUploadInProgress(bool inProgress) {
    if (inProgress) {
      _inflightUploads++;
    } else {
      _inflightUploads = _inflightUploads > 0 ? _inflightUploads - 1 : 0;
    }
    state = state.copyWith(isUploading: _inflightUploads > 0);
  }

  void markForDeletion(String fileId) {
    if (fileId.isEmpty) return;
    state = state.copyWith(
      pendingDeletions: [...state.pendingDeletions, fileId],
      isDirty: true,
    );
  }

  Future<void> load() async {
    if (_disposed) return;
    state = state.copyWith(item: const AsyncValue.loading());
    final res = await _repository.get(bakhedId);
    if (_disposed) return;
    res.fold(
      (failure) {
        if (failure is ServerFailure && failure.code == 404) {
          // 404 = new document, initialize empty draft
          final draft = ContentItem.empty(
            id: bakhedId,
            kind: ContentKind.rhyme,
          );
          state = state.copyWith(
            item: AsyncValue.data(draft),
            isDirty: false,
            isNewDraft: true,
            pendingDeletions: const [],
          );
          AppLogger.debug('Initialized new rhyme draft for id $bakhedId');
        } else {
          // Genuine load failure
          state = state.copyWith(
            item: AsyncValue.error(failure, StackTrace.current),
            isNewDraft: false,
          );
        }
      },
      (item) => state = state.copyWith(
        item: AsyncValue.data(item),
        isDirty: false,
        isNewDraft: false,
        pendingDeletions: const [],
      ),
    );
  }

  void updateTitle(String title) {
    state.item.whenData((item) {
      state = state.copyWith(
        item: AsyncValue.data(item.copyWith(title: title)),
        isDirty: true,
      );
    });
  }

  void updateTitleOlChiki(String titleOlChiki) {
    state.item.whenData((item) {
      state = state.copyWith(
        item: AsyncValue.data(item.copyWith(titleOlChiki: titleOlChiki)),
        isDirty: true,
      );
    });
  }

  void updateCategory(String? name) {
    state.item.whenData((item) {
      state = state.copyWith(
        item: AsyncValue.data(item.copyWith(category: name)),
        isDirty: true,
      );
    });
  }

  void updateIsPremium(bool isPremium) {
    state.item.whenData((item) {
      state = state.copyWith(
        item: AsyncValue.data(item.copyWith(isPremium: isPremium)),
        isDirty: true,
      );
    });
  }

  void updateCoverMedia(ContentMedia? media, String mediaType) {
    state.item.whenData((item) {
      final oldFileId = item.heroMedia?.fileId;
      if (oldFileId != null &&
          oldFileId.isNotEmpty &&
          oldFileId != media?.fileId) {
        markForDeletion(oldFileId);
      }
      state = state.copyWith(
        item: AsyncValue.data(
          item.copyWith(heroMedia: media, coverMediaType: mediaType),
        ),
        isDirty: true,
      );
    });
  }

  void clearCover() {
    state.item.whenData((item) {
      final oldFileId = item.heroMedia?.fileId;
      if (oldFileId != null && oldFileId.isNotEmpty) {
        markForDeletion(oldFileId);
      }
      state = state.copyWith(
        item: AsyncValue.data(
          item.copyWith(heroMedia: null, coverMediaType: null),
        ),
        isDirty: true,
      );
    });
  }

  void updateAudio(String? url, String? fileId, int? durationMs) {
    state.item.whenData((item) {
      state = state.copyWith(
        item: AsyncValue.data(
          item.copyWith(
            audioUrl: url,
            audioFileId: fileId,
            durationMs: durationMs,
          ),
        ),
        isDirty: true,
      );
    });
  }

  void markDirty() {
    state = state.copyWith(isDirty: true);
  }

  Future<SaveResult> save() async {
    // Guard: refuse to save while an audio upload is still in-flight.
    if (_inflightUploads > 0) {
      state = state.copyWith(
        errorMessage:
            'An audio upload is still in progress. Please wait for it to finish before saving.',
      );
      return SaveResult.uploadInProgress;
    }

    final initialItem = state.item.value;
    if (initialItem == null) return SaveResult.failure;

    // Audio duration is probed synchronously by MediaUploader before the
    // MediaPickerField.onChanged callback fires, so durationMs is already
    // in state by the time the user can click Save. If durationMs is still
    // null here, the probe failed — proceed with save, the deferred player
    // listener will backfill on first playback as a fallback.
    final currentItem = initialItem;

    state = state.copyWith(isSaving: true);

    try {
      // 1. Optimistic Concurrency Check
      final serverRes = await _repository.get(currentItem.id);
      bool conflict = false;
      serverRes.fold(
        (_) {}, // Proceed if fetch fails (could be offline or first time)
        (serverItem) {
          if (serverItem.updatedAt.isAfter(currentItem.updatedAt)) {
            conflict = true;
          }
        },
      );

      if (conflict) {
        state = state.copyWith(
          isSaving: false,
          errorMessage:
              'Another administrator has modified this document. Please reload.',
        );
        return SaveResult.concurrencyConflict;
      }

      final dbService = ref.read(appwriteDbServiceProvider);

      // 2. Save Subcollections (Child-First Save with Diff-based writes)

      // A. Lyrics Save
      final lyricsState = ref.read(bakhedLyricsEditorProvider(currentItem.id));
      if (lyricsState.isLoaded) {
        try {
          final currentIds = lyricsState.currentLines
              .map((e) => e.id)
              .where((id) => id.isNotEmpty)
              .toSet();

          final toDelete = lyricsState.originalLines
              .where((e) => !currentIds.contains(e.id))
              .toList();
          final toCreate = lyricsState.currentLines
              .where((e) => e.id.isEmpty)
              .toList();
          final toUpdate = lyricsState.currentLines.where((curr) {
            if (curr.id.isEmpty) return false;
            final matches = lyricsState.originalLines
                .where((o) => o.id == curr.id)
                .toList();
            if (matches.isEmpty) return false;
            final orig = matches.first;
            return orig != curr;
          }).toList();

          for (final line in toDelete) {
            await dbService.deleteDocument('bakhed_lyrics', line.id);
          }
          for (final line in toCreate) {
            final docId = DbId.unique();
            final idx = lyricsState.currentLines.indexOf(line);
            final derivedEndMs = idx < lyricsState.currentLines.length - 1
                ? lyricsState.currentLines[idx + 1].startMs
                : (currentItem.durationMs ?? 0);
            final payload = line
                .copyWith(id: docId, endMs: derivedEndMs)
                .toJson(currentItem.id);
            await dbService.createDocument('bakhed_lyrics', docId, payload);
          }
          for (final line in toUpdate) {
            final idx = lyricsState.currentLines.indexOf(line);
            final derivedEndMs = idx < lyricsState.currentLines.length - 1
                ? lyricsState.currentLines[idx + 1].startMs
                : (currentItem.durationMs ?? 0);
            final payload = line
                .copyWith(endMs: derivedEndMs)
                .toJson(currentItem.id);
            await dbService.updateDocument('bakhed_lyrics', line.id, payload);
          }
        } catch (e) {
          state = state.copyWith(
            isSaving: false,
            errorMessage: 'Failed to save lyrics. Other changes were aborted.',
          );
          return SaveResult.failure;
        }
      }

      // B. Vocabulary Save
      final vocabState = ref.read(
        bakhedVocabularyEditorProvider(currentItem.id),
      );
      if (vocabState.isLoaded) {
        try {
          final currentIds = vocabState.currentItems
              .map((e) => e.id)
              .where((id) => id.isNotEmpty)
              .toSet();

          final toDelete = vocabState.originalItems
              .where((e) => !currentIds.contains(e.id))
              .toList();
          final toCreate = vocabState.currentItems
              .where((e) => e.id.isEmpty)
              .toList();
          final toUpdate = vocabState.currentItems.where((curr) {
            if (curr.id.isEmpty) return false;
            final matches = vocabState.originalItems
                .where((o) => o.id == curr.id)
                .toList();
            if (matches.isEmpty) return false;
            final orig = matches.first;
            return orig != curr;
          }).toList();

          for (final itemVal in toDelete) {
            await dbService.deleteDocument('bakhed_vocabulary', itemVal.id);
          }
          for (final itemVal in toCreate) {
            final docId = DbId.unique();
            await dbService.createDocument(
              'bakhed_vocabulary',
              docId,
              itemVal.copyWith(id: docId).toJson(currentItem.id),
            );
          }
          for (final itemVal in toUpdate) {
            await dbService.updateDocument(
              'bakhed_vocabulary',
              itemVal.id,
              itemVal.toJson(currentItem.id),
            );
          }
        } catch (e) {
          state = state.copyWith(
            isSaving: false,
            errorMessage:
                'Failed to save vocabulary. Other changes were aborted.',
          );
          return SaveResult.failure;
        }
      }

      // C. Cultural Notes Save
      final notesState = ref.read(bakhedNotesEditorProvider(currentItem.id));
      if (notesState.isLoaded) {
        try {
          final currentIds = notesState.currentNotes
              .map((e) => e.noteId)
              .where((id) => id.isNotEmpty)
              .toSet();

          final toDelete = notesState.originalNotes
              .where((e) => !currentIds.contains(e.noteId))
              .toList();
          final toCreate = notesState.currentNotes
              .where((e) => e.noteId.isEmpty)
              .toList();
          final toUpdate = notesState.currentNotes.where((curr) {
            if (curr.noteId.isEmpty) return false;
            final matches = notesState.originalNotes
                .where((o) => o.noteId == curr.noteId)
                .toList();
            if (matches.isEmpty) return false;
            final orig = matches.first;
            return orig != curr;
          }).toList();

          for (final note in toDelete) {
            await dbService.deleteDocument(
              'bakhed_cultural_notes',
              note.noteId,
            );
          }
          for (final note in toCreate) {
            final docId = DbId.unique();
            await dbService.createDocument(
              'bakhed_cultural_notes',
              docId,
              note.copyWith(noteId: docId).toJson(currentItem.id),
            );
          }
          for (final note in toUpdate) {
            await dbService.updateDocument(
              'bakhed_cultural_notes',
              note.noteId,
              note.toJson(currentItem.id),
            );
          }
        } catch (e) {
          state = state.copyWith(
            isSaving: false,
            errorMessage:
                'Failed to save cultural notes. Other changes were aborted.',
          );
          return SaveResult.failure;
        }
      }

      // 3. Re-check concurrency right before parent upsert to close TOCTOU gap.
      //    The first check was at the start of save(). Between then and now,
      //    subcollection saves may have taken ~500ms — enough time for another
      //    admin to save. Re-reading is cheap (~50ms) and shrinks the race
      //    window from ~500ms to ~50ms.
      final reCheckRes = await _repository.get(currentItem.id);
      bool lateConflict = false;
      reCheckRes.fold(
        (_) {}, // Proceed if fetch fails
        (serverItem) {
          if (serverItem.updatedAt.isAfter(currentItem.updatedAt)) {
            lateConflict = true;
          }
        },
      );
      if (lateConflict) {
        state = state.copyWith(
          isSaving: false,
          errorMessage:
              'Another administrator saved while your subcollections were being written. Please reload.',
        );
        return SaveResult.concurrencyConflict;
      }

      // 4. Save Parent Rhyme Metadata Last
      final nextUpdatedAt = DateTime.now();
      final upsertRes = await _repository.upsert(
        currentItem.copyWith(updatedAt: nextUpdatedAt),
      );

      final saveResult = upsertRes.fold<SaveResult>(
        (failure) {
          state = state.copyWith(
            isSaving: false,
            errorMessage: failure.message,
          );
          return SaveResult.failure;
        },
        (_) {
          // Deletion of pending files after successful DB commit (Pattern A)
          final deletions = List<String>.from(state.pendingDeletions);
          state = state.copyWith(
            item: AsyncValue.data(
              currentItem.copyWith(updatedAt: nextUpdatedAt),
            ),
            isSaving: false,
            isDirty: false,
            isNewDraft: false,
            pendingDeletions: const [],
          );

          final uploader = ref.read(mediaUploaderProvider);
          // Execute deletions in background so it doesn't block the UI transit
          Future.microtask(() async {
            for (final fileId in deletions) {
              try {
                final delRes = await uploader.deleteIfUnreferenced(
                  fileId: fileId,
                  checks: const [
                    ReferenceCheck(
                      databaseId: 'olitun_db',
                      collectionId: 'rhymes',
                      fieldNames: ['audioFileId'],
                    ),
                    ReferenceCheck(
                      databaseId: 'olitun_db',
                      collectionId: 'bakhed_vocabulary',
                      fieldNames: ['audioFileId'],
                    ),
                  ],
                );
                delRes.fold(
                  (f) => AppLogger.debug(
                    'Failed to clean up pending media file $fileId during save commit: ${f.message}',
                    name: 'BakhedEditorController',
                  ),
                  (_) => AppLogger.debug(
                    'Successfully cleaned up pending media file $fileId during save commit',
                    name: 'BakhedEditorController',
                  ),
                );
              } catch (e) {
                AppLogger.debug(
                  'Error deleting pending media file $fileId during save commit: $e',
                  name: 'BakhedEditorController',
                );
              }
            }
          });

          // Re-initialize original lists to establish new baseline for edits
          if (lyricsState.isLoaded) {
            ref
                .read(bakhedLyricsEditorProvider(currentItem.id).notifier)
                .markClean();
          }
          if (vocabState.isLoaded) {
            ref
                .read(bakhedVocabularyEditorProvider(currentItem.id).notifier)
                .markClean();
          }
          if (notesState.isLoaded) {
            ref
                .read(bakhedNotesEditorProvider(currentItem.id).notifier)
                .markClean();
          }

          return SaveResult.success;
        },
      );
      return saveResult;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return SaveResult.failure;
    }
  }
}

final bakhedEditorControllerProvider =
    NotifierProvider.family<BakhedEditorNotifier, BakhedEditorState, String>(
      BakhedEditorNotifier.new,
    );

// ==========================================
// 2. Lyrics Timeline Editor Controller
// ==========================================
