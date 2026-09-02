part of 'bakhed_lyrics_tab.dart';

// Section builders extracted from the bakhed lyrics tab build method.

extension _BakhedLyricsTabSections on _BakhedLyricsTabState {
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
}
