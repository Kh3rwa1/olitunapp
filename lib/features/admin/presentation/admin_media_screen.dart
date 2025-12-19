import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';

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
final mediaItemsProvider = StateProvider<List<MediaItem>>((ref) => [
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
]);

final selectedMediaTypeProvider = StateProvider<MediaType>((ref) => MediaType.all);

class AdminMediaScreen extends ConsumerStatefulWidget {
  const AdminMediaScreen({super.key});

  @override
  ConsumerState<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends ConsumerState<AdminMediaScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'mp3', 'wav', 'mp4', 'mov', 'webm'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0;
        });

        // Simulate upload progress
        for (var file in result.files) {
          // Simulate upload
          for (int i = 0; i <= 100; i += 10) {
            await Future.delayed(const Duration(milliseconds: 100));
            setState(() {
              _uploadProgress = i / 100;
            });
          }

          // Add to media list
          final mediaType = _getMediaType(file.extension ?? '');
          final newItem = MediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: file.name,
            url: 'https://firebase-storage-url/${file.name}',
            type: mediaType,
            size: file.size,
            uploadedAt: DateTime.now(),
          );

          ref.read(mediaItemsProvider.notifier).update((state) => [newItem, ...state]);
        }

        setState(() {
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.files.length} file(s) uploaded successfully!'),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Media Library',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload and manage images, audio, and video files',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Upload button
                      _buildUploadButton(isDark),
                    ],
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Uploading... ${(_uploadProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                            ref.read(mediaItemsProvider.notifier).update(
                              (state) => state.where((i) => i.id != filteredItems[index].id).toList(),
                            );
                          },
                          onCopyUrl: () {
                            Clipboard.setData(ClipboardData(text: filteredItems[index].url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URL copied to clipboard!')),
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
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: _isUploading ? null : AppColors.heroGradient,
          color: _isUploading ? Colors.grey : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isUploading ? null : AppColors.glowShadow(AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isUploading ? Icons.hourglass_top_rounded : Icons.cloud_upload_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isUploading ? 'Uploading...' : 'Upload Files',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark, MediaType selectedType) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterTab(
            label: 'All',
            icon: Icons.grid_view_rounded,
            isSelected: selectedType == MediaType.all,
            onTap: () => ref.read(selectedMediaTypeProvider.notifier).state = MediaType.all,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Images',
            icon: Icons.image_rounded,
            isSelected: selectedType == MediaType.image,
            onTap: () => ref.read(selectedMediaTypeProvider.notifier).state = MediaType.image,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Audio',
            icon: Icons.audiotrack_rounded,
            isSelected: selectedType == MediaType.audio,
            onTap: () => ref.read(selectedMediaTypeProvider.notifier).state = MediaType.audio,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Video',
            icon: Icons.videocam_rounded,
            isSelected: selectedType == MediaType.video,
            onTap: () => ref.read(selectedMediaTypeProvider.notifier).state = MediaType.video,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.cloud_upload_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No media files yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload images, audio, or video files to get started',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickAndUploadFile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.glowShadow(AppColors.primary),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Upload First File',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
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
        return AppColors.primary;
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
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: isDark ? null : AppColors.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getColor().withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack(
                    children: [
                      // Icon/Preview
                      Center(
                        child: item.type == MediaType.image
                            ? Icon(_getIcon(), size: 48, color: _getColor())
                            : Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: _getColor().withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(_getIcon(), size: 32, color: _getColor()),
                              ),
                      ),
                      // Actions menu
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
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
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
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
              // Info
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(item.size),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
