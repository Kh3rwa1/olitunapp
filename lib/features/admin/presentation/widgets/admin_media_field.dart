import 'package:itun/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/storage/upload_service.dart';
import '../../../../shared/widgets/video_display.dart';

/// Reusable media upload row used for audio, image, and animation fields
/// across the entire admin panel (letters, numbers, words, sentences, lessons, etc.).
///
/// Handles file picking, upload via [AppwriteStorageUploadService], shows success/error feedback,
/// and provides a direct text input for entering custom URLs manually.
class AdminMediaField extends ConsumerStatefulWidget {
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

  const AdminMediaField({
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
  ConsumerState<AdminMediaField> createState() => _AdminMediaFieldState();
}

class _AdminMediaFieldState extends ConsumerState<AdminMediaField> {
  bool _uploading = false;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.currentUrl ?? '');
  }

  @override
  void didUpdateWidget(covariant AdminMediaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUrl != oldWidget.currentUrl &&
        widget.currentUrl != _urlController.text) {
      _urlController.text = widget.currentUrl ?? '';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

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
      AppLogger.debug(
        'Picked file: ${file.name}, size: ${file.size}, bytes: ${file.bytes != null}',
      );

      final url = await ref
          .read(uploadServiceProvider)
          .uploadMedia(file, widget.uploadFolder);

      AppLogger.debug('Upload result: $url');
      if (url != null) {
        _urlController.text = url;
        widget.onUploaded(url);
      }
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
      AppLogger.debug('Error picking ${widget.label}: $e');
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
                ] else if (hasUrl) ...[
                  _buildDefaultPreview(widget.currentUrl!, isDark),
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
        const SizedBox(height: 10),
        TextField(
          controller: _urlController,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Or enter URL manually...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.black45,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            prefixIcon: Icon(
              Icons.link_rounded,
              size: 18,
              color: widget.accent,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: (val) {
            widget.onUploaded(val.trim().isEmpty ? null : val.trim());
          },
        ),
      ],
    );
  }

  Widget _buildDefaultPreview(String url, bool isDark) {
    final lower = url.toLowerCase();
    final isSvg = lower.contains('.svg') || lower.contains('image/svg');
    final isLottie =
        lower.contains('.json') ||
        lower.contains('.lottie') ||
        lower.contains('/buckets/animations/');
    final isHtml =
        lower.contains('.html') ||
        lower.contains('text/html') ||
        lower.contains('/buckets/html/');
    final isVideo =
        lower.contains('.mp4') ||
        lower.contains('.webm') ||
        lower.contains('.mov') ||
        lower.contains('.m4v') ||
        lower.contains('.3gp') ||
        lower.contains('.avi') ||
        lower.contains('/buckets/videos/');
    final isAudio =
        lower.contains('.mp3') ||
        lower.contains('.wav') ||
        lower.contains('.ogg') ||
        lower.contains('.aac') ||
        lower.contains('.m4a') ||
        lower.contains('/buckets/audio/');

    Widget child;
    if (isVideo) {
      child = VideoDisplay(url: url);
    } else if (isLottie) {
      child = Lottie.network(
        url,
        height: 140,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: Colors.grey,
        ),
      );
    } else if (isSvg) {
      child = kIsWeb
          ? Image.network(
              url,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_rounded,
                size: 48,
                color: Colors.grey,
              ),
            )
          : SvgPicture.network(
              url,
              height: 140,
              placeholderBuilder: (_) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_rounded,
                size: 48,
                color: Colors.grey,
              ),
            );
    } else if (isHtml) {
      child = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code_rounded, size: 42, color: Colors.blue),
          SizedBox(height: 8),
          Text(
            'HTML Interactive File',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      );
    } else if (isAudio) {
      child = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.audiotrack_rounded, size: 42, color: Colors.grey),
          SizedBox(height: 8),
          Text('Audio file selected'),
        ],
      );
    } else {
      child = Image.network(
        url,
        height: 140,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 140,
        width: double.infinity,
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        child: Center(child: child),
      ),
    );
  }
}
