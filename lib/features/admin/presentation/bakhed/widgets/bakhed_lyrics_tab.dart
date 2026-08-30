import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../controllers/bakhed_editor_controller.dart';

/// Lyrics timeline editor tab of the Bakhed editor.
class BakhedLyricsTab extends ConsumerStatefulWidget {
  final String bakhedId;
  const BakhedLyricsTab({super.key, required this.bakhedId});

  @override
  ConsumerState<BakhedLyricsTab> createState() => _BakhedLyricsTabState();
}

class _BakhedLyricsTabState extends ConsumerState<BakhedLyricsTab> {
  int? _focusedRowIndex;

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = ((ms % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  Future<void> _showBulkPasteDialog() async {
    final textController = TextEditingController();
    bool replaceAll = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AdminTokens.overlay(
                Theme.of(context).brightness == Brightness.dark,
              ),
              title: const Text('Bulk Paste Lyrics'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Format: Ol Chiki | Latin | English Meaning (One per line)',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Example: ᱚᱞ ᱪᱤᱠᱤ | latin text | english meaning',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'ᱚᱞ ᱪᱤᱠᱤ | latin | meaning\nᱚᱞ ᱪᱤᱠᱤ | latin | meaning',
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Replace existing lyrics'),
                      subtitle: const Text(
                        'Warning: this will delete all currently marked lines',
                      ),
                      value: replaceAll,
                      onChanged: (val) {
                        setState(() {
                          replaceAll = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final notifier = ref.read(
                      bakhedLyricsEditorProvider(widget.bakhedId).notifier,
                    );
                    notifier.bulkPaste(
                      textController.text,
                      replace: replaceAll,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
          // Timeline Player Bar
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            initialData: player.playerState,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final playing = playerState?.playing ?? false;

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

                      return Card(
                        color: AdminTokens.raised(isDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusMd,
                          ),
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
                                    onPressed: () => playing
                                        ? player.pause()
                                        : player.play(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatMs(position.inMilliseconds),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: position.inMilliseconds
                                          .toDouble()
                                          .clamp(
                                            0.0,
                                            duration.inMilliseconds.toDouble() >
                                                    0
                                                ? duration.inMilliseconds
                                                      .toDouble()
                                                : 1.0,
                                          ),
                                      max:
                                          duration.inMilliseconds.toDouble() > 0
                                          ? duration.inMilliseconds.toDouble()
                                          : 1.0,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) => player.seek(
                                        Duration(milliseconds: val.toInt()),
                                      ),
                                    ),
                                  ),
                                  Text(_formatMs(duration.inMilliseconds)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    onPressed: () {
                                      final currentPos =
                                          position.inMilliseconds;
                                      final focusIdx = _focusedRowIndex ?? 0;
                                      if (focusIdx <
                                          lyricsState.currentLines.length) {
                                        final lines =
                                            List<BakhedLyricLine>.from(
                                              lyricsState.currentLines,
                                            );
                                        lines[focusIdx] = lines[focusIdx]
                                            .copyWith(startMs: currentPos);
                                        lyricsNotifier.updateLines(lines);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Marked line ${focusIdx + 1} at ${_formatMs(currentPos)}',
                                            ),
                                            duration: const Duration(
                                              milliseconds: 700,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );

                                        setState(() {
                                          if (focusIdx <
                                              lyricsState.currentLines.length -
                                                  1) {
                                            _focusedRowIndex = focusIdx + 1;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.content_paste_rounded,
                                        ),
                                        label: const Text('Bulk Paste'),
                                        onPressed: _showBulkPasteDialog,
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('Add Line'),
                                        onPressed: () {
                                          final currentIdx =
                                              lyricsState.currentLines.length;
                                          final defaultStart = currentIdx > 0
                                              ? lyricsState
                                                        .currentLines
                                                        .last
                                                        .startMs +
                                                    5000
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
                                        },
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
          ),
          const SizedBox(height: 16),

          // Header Row
          const Row(
            children: [
              SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    '#',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'StartMs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'EndMs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Ol Chiki',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  'Latin',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  'Meaning',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 100),
            ],
          ),
          const SizedBox(height: 8),

          // Reorderable list
          Expanded(
            child: ReorderableListView.builder(
              itemCount: lyricsState.currentLines.length,
              // ignore: deprecated_member_use
              onReorder: lyricsNotifier.reorderLines,
              itemBuilder: (context, index) {
                final line = lyricsState.currentLines[index];
                final isFocused = _focusedRowIndex == index;
                final derivedEndMs = index < lyricsState.currentLines.length - 1
                    ? lyricsState.currentLines[index + 1].startMs
                    : durationMs;

                return MouseRegion(
                  key: ValueKey('line_${line.id}_$index'),
                  child: Card(
                    color: isFocused
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : AdminTokens.raised(isDark),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      side: BorderSide(
                        color: isFocused
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AdminTokens.border(isDark),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _focusedRowIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            // Selection index
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: isFocused
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isFocused
                                        ? AppColors.primary
                                        : AdminTokens.textPrimary(isDark),
                                  ),
                                ),
                              ),
                            ),

                            // StartMs input
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                initialValue: line.startMs.toString(),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final numVal =
                                      int.tryParse(val) ?? line.startMs;
                                  final lines = List<BakhedLyricLine>.from(
                                    lyricsState.currentLines,
                                  );
                                  lines[index] = lines[index].copyWith(
                                    startMs: numVal,
                                  );
                                  lyricsNotifier.updateLines(lines);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Derived EndMs
                            SizedBox(
                              width: 90,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  _formatMs(derivedEndMs),
                                  style: TextStyle(
                                    color: AdminTokens.textTertiary(isDark),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Ol Chiki text
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: line.olChiki,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final lines = List<BakhedLyricLine>.from(
                                    lyricsState.currentLines,
                                  );
                                  lines[index] = lines[index].copyWith(
                                    olChiki: val,
                                  );
                                  lyricsNotifier.updateLines(lines);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Latin text
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: line.latin,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final lines = List<BakhedLyricLine>.from(
                                    lyricsState.currentLines,
                                  );
                                  lines[index] = lines[index].copyWith(
                                    latin: val,
                                  );
                                  lyricsNotifier.updateLines(lines);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Meaning text
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: line.meaning,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final lines = List<BakhedLyricLine>.from(
                                    lyricsState.currentLines,
                                  );
                                  lines[index] = lines[index].copyWith(
                                    meaning: val,
                                  );
                                  lyricsNotifier.updateLines(lines);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Actions
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () {
                                lyricsNotifier.removeLine(
                                  line.id,
                                  line.lineIndex,
                                );
                                if (isFocused) {
                                  setState(() {
                                    _focusedRowIndex = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. Learning Tab (Vocabulary + Cultural Notes)
// ==========================================
