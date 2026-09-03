// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/core/version/build_version_checker.dart';
import 'package:itun/core/version/build_version_status.dart';
import 'package:itun/core/logging/app_logger.dart';

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
  VideoPlayerController? _videoController;
  bool _showWarningBanner = false;

  @override
  void initState() {
    super.initState();
    if (widget.value != null && widget.value!.kind == ContentMediaKind.video) {
      _initVideoController(widget.value!.url);
      if (widget.value!.durationMs != null &&
          widget.value!.durationMs! > 30000) {
        _showWarningBanner = true;
      }
    }
  }

  @override
  void didUpdateWidget(covariant MediaPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kind != oldWidget.kind) {
      final controller = _videoController;
      _videoController = null;
      if (controller != null) {
        controller.dispose();
      }
      _showWarningBanner = false;
    }

    if (widget.value?.url != oldWidget.value?.url ||
        widget.value?.kind != oldWidget.value?.kind) {
      if (widget.value != null &&
          widget.value!.kind == ContentMediaKind.video) {
        _initVideoController(widget.value!.url);
        if (widget.value!.durationMs != null &&
            widget.value!.durationMs! > 30000) {
          if (widget.value?.url != oldWidget.value?.url) {
            _showWarningBanner = true;
          }
        } else {
          _showWarningBanner = false;
        }
      } else {
        final controller = _videoController;
        _videoController = null;
        if (controller != null) {
          controller.dispose();
        }
        _showWarningBanner = false;
      }
    }
  }

  @override
  void deactivate() {
    final controller = _videoController;
    if (controller != null) {
      Future.microtask(controller.pause);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initVideoController(String url) {
    final oldController = _videoController;
    _videoController = null;
    if (oldController != null) {
      oldController.dispose();
    }

    if (url.trim().isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;

    controller
        .initialize()
        .then((_) {
          if (mounted && _videoController == controller) {
            setState(() {});
            controller.setVolume(0.0);
            controller.setLooping(true);
            controller.play();
          }
        })
        .catchError((e) {
          AppLogger.warning(
            'Preview video controller initialization failed',
            name: 'MediaPickerField',
            fields: {'url': url, 'error': e.toString()},
          );
        });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool _checkStale() {
    final status = ref.read(buildVersionStatusProvider).value;
    if (status is BuildVersionStale) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Version Mismatch'),
          content: const Text(
            'This page is out of date. Reload before removing or replacing media to prevent data loss.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                reloadBrowser();
              },
              child: const Text('Reload'),
            ),
          ],
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> _pickAndUpload() async {
    if (_checkStale()) return;
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          },
          (media) {
            if (widget.value != null &&
                widget.value!.fileId.isNotEmpty &&
                widget.onRemove != null) {
              widget.onRemove!(widget.value!.fileId);
            }
            if (media.kind == ContentMediaKind.video &&
                media.durationMs != null &&
                media.durationMs! > 30000) {
              setState(() {
                _showWarningBanner = true;
              });
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
    if (_checkStale()) return;
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
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightBackground,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                      if (media.kind == ContentMediaKind.video &&
                          media.durationMs != null &&
                          media.durationMs! > 30000 &&
                          _showWarningBanner) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: isDark
                                    ? Colors.amber[300]
                                    : Colors.amber[800],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cover loops work best under 30 seconds. Longer videos will still upload but may impact mobile experience.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.amber[300]
                                        : Colors.amber[800],
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                tooltip: 'Dismiss warning',
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: isDark
                                      ? Colors.amber[300]
                                      : Colors.amber[800],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showWarningBanner = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _pickAndUpload,
                            icon: const Icon(Icons.cached_rounded, size: 18),
                            label: const Text('Change'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brandBlue,
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
                                ? AppColors.textSecondaryLight
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(height: 12),
                          if (_isUploading)
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _pickAndUpload,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(
                                'Upload ${widget.kind.name.toUpperCase()}',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
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
              memCacheWidth: 800,
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
              Icon(Icons.animation_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Lottie Animation uploaded successfully',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      case ContentMediaKind.video:
        final controller = _videoController;
        if (controller == null || !controller.value.isInitialized) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 140,
              width: double.infinity,
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.brandBlue),
              ),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
                // Premium overlays: scrub/pause controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: controller.value.isPlaying
                              ? 'Pause preview'
                              : 'Play preview',
                          icon: Icon(
                            controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              controller.value.isPlaying
                                  ? controller.pause()
                                  : controller.play();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: AppColors.brandBlue,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatDuration(controller.value.position)} / ${_formatDuration(controller.value.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case ContentMediaKind.audio:
        return Container(
          height: 80,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.audiotrack_rounded, color: AppColors.warning),
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
