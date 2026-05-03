import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_page_header.dart';
import 'widgets/admin_form_widgets.dart';
import '../../../core/storage/upload_service.dart';

// Media type enum
enum MediaType { all, image, audio, video }

// Sample media item model
class MediaItem {
  final String id;
  final String name;
  final String url;
  final MediaType type;
  final int size;
  final DateTime uploadedAt;

  MediaItem({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });
}

// Provider for media items (mock data for preview)
final mediaItemsProvider = StateProvider<List<MediaItem>>(
  (ref) => [
    MediaItem(
      id: '1',
      name: 'alphabet_a.png',
      url: 'https://via.placeholder.com/200',
      type: MediaType.image,
      size: 45000,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MediaItem(
      id: '2',
      name: 'lesson_intro.mp3',
      url: 'https://example.com/audio.mp3',
      type: MediaType.audio,
      size: 2500000,
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MediaItem(
      id: '3',
      name: 'welcome_video.mp4',
      url: 'https://example.com/video.mp4',
      type: MediaType.video,
      size: 15000000,
      uploadedAt: DateTime.now(),
    ),
  ],
);

final selectedMediaTypeProvider = StateProvider<MediaType>(
  (ref) => MediaType.all,
);

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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
                  _buildFilterTabs(isDark, selectedType),
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
                        childAspectRatio: 1,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return _MediaCard(
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

  Widget _buildFilterTabs(bool isDark, MediaType selectedType) {
    void setType(MediaType t) =>
        ref.read(selectedMediaTypeProvider.notifier).state = t;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AdminFilterChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            selected: selectedType == MediaType.all,
            onTap: () => setType(MediaType.all),
          ),
          const SizedBox(width: 8),
          AdminFilterChip(
            label: 'Images',
            icon: Icons.image_rounded,
            selected: selectedType == MediaType.image,
            onTap: () => setType(MediaType.image),
          ),
          const SizedBox(width: 8),
          AdminFilterChip(
            label: 'Audio',
            icon: Icons.audiotrack_rounded,
            selected: selectedType == MediaType.audio,
            onTap: () => setType(MediaType.audio),
          ),
          const SizedBox(width: 8),
          AdminFilterChip(
            label: 'Video',
            icon: Icons.videocam_rounded,
            selected: selectedType == MediaType.video,
            onTap: () => setType(MediaType.video),
          ),
        ],
      ),
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

class _MediaCard extends StatelessWidget {
  final MediaItem item;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onCopyUrl;

  const _MediaCard({
    required this.item,
    required this.isDark,
    required this.onDelete,
    required this.onCopyUrl,
  });

  IconData _getIcon() {
    switch (item.type) {
      case MediaType.image:
        return Icons.image_rounded;
      case MediaType.audio:
        return Icons.audiotrack_rounded;
      case MediaType.video:
        return Icons.videocam_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getColor() {
    switch (item.type) {
      case MediaType.image:
        return AdminTokens.accent;
      case MediaType.audio:
        return AppColors.accentPurple;
      case MediaType.video:
        return AppColors.accentCoral;
      default:
        return AppColors.accentCyan;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _getColor();
    return Container(
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AdminTokens.radiusLg),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius:
                            BorderRadius.circular(AdminTokens.radiusMd),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Icon(_getIcon(), size: 30, color: accent),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AdminTokens.overlay(isDark),
                          borderRadius:
                              BorderRadius.circular(AdminTokens.radiusXs),
                          border:
                              Border.all(color: AdminTokens.border(isDark)),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: AdminTokens.textSecondary(isDark),
                        ),
                      ),
                      color: AdminTokens.overlay(isDark),
                      onSelected: (value) {
                        if (value == 'copy') onCopyUrl();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.link_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Copy URL'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTokens.bodyStrong(isDark),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(item.size),
                  style: AdminTokens.label(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
