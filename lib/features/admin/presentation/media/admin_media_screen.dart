import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_form_widgets.dart';
import '../../../../core/storage/upload_service.dart';
import 'admin_media_state.dart';
import 'widgets/media_card.dart';
import 'widgets/media_filter_bar.dart';

class AdminMediaScreen extends ConsumerStatefulWidget {
  final MediaType initialType;
  const AdminMediaScreen({super.key, this.initialType = MediaType.all});

  @override
  ConsumerState<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends ConsumerState<AdminMediaScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    // Initialize provider with initialType
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedMediaTypeProvider.notifier).state = widget.initialType;
    });
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'png',
          'jpg',
          'jpeg',
          'gif',
          'mp3',
          'wav',
          'mp4',
          'mov',
          'webm',
        ],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0;
        });

        int uploadedCount = 0;
        for (var file in result.files) {
          final mediaType = _getMediaType(file.extension ?? '');
          final folder = mediaType == MediaType.audio
              ? 'audio'
              : (mediaType == MediaType.video ? 'video' : 'images');

          // Real upload
          final uploadedUrl = await ref
              .read(uploadServiceProvider)
              .uploadMedia(file, folder);

          if (uploadedUrl != null) {
            final newItem = MediaItem(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  uploadedCount.toString(),
              name: file.name,
              url: uploadedUrl,
              type: mediaType,
              size: file.size,
              uploadedAt: DateTime.now(),
            );

            ref
                .read(mediaItemsProvider.notifier)
                .update((state) => [newItem, ...state]);
            uploadedCount++;
          }

          setState(() {
            _uploadProgress = (uploadedCount / result.files.length);
          });
        }

        setState(() {
          _isUploading = false;
        });

        if (mounted && uploadedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$uploadedCount file(s) uploaded successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  MediaType _getMediaType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return MediaType.image;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'aac':
        return MediaType.audio;
      case 'mp4':
      case 'mov':
      case 'webm':
      case 'avi':
        return MediaType.video;
      default:
        return MediaType.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaItems = ref.watch(mediaItemsProvider);
    final selectedType = ref.watch(selectedMediaTypeProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    final filteredItems = selectedType == MediaType.all
        ? mediaItems
        : mediaItems.where((item) => item.type == selectedType).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'Media Library',
                    subtitle:
                        'Upload and manage images, audio, and video files',
                    eyebrow: 'MEDIA · LIBRARY',
                    actions: [_buildUploadButton(isDark)],
                  ),

                  const SizedBox(height: 24),

                  // Filter tabs
                  MediaFilterBar(
                    selectedType: selectedType,
                    onTypeSelected: (t) =>
                        ref.read(selectedMediaTypeProvider.notifier).state = t,
                  ),
                ],
              ),
            ),

            // Upload progress
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AdminTokens.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Uploading… ${(_uploadProgress * 100).toInt()}%',
                          style: AdminTokens.bodyStrong(isDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AdminTokens.accentSoft(isDark),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AdminTokens.accent,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            // Media grid
            Expanded(
              child: filteredItems.isEmpty
                  ? _buildEmptyState(isDark)
                  : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWideScreen ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return MediaCard(
                          item: filteredItems[index],
                          isDark: isDark,
                          onDelete: () {
                            ref
                                .read(mediaItemsProvider.notifier)
                                .update(
                                  (state) => state
                                      .where(
                                        (i) => i.id != filteredItems[index].id,
                                      )
                                      .toList(),
                                );
                          },
                          onCopyUrl: () {
                            Clipboard.setData(
                              ClipboardData(text: filteredItems[index].url),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('URL copied to clipboard!'),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(bool isDark) {
    return AdminPrimaryButton(
      label: _isUploading ? 'Uploading…' : 'Upload Files',
      icon: _isUploading
          ? Icons.hourglass_top_rounded
          : Icons.cloud_upload_rounded,
      onTap: _isUploading ? () {} : _pickAndUploadFile,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AdminEmptyState(
      icon: Icons.cloud_upload_rounded,
      title: 'No media files yet',
      message:
          'Upload images, audio, or video files to start building your library.',
      actionLabel: 'Upload File',
      onAction: _pickAndUploadFile,
    );
  }
}
