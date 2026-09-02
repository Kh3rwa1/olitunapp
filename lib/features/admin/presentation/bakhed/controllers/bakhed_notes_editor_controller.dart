import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:itun/core/logging/app_logger.dart';
import '../../../../admin/data/bakhed_repository.dart';
import '../../../../../shared/providers/bakhed_content_provider.dart';
import 'bakhed_editor_controller.dart';

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
