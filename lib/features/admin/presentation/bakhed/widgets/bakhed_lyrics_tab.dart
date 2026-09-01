import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../controllers/bakhed_editor_controller.dart';
import 'bakhed_bulk_paste_dialog.dart';
import 'bakhed_lyric_line_row.dart';
import 'bakhed_time_format.dart';

/// Lyrics timeline editor tab of the Bakhed editor.
class BakhedLyricsTab extends ConsumerStatefulWidget {
  final String bakhedId;
  const BakhedLyricsTab({super.key, required this.bakhedId});

  @override
  ConsumerState<BakhedLyricsTab> createState() => _BakhedLyricsTabState();
}

class _BakhedLyricsTabState extends ConsumerState<BakhedLyricsTab> {
  int? _focusedRowIndex;

  void _markLineStart(
    int positionMs,
    BakhedLyricsState lyricsState,
    BakhedLyricsEditorNotifier lyricsNotifier,
  ) {
    final focusIdx = _focusedRowIndex ?? 0;
    if (focusIdx >= lyricsState.currentLines.length) return;

    final lines = List<BakhedLyricLine>.from(lyricsState.currentLines);
    lines[focusIdx] = lines[focusIdx].copyWith(startMs: positionMs);
    lyricsNotifier.updateLines(lines);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked line ${focusIdx + 1} at ${formatBakhedMs(positionMs)}',
        ),
        duration: const Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      if (focusIdx < lyricsState.currentLines.length - 1) {
        _focusedRowIndex = focusIdx + 1;
      }
    });
  }

  void _addLine(
    BakhedLyricsState lyricsState,
    BakhedLyricsEditorNotifier lyricsNotifier,
  ) {
    final currentIdx = lyricsState.currentLines.length;
    final defaultStart = currentIdx > 0
        ? lyricsState.currentLines.last.startMs + 5000
        : 0;
    final newLine = BakhedLyricLine(
      id: '',
      lineIndex: currentIdx,
      startMs: defaultStart,
      endMs: defaultStart + 5000,
      olChiki: '',
      latin: '',
      meaning: '',
    );
    lyricsNotifier.addLine(newLine);
  }

  Widget _buildPlayerBar(
    bool isDark,
    AudioPlayer player,
    BakhedLyricsState lyricsState,
    BakhedLyricsEditorNotifier lyricsNotifier,
  ) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      initialData: player.playerState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;

        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          initialData: player.duration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: player.positionStream,
              initialData: player.position,
              builder: (context, positionSnapshot) {
                var position = positionSnapshot.data ?? Duration.zero;
                if (position > duration) position = duration;
                final maxMs = duration.inMilliseconds.toDouble() > 0
                    ? duration.inMilliseconds.toDouble()
                    : 1.0;

                return Card(
                  color: AdminTokens.raised(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    side: BorderSide(color: AdminTokens.border(isDark)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                playing
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.play_circle_outline_rounded,
                                color: AppColors.primary,
                                size: 36,
                              ),
                              onPressed: () =>
                                  playing ? player.pause() : player.play(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatBakhedMs(position.inMilliseconds),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: position.inMilliseconds
                                    .toDouble()
                                    .clamp(0.0, maxMs),
                                max: maxMs,
                                activeColor: AppColors.primary,
                                onChanged: (val) => player.seek(
                                  Duration(milliseconds: val.toInt()),
                                ),
                              ),
                            ),
                            Text(formatBakhedMs(duration.inMilliseconds)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.timer_rounded,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Mark Line Start',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => _markLineStart(
                                position.inMilliseconds,
                                lyricsState,
                                lyricsNotifier,
                              ),
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.content_paste_rounded,
                                  ),
                                  label: const Text('Bulk Paste'),
                                  onPressed: () => showBakhedBulkPasteDialog(
                                    context,
                                    ref,
                                    widget.bakhedId,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Line'),
                                  onPressed: () =>
                                      _addLine(lyricsState, lyricsNotifier),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static const _headerRow = Row(
    children: [
      SizedBox(
        width: 48,
        child: Center(
          child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      SizedBox(
        width: 100,
        child: Text('StartMs', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      SizedBox(
        width: 100,
        child: Text('EndMs', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      Expanded(
        flex: 2,
        child: Text('Ol Chiki', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      SizedBox(width: 16),
      Expanded(
        flex: 2,
        child: Text('Latin', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      SizedBox(width: 16),
      Expanded(
        flex: 3,
        child: Text('Meaning', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      SizedBox(width: 100),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lyricsState = ref.watch(bakhedLyricsEditorProvider(widget.bakhedId));
    final lyricsNotifier = ref.read(
      bakhedLyricsEditorProvider(widget.bakhedId).notifier,
    );
    final player = ref.watch(bakhedAudioPlayerProvider(widget.bakhedId));
    final item = ref.watch(
      bakhedEditorControllerProvider(
        widget.bakhedId,
      ).select((s) => s.item.value),
    );
    final durationMs = item?.durationMs ?? 0;

    if (!lyricsState.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildPlayerBar(isDark, player, lyricsState, lyricsNotifier),
          const SizedBox(height: 16),
          _headerRow,
          const SizedBox(height: 8),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: lyricsState.currentLines.length,
              // reorderLines pre-adjusts newIndex with old-style semantics;
              // migrating to onReorderItem would double-adjust the index.
              // ignore: deprecated_member_use
              onReorder: lyricsNotifier.reorderLines,
              itemBuilder: (context, index) {
                final line = lyricsState.currentLines[index];
                final isFocused = _focusedRowIndex == index;
                final derivedEndMs =
                    index < lyricsState.currentLines.length - 1
                    ? lyricsState.currentLines[index + 1].startMs
                    : durationMs;

                return BakhedLyricLineRow(
                  key: ValueKey('line_${line.id}_$index'),
                  line: line,
                  index: index,
                  isFocused: isFocused,
                  isDark: isDark,
                  derivedEndMs: derivedEndMs,
                  currentLines: lyricsState.currentLines,
                  onLinesChanged: lyricsNotifier.updateLines,
                  onFocus: () {
                    setState(() {
                      _focusedRowIndex = index;
                    });
                  },
                  onRemove: () {
                    lyricsNotifier.removeLine(line.id, line.lineIndex);
                    if (isFocused) {
                      setState(() {
                        _focusedRowIndex = null;
                      });
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
