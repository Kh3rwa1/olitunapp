import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A reusable, memory-safe video playback widget.
///
/// Supports autoplay, looping, muting, and handles loading and error states.
class VideoDisplay extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool autoplay;
  final bool loop;
  final bool muted;
  final Widget? placeholder;
  final Widget? errorWidget;

  const VideoDisplay({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.autoplay = true,
    this.loop = true,
    this.muted = true,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<VideoDisplay> createState() => _VideoDisplayState();
}

class _VideoDisplayState extends State<VideoDisplay> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant VideoDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    setState(() {
      _initialized = false;
      _hasError = false;
    });

    try {
      final uri = Uri.parse(widget.url);
      final controller = VideoPlayerController.networkUrl(uri);
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      if (widget.loop) {
        await controller.setLooping(true);
      }
      if (widget.muted) {
        await controller.setVolume(0.0);
      } else {
        await controller.setVolume(1.0);
      }
      if (widget.autoplay) {
        await controller.play();
      }

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildErrorPlaceholder();
    }

    final controller = _controller;
    if (!_initialized || controller == null) {
      return widget.placeholder ?? _buildLoadingPlaceholder();
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      width: widget.width ?? 48,
      height: widget.height ?? 48,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return SizedBox(
      width: widget.width ?? 48,
      height: widget.height ?? 48,
      child: const Center(
        child: Icon(Icons.error_outline_rounded, color: Colors.grey, size: 24),
      ),
    );
  }
}
