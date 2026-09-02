import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../admin/data/bakhed_repository.dart';
import '../../../../../shared/providers/bakhed_content_provider.dart';
import 'bakhed_editor_controller.dart';

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
