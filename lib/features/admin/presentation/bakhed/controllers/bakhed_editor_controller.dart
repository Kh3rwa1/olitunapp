import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../admin/data/bakhed_repository.dart';
import '../../../../../shared/models/content_item.dart';
import '../../../../../shared/providers/bakhed_content_provider.dart';
import '../../../../../core/api/appwrite_db_service.dart';

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

  BakhedEditorState({
    required this.item,
    this.isDirty = false,
    this.isSaving = false,
    this.errorMessage,
    this.uploadProgress = 0.0,
  });

  BakhedEditorState copyWith({
    AsyncValue<ContentItem>? item,
    bool? isDirty,
    bool? isSaving,
    String? errorMessage,
    double? uploadProgress,
  }) {
    return BakhedEditorState(
      item: item ?? this.item,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class BakhedEditorNotifier extends StateNotifier<BakhedEditorState> {
  final String bakhedId;
  final BakhedRepository _repository;
  final Ref _ref;

  /// Tracks the number of audio uploads currently in flight.
  /// save() will refuse to persist while this is > 0.
  int _inflightUploads = 0;
  bool get hasInflightUpload => _inflightUploads > 0;

  BakhedEditorNotifier(this.bakhedId, this._repository, this._ref)
    : super(BakhedEditorState(item: const AsyncValue.loading())) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(item: const AsyncValue.loading());
    final res = await _repository.get(bakhedId);
    res.fold(
      (failure) => state = state.copyWith(
        item: AsyncValue.error(failure, StackTrace.current),
      ),
      (item) =>
          state = state.copyWith(item: AsyncValue.data(item), isDirty: false),
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

  void updateCategoryId(String categoryId) {
    state.item.whenData((item) {
      state = state.copyWith(
        item: AsyncValue.data(item.copyWith(categoryId: categoryId)),
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

  void updateThumbnailUrl(String? url) {
    state.item.whenData((item) {
      final updatedMedia =
          item.heroMedia?.copyWith(url: url ?? '') ??
          ContentMedia(
            url: url ?? '',
            fileId: '',
            kind: ContentMediaKind.image,
          );
      state = state.copyWith(
        item: AsyncValue.data(item.copyWith(heroMedia: updatedMedia)),
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

  /// Uploads an audio file through the repository and sets the audio fields
  /// on completion. While this future is in-flight, save() will return
  /// SaveResult.uploadInProgress instead of persisting stale data.
  Future<void> uploadAndSetAudio(Uint8List bytes, String filename) async {
    _inflightUploads++;
    state = state.copyWith(uploadProgress: 0.1);
    try {
      final result = await _repository.uploadAudio(bytes, filename);
      result.fold(
        (failure) {
          state = state.copyWith(
            errorMessage: failure.message,
            uploadProgress: 0.0,
          );
        },
        (uploadResult) {
          updateAudio(
            uploadResult['url'],
            uploadResult['fileId'],
            null, // duration resolved client-side after player loads
          );
          state = state.copyWith(uploadProgress: 0.0);
        },
      );
    } finally {
      _inflightUploads--;
    }
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

    final currentItem = state.item.value;
    if (currentItem == null) return SaveResult.failure;

    state = BakhedEditorState(
      item: state.item,
      isDirty: state.isDirty,
      isSaving: true,
      uploadProgress: state.uploadProgress,
    );

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

      final dbService = _ref.read(appwriteDbServiceProvider);

      // 2. Save Subcollections (Child-First Save with Diff-based writes)

      // A. Lyrics Save
      final lyricsState = _ref.read(bakhedLyricsEditorProvider(currentItem.id));
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
      final vocabState = _ref.read(
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
      final notesState = _ref.read(bakhedNotesEditorProvider(currentItem.id));
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

      return upsertRes.fold(
        (failure) {
          state = state.copyWith(
            isSaving: false,
            errorMessage: failure.message,
          );
          return SaveResult.failure;
        },
        (_) {
          state = state.copyWith(
            item: AsyncValue.data(
              currentItem.copyWith(updatedAt: nextUpdatedAt),
            ),
            isSaving: false,
            isDirty: false,
          );

          // Re-initialize original lists to establish new baseline for edits
          if (lyricsState.isLoaded) {
            _ref
                .read(bakhedLyricsEditorProvider(currentItem.id).notifier)
                .markClean();
          }
          if (vocabState.isLoaded) {
            _ref
                .read(bakhedVocabularyEditorProvider(currentItem.id).notifier)
                .markClean();
          }
          if (notesState.isLoaded) {
            _ref
                .read(bakhedNotesEditorProvider(currentItem.id).notifier)
                .markClean();
          }

          return SaveResult.success;
        },
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return SaveResult.failure;
    }
  }
}

final bakhedEditorControllerProvider =
    StateNotifierProvider.family<
      BakhedEditorNotifier,
      BakhedEditorState,
      String
    >((ref, bakhedId) {
      final repository = ref.watch(bakhedRepositoryProvider);
      return BakhedEditorNotifier(bakhedId, repository, ref);
    });

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

class BakhedLyricsEditorNotifier extends StateNotifier<BakhedLyricsState> {
  final String bakhedId;
  final BakhedRepository _repository;
  final Ref _ref;

  BakhedLyricsEditorNotifier(this.bakhedId, this._repository, this._ref)
    : super(const BakhedLyricsState());

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
    _ref.read(bakhedEditorControllerProvider(bakhedId).notifier).markDirty();
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
    StateNotifierProvider.family<
      BakhedLyricsEditorNotifier,
      BakhedLyricsState,
      String
    >((ref, bakhedId) {
      final repository = ref.watch(bakhedRepositoryProvider);
      return BakhedLyricsEditorNotifier(bakhedId, repository, ref);
    });

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
    extends StateNotifier<BakhedVocabularyState> {
  final String bakhedId;
  final BakhedRepository _repository;
  final Ref _ref;

  BakhedVocabularyEditorNotifier(this.bakhedId, this._repository, this._ref)
    : super(const BakhedVocabularyState());

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
    _ref.read(bakhedEditorControllerProvider(bakhedId).notifier).markDirty();
  }

  void addItem(BakhedVocabularyItem item) {
    updateItems([...state.currentItems, item]);
  }

  void removeItem(String id, int sortOrder) {
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
    StateNotifierProvider.family<
      BakhedVocabularyEditorNotifier,
      BakhedVocabularyState,
      String
    >((ref, bakhedId) {
      final repository = ref.watch(bakhedRepositoryProvider);
      return BakhedVocabularyEditorNotifier(bakhedId, repository, ref);
    });

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

class BakhedNotesEditorNotifier extends StateNotifier<BakhedNotesState> {
  final String bakhedId;
  final BakhedRepository _repository;
  final Ref _ref;

  BakhedNotesEditorNotifier(this.bakhedId, this._repository, this._ref)
    : super(const BakhedNotesState());

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
    _ref.read(bakhedEditorControllerProvider(bakhedId).notifier).markDirty();
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
    StateNotifierProvider.family<
      BakhedNotesEditorNotifier,
      BakhedNotesState,
      String
    >((ref, bakhedId) {
      final repository = ref.watch(bakhedRepositoryProvider);
      return BakhedNotesEditorNotifier(bakhedId, repository, ref);
    });

final bakhedAudioPlayerProvider = Provider.autoDispose
    .family<AudioPlayer, String>((ref, bakhedId) {
      final player = AudioPlayer();
      final item = ref
          .read(bakhedEditorControllerProvider(bakhedId))
          .item
          .value;
      if (item != null && item.audioUrl != null && item.audioUrl!.isNotEmpty) {
        player.setUrl(item.audioUrl!).catchError((_) => null);
      }
      ref.onDispose(player.dispose);
      return player;
    });
