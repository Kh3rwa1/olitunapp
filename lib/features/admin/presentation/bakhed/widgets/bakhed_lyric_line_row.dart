import 'package:flutter/material.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import 'bakhed_time_format.dart';

/// A single editable lyric line row inside the Bakhed lyrics timeline editor.
class BakhedLyricLineRow extends StatelessWidget {
  final BakhedLyricLine line;
  final int index;
  final bool isFocused;
  final bool isDark;
  final int derivedEndMs;
  final List<BakhedLyricLine> currentLines;
  final void Function(List<BakhedLyricLine> lines) onLinesChanged;
  final VoidCallback onFocus;
  final VoidCallback onRemove;

  const BakhedLyricLineRow({
    super.key,
    required this.line,
    required this.index,
    required this.isFocused,
    required this.isDark,
    required this.derivedEndMs,
    required this.currentLines,
    required this.onLinesChanged,
    required this.onFocus,
    required this.onRemove,
  });

  void _updateLine(BakhedLyricLine Function(BakhedLyricLine) transform) {
    final lines = List<BakhedLyricLine>.from(currentLines);
    lines[index] = transform(lines[index]);
    onLinesChanged(lines);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
          onTap: onFocus,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
                      final numVal = int.tryParse(val) ?? line.startMs;
                      _updateLine((l) => l.copyWith(startMs: numVal));
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
                      formatBakhedMs(derivedEndMs),
                      style: TextStyle(
                        color: AdminTokens.textTertiary(isDark),
                        fontFeatures: const [FontFeature.tabularFigures()],
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
                    onChanged: (val) =>
                        _updateLine((l) => l.copyWith(olChiki: val)),
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
                    onChanged: (val) =>
                        _updateLine((l) => l.copyWith(latin: val)),
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
                    onChanged: (val) =>
                        _updateLine((l) => l.copyWith(meaning: val)),
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
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
