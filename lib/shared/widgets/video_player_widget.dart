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

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  CachedVideoPlayerPlusController? _controller;
  bool _initialized = false;
  bool _disposed = false;
  Future<void>? _pendingInit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pendingInit = _initialize();
  }

  Future<void> _initialize() async {
    final controller = widget.isNetwork
        ? CachedVideoPlayerPlusController.networkUrl(
            Uri.parse(widget.assetPath),
          )
        : CachedVideoPlayerPlusController.asset(widget.assetPath);

    // Assign early so dispose() can clean it up if called during init
    _controller = controller;

    try {
      await controller.initialize();

      // Guard: widget may have been disposed while awaiting
      if (_disposed) {
        controller.dispose();
        return;
      }

      if (widget.looping) await controller.setLooping(true);
      if (_disposed) return;

      if (widget.muted) await controller.setVolume(0);
      if (_disposed) return;

      if (widget.autoPlay) await controller.play();
      if (_disposed) return;

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      // Dispose the controller on error to prevent surface leaks
      if (!_disposed) {
        try {
          controller.dispose();
        } catch (_) {}
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || _controller == null || !_initialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed && widget.autoPlay) {
      _controller?.play();
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _reinitialize();
    }
  }

  Future<void> _reinitialize() async {
    // Wait for any pending initialization to complete first
    if (_pendingInit != null) {
      await _pendingInit;
    }

    if (_disposed) return;

    // Safely dispose old controller
    final oldController = _controller;
    _controller = null;
    _initialized = false;

    if (oldController != null) {
      try {
        oldController.dispose();
      } catch (e) {
        debugPrint('Error disposing old video controller: $e');
      }
    }

    if (_disposed) return;
    _pendingInit = _initialize();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);

    final controller = _controller;
    _controller = null;

    if (controller != null) {
      try {
        controller.dispose();
      } catch (e) {
        debugPrint('Error disposing video controller: $e');
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
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
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: CachedVideoPlayerPlus(_controller!),
        ),
      ),
    );
  }
}
