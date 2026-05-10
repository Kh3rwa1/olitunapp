import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/storage/upload_service.dart';

/// Reusable media upload row used for audio, image, and animation fields
/// in admin letter/lesson/category forms.
///
/// Handles file picking, upload via [AppwriteStorageUploadService], and
/// shows success/error feedback. Caller receives the final URL via [onUploaded].
class LetterMediaField extends ConsumerStatefulWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final String? currentUrl;
  final String uploadFolder;
  final FileType fileType;
  final List<String>? allowedExtensions;
  final ValueChanged<String?> onUploaded;
  final Widget Function(String url)? previewBuilder;

  const LetterMediaField({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.accent,
    this.currentUrl,
    required this.uploadFolder,
    required this.fileType,
    this.allowedExtensions,
    required this.onUploaded,
    this.previewBuilder,
  });

  @override
  ConsumerState<LetterMediaField> createState() => _LetterMediaFieldState();
}

class _LetterMediaFieldState extends ConsumerState<LetterMediaField> {
  bool _uploading = false;

  Future<void> _pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: widget.fileType,
        allowedExtensions: widget.allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploading = true);
      final file = result.files.first;
      debugPrint(
        'Picked file: ${file.name}, size: ${file.size}, bytes: ${file.bytes != null}',
      );

      final url = await ref
          .read(uploadServiceProvider)
          .uploadMedia(file, widget.uploadFolder);

      debugPrint('Upload result: $url');
      widget.onUploaded(url);
      setState(() => _uploading = false);

      if (url == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.label} upload failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking ${widget.label}: $e');
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUrl = widget.currentUrl != null && !_uploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
        const SizedBox(height: 12),
        InkWell(
          onTap: _uploading ? null : _pick,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                if (hasUrl && widget.previewBuilder != null) ...[
                  widget.previewBuilder!(widget.currentUrl!),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(
                      _uploading ? Icons.hourglass_top_rounded : widget.icon,
                      color: widget.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _uploading
                            ? 'Uploading...'
                            : hasUrl
                            ? 'Tap to change'
                            : 'Upload ${widget.label}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (hasUrl)
                      Icon(
                        Icons.check_circle_rounded,
                        color: widget.accent,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
