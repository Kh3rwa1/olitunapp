// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/shared/models/content_item.dart';

class MediaPickerField extends ConsumerStatefulWidget {
  final String label;
  final ContentMediaKind kind;
  final ContentMedia? value;
  final ValueChanged<ContentMedia?> onChanged;
  final ValueChanged<bool>? onUploadStateChanged;
  final ValueChanged<String>? onRemove;

  const MediaPickerField({
    super.key,
    required this.label,
    required this.kind,
    this.value,
    required this.onChanged,
    this.onUploadStateChanged,
    this.onRemove,
  });

  @override
  ConsumerState<MediaPickerField> createState() => _MediaPickerFieldState();
}

class _MediaPickerFieldState extends ConsumerState<MediaPickerField> {
  bool _isUploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() {
      _isUploading = true;
      _error = null;
    });
    widget.onUploadStateChanged?.call(true);

    try {
      final uploader = ref.read(mediaUploaderProvider);
      final res = await uploader.pickAndUpload(kind: widget.kind);

      if (mounted) {
        res.fold(
          (failure) {
            setState(() {
              _error = failure.message;
            });
          },
          (media) {
            if (widget.value != null &&
                widget.value!.fileId.isNotEmpty &&
                widget.onRemove != null) {
              widget.onRemove!(widget.value!.fileId);
            }
            widget.onChanged(media);
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      widget.onUploadStateChanged?.call(false);
    }
  }

  void _clearMedia() {
    if (widget.value != null && widget.value!.fileId.isNotEmpty) {
      if (widget.onRemove != null) {
        widget.onRemove!(widget.value!.fileId);
      } else {
        ref.read(mediaUploaderProvider).delete(widget.value!.fileId);
      }
    }
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = widget.value;
    final hasMedia = media != null && media.url.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: hasMedia
                ? Column(
                    children: [
                      // Active preview card
                      _buildPreview(context, media),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _pickAndUpload,
                            icon: const Icon(Icons.cached_rounded, size: 18),
                            label: const Text('Change'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _clearMedia,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Icon(
                            _getIconForKind(widget.kind),
                            size: 44,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          if (_isUploading)
                            const CircularProgressIndicator(
                              color: Color(0xFF10B981),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _pickAndUpload,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(
                                'Upload ${widget.kind.name.toUpperCase()}',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForKind(ContentMediaKind kind) {
    switch (kind) {
      case ContentMediaKind.image:
      case ContentMediaKind.svg:
        return Icons.image_rounded;
      case ContentMediaKind.video:
        return Icons.video_library_rounded;
      case ContentMediaKind.audio:
        return Icons.audiotrack_rounded;
      case ContentMediaKind.lottie:
        return Icons.animation_rounded;
    }
  }

  Widget _buildPreview(BuildContext context, ContentMedia media) {
    if (media.url.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    switch (media.kind) {
      case ContentMediaKind.image:
      case ContentMediaKind.svg:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140,
            width: double.infinity,
            color: Colors.black12,
            child: CachedNetworkImage(
              imageUrl: media.url,
              fit: BoxFit.contain,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image),
            ),
          ),
        );
      case ContentMediaKind.lottie:
        return Container(
          height: 120,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.animation_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Lottie Animation uploaded successfully',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      case ContentMediaKind.video:
        return Container(
          height: 120,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_rounded, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text(
                'Video clip uploaded successfully',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      case ContentMediaKind.audio:
        return Container(
          height: 80,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.audiotrack_rounded, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'Audio track uploaded successfully',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
    }
  }
}
