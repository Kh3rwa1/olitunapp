import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:just_audio/just_audio.dart';
import 'package:itun/core/logging/app_logger.dart';
import '../../../../admin/data/bakhed_repository.dart';
import '../../../../../shared/models/content_item.dart';
import '../../../../../shared/providers/bakhed_content_provider.dart';
import '../../../../../core/api/appwrite_db_service.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/core/error/failures.dart';

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

  @Deprecated('Use updateCategory with the string name instead')
  void updateCategoryId(String categoryId) {
    state.item.whenData((item) {
      state = state.copyWith(
        item: AsyncValue.data(item.copyWith(categoryId: categoryId)),
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

  @Deprecated('Use updateCoverMedia with mediaType')
  void updateThumbnail(ContentMedia? media) {
    updateCoverMedia(media, 'image');
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
            final docId = ID.unique();
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
            final docId = ID.unique();
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
            final docId = ID.unique();
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

class BakhedLyricsState {
  final List<BakhedLyricLine> originalLines;
  final List<BakhedLyricLine> currentLines;
  final bool isLoaded;
  final bool isLoading;
  final String? error;

  const BakhedLyricsState({
    this.originalLines = const [],
    this.currentLines = const [],
    this.isLoaded = false,
    this.isLoading = false,
    this.error,
  });

  bool get isDirty {
    if (!isLoaded) return false;
    if (originalLines.length != currentLines.length) return true;
    for (int i = 0; i < originalLines.length; i++) {
      if (originalLines[i] != currentLines[i]) return true;
    }
    return false;
  }

  BakhedLyricsState copyWith({
    List<BakhedLyricLine>? originalLines,
    List<BakhedLyricLine>? currentLines,
    bool? isLoaded,
    bool? isLoading,
    String? error,
  }) {
    return BakhedLyricsState(
      originalLines: originalLines ?? this.originalLines,
      currentLines: currentLines ?? this.currentLines,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BakhedLyricsEditorNotifier
    extends FamilyNotifier<BakhedLyricsState, String> {
  late String bakhedId;

  BakhedRepository get _repository => ref.read(bakhedRepositoryProvider);

  @override
  BakhedLyricsState build(String arg) {
    bakhedId = arg;
    return const BakhedLyricsState();
  }

  Future<void> ensureLoaded() async {
    if (state.isLoaded || state.isLoading) return;
    state = BakhedLyricsState(
      originalLines: state.originalLines,
      currentLines: state.currentLines,
      isLoaded: state.isLoaded,
      isLoading: true,
    );

    final res = await _repository.getLyrics(bakhedId);
    res.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (lines) {
        state = BakhedLyricsState(
          originalLines: List.from(lines),
          currentLines: List.from(lines),
          isLoaded: true,
        );
      },
    );
  }

  void updateLines(List<BakhedLyricLine> lines) {
    final sorted = List<BakhedLyricLine>.from(lines)
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    final updated = List.generate(sorted.length, (index) {
      return sorted[index].copyWith(lineIndex: index);
    });

    state = state.copyWith(currentLines: updated);
    ref.read(bakhedEditorControllerProvider(bakhedId).notifier).markDirty();
  }

  void reorderLines(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final lines = List<BakhedLyricLine>.from(state.currentLines);
    final item = lines.removeAt(oldIndex);
    lines.insert(newIndex, item);

    // Adjust startMs to preserve sorting invariant startMs[i] < startMs[i+1]
    for (int i = 0; i < lines.length; i++) {
      if (i == 0) {
        if (lines[i].startMs > (lines.length > 1 ? lines[1].startMs : 0)) {
          lines[i] = lines[i].copyWith(startMs: 0);
        }
      } else {
        if (lines[i].startMs < lines[i - 1].startMs) {
          final prevStart = lines[i - 1].startMs;
          final nextStart = i < lines.length - 1
              ? lines[i + 1].startMs
              : prevStart + 5000;
          final mid = prevStart + (nextStart - prevStart) ~/ 2;
          lines[i] = lines[i].copyWith(startMs: mid);
        }
      }
    }

    updateLines(lines);
  }

  void addLine(BakhedLyricLine line) {
    updateLines([...state.currentLines, line]);
  }

  void removeLine(String id, int lineIndex) {
    final updated = state.currentLines.where((e) {
      if (id.isNotEmpty && e.id == id) return false;
      return e.lineIndex != lineIndex;
    }).toList();
    updateLines(updated);
  }

  void bulkPaste(String text, {required bool replace}) {
    final lines = text.split('\n');
    final parsedLines = <BakhedLyricLine>[];
    int startIdx = replace ? 0 : state.currentLines.length;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split('|');
      final olChiki = parts.isNotEmpty ? parts[0].trim() : '';
      final latin = parts.length > 1 ? parts[1].trim() : '';
      final meaning = parts.length > 2 ? parts[2].trim() : '';

      parsedLines.add(
        BakhedLyricLine(
          id: '',
          lineIndex: startIdx,
          startMs: startIdx * 5000,
          endMs: (startIdx + 1) * 5000,
          olChiki: olChiki,
          latin: latin,
          meaning: meaning,
        ),
      );
      startIdx++;
    }

    if (replace) {
      updateLines(parsedLines);
    } else {
      updateLines([...state.currentLines, ...parsedLines]);
    }
  }

  void markClean() {
    state = state.copyWith(originalLines: List.from(state.currentLines));
  }
}

final bakhedLyricsEditorProvider =
    NotifierProvider.family<
      BakhedLyricsEditorNotifier,
      BakhedLyricsState,
      String
    >(BakhedLyricsEditorNotifier.new);

// ==========================================
// 3. Vocabulary Editor Controller
// ==========================================

class BakhedVocabularyState {
  final List<BakhedVocabularyItem> originalItems;
  final List<BakhedVocabularyItem> currentItems;
  final bool isLoaded;
  final bool isLoading;
  final String? error;

  const BakhedVocabularyState({
    this.originalItems = const [],
    this.currentItems = const [],
    this.isLoaded = false,
    this.isLoading = false,
    this.error,
  });

  bool get isDirty {
    if (!isLoaded) return false;
    if (originalItems.length != currentItems.length) return true;
    for (int i = 0; i < originalItems.length; i++) {
      if (originalItems[i] != currentItems[i]) return true;
    }
    return false;
  }

  BakhedVocabularyState copyWith({
    List<BakhedVocabularyItem>? originalItems,
    List<BakhedVocabularyItem>? currentItems,
    bool? isLoaded,
    bool? isLoading,
    String? error,
  }) {
    return BakhedVocabularyState(
      originalItems: originalItems ?? this.originalItems,
      currentItems: currentItems ?? this.currentItems,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BakhedVocabularyEditorNotifier
    extends FamilyNotifier<BakhedVocabularyState, String> {
  late String bakhedId;

  BakhedRepository get _repository => ref.read(bakhedRepositoryProvider);

  @override
  BakhedVocabularyState build(String arg) {
    bakhedId = arg;
    return const BakhedVocabularyState();
  }

  Future<void> ensureLoaded() async {
    if (state.isLoaded || state.isLoading) return;
    state = BakhedVocabularyState(
      originalItems: state.originalItems,
      currentItems: state.currentItems,
      isLoaded: state.isLoaded,
      isLoading: true,
    );

    final res = await _repository.getVocabulary(bakhedId);
    res.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (items) {
        state = BakhedVocabularyState(
          originalItems: List.from(items),
          currentItems: List.from(items),
          isLoaded: true,
        );
      },
    );
  }

  void updateItems(List<BakhedVocabularyItem> items) {
    // Standardize sortOrder values sequentially
    final updated = List.generate(items.length, (index) {
      return items[index].copyWith(sortOrder: index);
    });
    state = state.copyWith(currentItems: updated);
    ref.read(bakhedEditorControllerProvider(bakhedId).notifier).markDirty();
  }

  void addItem(BakhedVocabularyItem item) {
    updateItems([...state.currentItems, item]);
  }

  void removeItem(String id, int sortOrder) {
    final removedItem = state.currentItems.firstWhere(
      (e) =>
          (id.isNotEmpty && e.id == id) ||
          (id.isEmpty && e.sortOrder == sortOrder),
      orElse: () => const BakhedVocabularyItem(
        id: '',
        olChiki: '',
        latin: '',
        meaning: '',
        audioFileId: '',
        sortOrder: -1,
      ),
    );
    if (removedItem.audioFileId.isNotEmpty) {
      ref
          .read(bakhedEditorControllerProvider(bakhedId).notifier)
          .markForDeletion(removedItem.audioFileId);
    }

    final updated = state.currentItems.where((e) {
      if (id.isNotEmpty && e.id == id) return false;
      return e.sortOrder != sortOrder;
    }).toList();
    updateItems(updated);
  }

  void markClean() {
    state = state.copyWith(originalItems: List.from(state.currentItems));
  }
}

final bakhedVocabularyEditorProvider =
    NotifierProvider.family<
      BakhedVocabularyEditorNotifier,
      BakhedVocabularyState,
      String
    >(BakhedVocabularyEditorNotifier.new);

// ==========================================
// 4. Cultural Notes Editor Controller
// ==========================================

class BakhedNotesState {
  final List<BakhedCulturalNote> originalNotes;
  final List<BakhedCulturalNote> currentNotes;
  final bool isLoaded;
  final bool isLoading;
  final String? error;

  const BakhedNotesState({
    this.originalNotes = const [],
    this.currentNotes = const [],
    this.isLoaded = false,
    this.isLoading = false,
    this.error,
  });

  bool get isDirty {
    if (!isLoaded) return false;
    if (originalNotes.length != currentNotes.length) return true;
    for (int i = 0; i < originalNotes.length; i++) {
      if (originalNotes[i] != currentNotes[i]) return true;
    }
    return false;
  }

  BakhedNotesState copyWith({
    List<BakhedCulturalNote>? originalNotes,
    List<BakhedCulturalNote>? currentNotes,
    bool? isLoaded,
    bool? isLoading,
    String? error,
  }) {
    return BakhedNotesState(
      originalNotes: originalNotes ?? this.originalNotes,
      currentNotes: currentNotes ?? this.currentNotes,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BakhedNotesEditorNotifier
    extends FamilyNotifier<BakhedNotesState, String> {
  late String bakhedId;

  BakhedRepository get _repository => ref.read(bakhedRepositoryProvider);

  @override
  BakhedNotesState build(String arg) {
    bakhedId = arg;
    return const BakhedNotesState();
  }

  Future<void> ensureLoaded() async {
    if (state.isLoaded || state.isLoading) return;
    state = BakhedNotesState(
      originalNotes: state.originalNotes,
      currentNotes: state.currentNotes,
      isLoaded: state.isLoaded,
      isLoading: true,
    );

    final res = await _repository.getCulturalNotes(bakhedId);
    res.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (notes) {
        state = BakhedNotesState(
          originalNotes: List.from(notes),
          currentNotes: List.from(notes),
          isLoaded: true,
        );
      },
    );
  }

  void updateNotes(List<BakhedCulturalNote> notes) {
    state = state.copyWith(currentNotes: notes);
    ref.read(bakhedEditorControllerProvider(bakhedId).notifier).markDirty();
  }

  void addNote(BakhedCulturalNote note) {
    updateNotes([...state.currentNotes, note]);
  }

  void removeNote(String noteId) {
    final updated = state.currentNotes
        .where((e) => e.noteId != noteId)
        .toList();
    updateNotes(updated);
  }

  void markClean() {
    state = state.copyWith(originalNotes: List.from(state.currentNotes));
  }
}

final bakhedNotesEditorProvider =
    NotifierProvider.family<
      BakhedNotesEditorNotifier,
      BakhedNotesState,
      String
    >(BakhedNotesEditorNotifier.new);

final bakhedAudioPlayerProvider = Provider.autoDispose.family<AudioPlayer, String>((
  ref,
  bakhedId,
) {
  final player = AudioPlayer();
  player.setWebCrossOrigin(WebCrossOrigin.anonymous);

  // Listen to the audioUrl changes in the editor state.
  // This ensures the player dynamically loads the audio URL when it becomes available
  // (e.g. after the document loads asynchronously or after a new audio file is uploaded).
  ref.listen<String?>(
    bakhedEditorControllerProvider(
      bakhedId,
    ).select((s) => s.item.value?.audioUrl),
    (previous, next) {
      if (next != null && next.isNotEmpty && next != previous) {
        player.setUrl(next).catchError((e) {
          AppLogger.debug('bakhedAudioPlayer: Error setting URL ($next): $e');
          return null;
        });
      } else if (next == null || next.isEmpty) {
        player.stop();
      }
    },
    fireImmediately: true,
  );

  // Listen to the player's duration stream to automatically update the document's durationMs
  // when the player client-side decodes and resolves the audio file metadata.
  final subscription = player.durationStream.listen((duration) {
    if (duration != null && duration > Duration.zero) {
      final notifier = ref.read(
        bakhedEditorControllerProvider(bakhedId).notifier,
      );
      final currentItem = ref
          .read(bakhedEditorControllerProvider(bakhedId))
          .item
          .value;
      if (currentItem != null &&
          currentItem.durationMs != duration.inMilliseconds) {
        notifier.updateAudio(
          currentItem.audioUrl,
          currentItem.audioFileId,
          duration.inMilliseconds,
        );
      }
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    player.dispose();
  });

  return player;
});
