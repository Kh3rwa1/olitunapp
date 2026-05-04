import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/storage/upload_service.dart';
import '../../../../core/theme/admin_tokens.dart';

/// Reusable upload field widget for admin panel.
/// Provides a text field with an upload button that picks a file,
/// uploads it via Appwrite Storage, and sets the URL.
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
      List<String> validExtensions = [];

      switch (widget.uploadType) {
        case AdminUploadType.audio:
          fileType = FileType.audio;
          validExtensions = ['mp3', 'wav', 'ogg', 'aac', 'm4a'];
          break;
        case AdminUploadType.video:
          fileType = FileType.video;
          validExtensions = ['mp4', 'webm', 'mov'];
          break;
        case AdminUploadType.lottie:
          // On web use FileType.any; on native use custom for better UX
          if (kIsWeb) {
            fileType = FileType.any;
          } else {
            fileType = FileType.custom;
            allowedExtensions = ['json'];
          }
          validExtensions = ['json'];
          break;
        case AdminUploadType.lottieOrWebm:
          // On web use FileType.any; on native use custom for better UX
          if (kIsWeb) {
            fileType = FileType.any;
          } else {
            fileType = FileType.custom;
            allowedExtensions = ['json', 'webm', 'webp'];
          }
          validExtensions = ['json', 'webm', 'webp'];
          break;
        case AdminUploadType.image:
          fileType = FileType.image;
          validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'];
          break;
      }

      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: fileType,
        // CRITICAL: only pass allowedExtensions with FileType.custom
        allowedExtensions: fileType == FileType.custom
            ? allowedExtensions
            : null,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        // Client-side extension validation for FileType.any
        final ext = pickedFile.name.split('.').last.toLowerCase();
        if (validExtensions.isNotEmpty && !validExtensions.contains(ext)) {
          throw Exception(
            'Invalid file type: .$ext — Allowed: ${validExtensions.map((e) => '.$e').join(', ')}',
          );
        }

        if (pickedFile.bytes == null || pickedFile.bytes!.isEmpty) {
          throw Exception('File data is empty. Please try again.');
        }

        final url = await ref
            .read(uploadServiceProvider)
            .uploadMedia(pickedFile, widget.folder);
        if (url != null) {
          widget.controller.text = url;
          widget.dialogSetState?.call(() {});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Upload successful!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
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
        Text(widget.label, style: AdminTokens.label(isDark)),
        const SizedBox(height: AdminTokens.space2),

        // Preview when URL is set
        if (hasUrl && widget.uploadType == AdminUploadType.image)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
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
                style: AdminTokens.bodyStrong(isDark),
                decoration: InputDecoration(
                  hintText: 'Upload or paste URL...',
                  hintStyle: AdminTokens.body(
                    isDark,
                  ).copyWith(color: AdminTokens.textTertiary(isDark)),
                  filled: true,
                  fillColor: AdminTokens.sunken(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    borderSide: BorderSide(color: AdminTokens.border(isDark)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    borderSide: BorderSide(color: AdminTokens.border(isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    borderSide: const BorderSide(
                      color: AdminTokens.accent,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    widget.icon,
                    size: 20,
                    color: AdminTokens.textTertiary(isDark),
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

enum AdminUploadType { image, audio, video, lottie, lottieOrWebm }
