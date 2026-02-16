import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/storage/supabase_service.dart';

/// Reusable upload field widget for admin panel.
/// Provides a text field with an upload button that picks a file,
/// uploads it via HostingerUploadService, and sets the URL.
class AdminUploadField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final String folder;
  final AdminUploadType uploadType;
  final StateSetter? dialogSetState;

  const AdminUploadField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.folder,
    this.uploadType = AdminUploadType.image,
    this.dialogSetState,
  });

  @override
  ConsumerState<AdminUploadField> createState() => _AdminUploadFieldState();
}

class _AdminUploadFieldState extends ConsumerState<AdminUploadField> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    try {
      setState(() => _isUploading = true);
      widget.dialogSetState?.call(() {});

      FileType fileType;
      List<String>? allowedExtensions;

      switch (widget.uploadType) {
        case AdminUploadType.audio:
          fileType = FileType.audio;
          break;
        case AdminUploadType.video:
          fileType = FileType.video;
          break;
        case AdminUploadType.lottie:
          fileType = FileType.custom;
          allowedExtensions = ['json'];
          break;
        case AdminUploadType.image:
        default:
          fileType = FileType.image;
          break;
      }

      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: fileType,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty) {
        final url = await ref
            .read(supabaseServiceProvider)
            .uploadMedia(result.files.first, widget.folder);
        if (url != null) {
          widget.controller.text = url;
          widget.dialogSetState?.call(() {});
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Upload successful!')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
        widget.dialogSetState?.call(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final hasUrl = widget.controller.text.isNotEmpty;

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
        const SizedBox(height: 10),

        // Preview when URL is set
        if (hasUrl && widget.uploadType == AdminUploadType.image)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.network(
                    widget.controller.text,
                    width: double.infinity,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.clear();
                        setState(() {});
                        widget.dialogSetState?.call(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Upload or paste URL...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  prefixIcon: Icon(
                    widget.icon,
                    size: 20,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isUploading
                ? Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  )
                : IconButton.filledTonal(
                    onPressed: _pickAndUpload,
                    icon: const Icon(Icons.upload_rounded, size: 20),
                    tooltip: 'Upload ${widget.label}',
                  ),
          ],
        ),
      ],
    );
  }
}

enum AdminUploadType { image, audio, video, lottie }
