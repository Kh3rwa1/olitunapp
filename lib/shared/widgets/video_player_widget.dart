import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String assetPath;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final double? width;
  final double? height;
  final BoxFit fit;

  const VideoPlayerWidget({
    super.key,
    required this.assetPath,
    this.autoPlay = true,
    this.looping = true,
    this.muted = true,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  /// Whether this path points to a network resource
  bool get isNetwork =>
      assetPath.startsWith('http://') || assetPath.startsWith('https://');

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late CachedVideoPlayerPlusController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _controller = widget.isNetwork
        ? CachedVideoPlayerPlusController.networkUrl(
            Uri.parse(widget.assetPath),
          )
        : CachedVideoPlayerPlusController.asset(widget.assetPath);
    try {
      await _controller.initialize();
      if (widget.looping) await _controller.setLooping(true);
      if (widget.muted) await _controller.setVolume(0);
      if (widget.autoPlay) await _controller.play();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _controller.dispose();
      _initialized = false;
      _initialize();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: CachedVideoPlayerPlus(_controller),
        ),
      ),
    );
  }
}
