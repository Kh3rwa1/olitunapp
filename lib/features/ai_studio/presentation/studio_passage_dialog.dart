import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';

/// Keeps the entire draft visible; users choose what to send, never a substring
/// silently selected by the app.
class StudioPassageDialog extends StatefulWidget {
  const StudioPassageDialog({
    super.key,
    required this.text,
    required this.limit,
    required this.title,
    required this.action,
  });

  final String text;
  final int limit;
  final String title;
  final String action;

  @override
  State<StudioPassageDialog> createState() => _StudioPassageDialogState();
}

class _StudioPassageDialogState extends State<StudioPassageDialog> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.trim().runes.length;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose or edit a passage of up to ${widget.limit} characters. '
                'Your original result will stay unchanged.',
              ),
              AppSpacing.gapH16,
              TextField(
                key: const Key('studio-passage'),
                controller: _controller,
                minLines: 4,
                maxLines: 8,
                maxLength: widget.limit,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Passage to send',
                  alignLabelWithHint: true,
                  counterText: '$length / ${widget.limit}',
                  errorText: length > widget.limit
                      ? 'Shorten the passage to continue. Nothing is truncated.'
                      : null,
                  errorMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: length > 0 && length <= widget.limit
              ? () => Navigator.of(context).pop(_controller.text.trim())
              : null,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
