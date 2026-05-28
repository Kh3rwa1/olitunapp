import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/core/logging/app_logger.dart';

class CoverThumbnail extends StatefulWidget {
  final ContentMedia? media;
  final String? coverMediaType;
  final BoxFit fit;
  final Widget? fallback;
  final double? width;
  final double? height;
  final bool showVideoBadge;
  final Duration initTimeout;

  const CoverThumbnail({
    super.key,
    required this.media,
    required this.coverMediaType,
    this.fit = BoxFit.cover,
    this.fallback,
    this.width,
    this.height,
    this.showVideoBadge = true,
    this.initTimeout = const Duration(seconds: 5),
  });

  @override
  State<CoverThumbnail> createState() => _CoverThumbnailState();
}

class _CoverThumbnailState extends State<CoverThumbnail> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.coverMediaType == 'video') {
      _initController();
    }
  }

  @override
  void didUpdateWidget(covariant CoverThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final mediaChanged = widget.media?.fileId != oldWidget.media?.fileId;
    final typeChanged = widget.coverMediaType != oldWidget.coverMediaType;
    if (mediaChanged || typeChanged) {
      if (widget.coverMediaType == 'video') {
        _initController();
      } else {
        _clearController();
      }
    }
  }

  @override
  void deactivate() {
    // Defer pause to a microtask to avoid markNeedsBuild exceptions when
    // the framework tears down the widget tree during disposal. Calling
    // controller.pause() synchronously inside deactivate() would trigger
    // a setState on the VideoPlayer's internal listener while the tree
    // is already locked.
    final controller = _videoController;
    if (controller != null) {
      Future.microtask(controller.pause);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _clearController();
    super.dispose();
  }

  void _clearController() {
    final controller = _videoController;
    _videoController = null;
    _isInitialized = false;
    _initFailed = false;
    if (controller != null) {
      controller.dispose();
    }
  }

  void _initController() {
    _clearController();

    final url = widget.media?.url;
    if (url == null || url.trim().isEmpty) {
      setState(() {
        _initFailed = true;
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;

    controller
        .initialize()
        .timeout(widget.initTimeout)
        .then((_) {
          if (mounted && _videoController == controller) {
            setState(() {
              _isInitialized = true;
            });
            controller.setVolume(0.0);
          }
        })
        .catchError((e) {
          AppLogger.warning(
            'Cover video thumbnail initialization failed',
            name: 'CoverThumbnail',
            fields: {'url': url, 'error': e.toString()},
          );
          if (mounted && _videoController == controller) {
            setState(() {
              _initFailed = true;
            });
            controller.dispose();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    final media = widget.media;
    final hasMedia = media != null && media.url.trim().isNotEmpty;

    if (!hasMedia || _initFailed) {
      content = widget.fallback ?? const Icon(Icons.music_note_rounded);
    } else if (widget.coverMediaType == 'video') {
      if (_isInitialized) {
        content = SizedBox.expand(child: VideoPlayer(_videoController!));
      } else {
        content = const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
    } else {
      content = Image.network(
        media.url,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) =>
            widget.fallback ?? const Icon(Icons.music_note_rounded),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    if (widget.coverMediaType == 'video' &&
        widget.showVideoBadge &&
        hasMedia &&
        !_initFailed) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Positioned(
            bottom: 4,
            right: 4,
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ),
        ],
      );
    }

    if (widget.width != null || widget.height != null) {
      content = SizedBox(
        width: widget.width,
        height: widget.height,
        child: content,
      );
    }

    return content;
  }
}
