// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/core/logging/app_logger.dart';

/// Autoplay looping muted video hero for the Bakhed detail screen.
///
/// Renders:
/// - `coverMediaType == 'image'` → [CachedNetworkImage] (preserves existing cache)
/// - `coverMediaType == 'video'` → muted, looping, auto-playing [VideoPlayer]
/// - `media == null`            → [fallback] widget
///
/// Handles app lifecycle pause/resume and screen exit disposal.
class CoverHero extends StatefulWidget {
  final ContentMedia? media;
  final String? coverMediaType;
  final Widget? fallback;

  /// Default aspect ratio matching the existing Bakhed detail header layout.
  static const double defaultAspectRatio = 1.6;

  /// Init timeout for video controller initialization.
  final Duration initTimeout;

  const CoverHero({
    super.key,
    required this.media,
    required this.coverMediaType,
    this.fallback,
    this.initTimeout = const Duration(seconds: 10),
  });

  @override
  State<CoverHero> createState() => _CoverHeroState();
}

class _CoverHeroState extends State<CoverHero> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _initFailed = false;

  /// Guards resume playback — true from initState to dispose.
  bool _isActive = true;

  /// Tracks whether video was playing before app lifecycle pause,
  /// so we only resume if it was actually playing.
  bool _wasPlayingBeforePause = false;

  @override
  void initState() {
    super.initState();
    _isActive = true;
    WidgetsBinding.instance.addObserver(this);
    if (widget.coverMediaType == 'video') {
      _initVideoController();
    }
  }

  @override
  void didUpdateWidget(covariant CoverHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    final mediaChanged = widget.media?.fileId != oldWidget.media?.fileId;
    final typeChanged = widget.coverMediaType != oldWidget.coverMediaType;
    if (mediaChanged || typeChanged) {
      _disposeVideoController();
      if (widget.coverMediaType == 'video') {
        _initVideoController();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActive || _videoController == null || !_isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _wasPlayingBeforePause = _videoController!.value.isPlaying;
        _videoController!.pause();
        break;
      case AppLifecycleState.resumed:
        // Only resume if this widget is still the active screen and
        // video was playing before the lifecycle pause.
        if (_isActive && _wasPlayingBeforePause) {
          _videoController!.play();
        }
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _isActive = false;
    WidgetsBinding.instance.removeObserver(this);
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    final controller = _videoController;
    _videoController = null;
    _isInitialized = false;
    _initFailed = false;
    _wasPlayingBeforePause = false;
    controller?.dispose();
  }

  void _initVideoController() {
    final url = widget.media?.url;
    if (url == null || url.trim().isEmpty) {
      setState(() => _initFailed = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;

    controller
        .initialize()
        .timeout(widget.initTimeout)
        .then((_) async {
          // Guard: user may have popped the screen between initialize()
          // starting and completing (Refinement 2 — mounted guard after await).
          if (!mounted || _videoController != controller) return;

          await controller.setVolume(0.0);
          if (!mounted || _videoController != controller) return;

          await controller.setLooping(true);
          if (!mounted || _videoController != controller) return;

          await controller.play();
          if (!mounted || _videoController != controller) return;

          setState(() {
            _isInitialized = true;
          });
        })
        .catchError((Object e) {
          AppLogger.warning(
            'Cover video hero initialization failed',
            name: 'CoverHero',
            fields: {'url': url, 'error': e.toString()},
          );
          if (mounted && _videoController == controller) {
            setState(() => _initFailed = true);
            controller.dispose();
            _videoController = null;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final hasMedia = media != null && media.url.trim().isNotEmpty;

    if (!hasMedia || _initFailed) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    if (widget.coverMediaType == 'video') {
      if (_isInitialized && _videoController != null) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      }
      // Still initializing — show a subtle loading state
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.fallback ?? Container(color: Colors.black26),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white38,
              ),
            ),
          ),
        ],
      );
    }

    // Image cover — preserve existing CachedNetworkImage behavior
    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.black26),
      errorWidget: (context, url, err) =>
          widget.fallback ?? const SizedBox.shrink(),
    );
  }
}
