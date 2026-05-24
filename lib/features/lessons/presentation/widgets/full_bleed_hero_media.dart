import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/utils/media_type_resolver.dart';
import 'platform_view_stub.dart'
    if (dart.library.js_interop) 'platform_view_web.dart';

class FullBleedHeroMedia extends StatelessWidget {
  const FullBleedHeroMedia({
    super.key,
    required this.animationUrl,
    required this.imageUrl,
    this.fallbackUrl,
    required this.fallback,
  });

  final String? animationUrl;
  final String? imageUrl;
  final String? fallbackUrl;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final animation = animationUrl?.trim();
    final image = imageUrl?.trim();
    final primaryUrl = animation != null && animation.isNotEmpty
        ? animation
        : image != null && image.isNotEmpty
        ? image
        : null;
    final fallbackCandidate =
        fallbackUrl ??
        (animation != null && animation.isNotEmpty ? image : null);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (primaryUrl == null)
            Center(child: fallback)
          else
            _HeroMediaSource(
              url: primaryUrl,
              fallbackUrl: fallbackCandidate,
              fallback: fallback,
              preferAnimation: animation != null && animation.isNotEmpty,
            ),
          const _HeroMediaScrim(),
        ],
      ),
    );
  }
}

class _HeroMediaSource extends StatelessWidget {
  const _HeroMediaSource({
    required this.url,
    required this.fallbackUrl,
    required this.fallback,
    required this.preferAnimation,
  });

  final String url;
  final String? fallbackUrl;
  final Widget fallback;
  final bool preferAnimation;

  @override
  Widget build(BuildContext context) {
    switch (MediaTypeResolver.resolve(url)) {
      case MediaKind.video:
        return _InteractiveVideoHero(url: url, fallback: _buildFallback());
      case MediaKind.svg:
        return _SvgHeroMedia(url: url, fallback: _buildFallback());
      case MediaKind.lottie:
        return _InteractiveLottieHero(url: url, fallback: _buildFallback());
      case MediaKind.html:
        return _HtmlHeroMedia(url: url, fallback: _buildFallback());
      case MediaKind.image:
        return _HeroImage(url: url, fallback: _buildFallback());
      case MediaKind.audio:
      case MediaKind.unknown:
        break;
    }

    if (preferAnimation) {
      return _InteractiveLottieHero(url: url, fallback: _buildFallback());
    }

    return _HeroImage(url: url, fallback: _buildFallback());
  }

  Widget _buildFallback() {
    final image = fallbackUrl?.trim();
    if (image != null && image.isNotEmpty) {
      final centeredFallback = Center(child: fallback);
      switch (MediaTypeResolver.resolve(image)) {
        case MediaKind.video:
          return _InteractiveVideoHero(url: image, fallback: centeredFallback);
        case MediaKind.svg:
          return _SvgHeroMedia(url: image, fallback: centeredFallback);
        case MediaKind.lottie:
          return _InteractiveLottieHero(url: image, fallback: centeredFallback);
        case MediaKind.html:
          return _HtmlHeroMedia(url: image, fallback: centeredFallback);
        case MediaKind.image:
        case MediaKind.audio:
        case MediaKind.unknown:
          return _HeroImage(url: image, fallback: centeredFallback);
      }
    }
    return Center(child: fallback);
  }
}

class _InteractiveVideoHero extends StatefulWidget {
  const _InteractiveVideoHero({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  State<_InteractiveVideoHero> createState() => _InteractiveVideoHeroState();
}

class _InteractiveVideoHeroState extends State<_InteractiveVideoHero> {
  VideoPlayerController? _controller;
  bool _isLoaded = false;
  bool _hasError = false;
  bool _showOverlayIcon = false;
  IconData _overlayIcon = Icons.play_arrow_rounded;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant _InteractiveVideoHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeVideo();
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoaded = false;
      _hasError = false;
    });

    try {
      final uri = Uri.parse(widget.url);
      final controller = VideoPlayerController.networkUrl(uri);
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();

      setState(() {
        _isLoaded = true;
      });
    } catch (e) {
      debugPrint('Error initializing hero video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _disposeVideo() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !_isLoaded) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _overlayIcon = Icons.pause_rounded;
      } else {
        controller.play();
        _overlayIcon = Icons.play_arrow_rounded;
      }
      _showOverlayIcon = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showOverlayIcon = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback;
    }

    final controller = _controller;
    if (!_isLoaded || controller == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          if (_showOverlayIcon)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: (1.0 - value).clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _overlayIcon,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _InteractiveLottieHero extends StatefulWidget {
  const _InteractiveLottieHero({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  State<_InteractiveLottieHero> createState() => _InteractiveLottieHeroState();
}

class _InteractiveLottieHeroState extends State<_InteractiveLottieHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isLoaded = false;
  bool _isPausedByUser = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _InteractiveLottieHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _isLoaded = false;
      _isPausedByUser = false;
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _isLoaded ? _togglePlayback : null,
          onHorizontalDragUpdate: _isLoaded
              ? (details) =>
                    _scrub(details.localPosition.dx, constraints.maxWidth)
              : null,
          child: Lottie.network(
            widget.url,
            controller: _controller,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            repeat: true,
            onLoaded: (composition) {
              _controller.duration = composition.duration;
              _isLoaded = true;
              if (!_isPausedByUser) {
                _controller.repeat();
              }
            },
            frameBuilder: (context, child, composition) {
              if (composition == null) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return child;
            },
            errorBuilder: (context, error, stackTrace) => widget.fallback,
          ),
        );
      },
    );
  }

  void _togglePlayback() {
    setState(() {
      _isPausedByUser = _controller.isAnimating;
      if (_isPausedByUser) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    });
  }

  void _scrub(double dx, double width) {
    if (width <= 0) return;
    _controller.stop();
    _controller.value = (dx / width).clamp(0.0, 1.0);
    _isPausedByUser = true;
  }
}

class _SvgHeroMedia extends StatelessWidget {
  const _SvgHeroMedia({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return SvgPicture.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
      placeholderBuilder: (context) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, _, _) => fallback,
    );
  }
}

class _HeroMediaScrim extends StatelessWidget {
  const _HeroMediaScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.08),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.28),
          ],
          stops: const [0, 0.52, 1],
        ),
      ),
    );
  }
}

class _HtmlHeroMedia extends StatefulWidget {
  const _HtmlHeroMedia({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  State<_HtmlHeroMedia> createState() => _HtmlHeroMediaState();
}

class _HtmlHeroMediaState extends State<_HtmlHeroMedia> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'html-hero-${widget.url.hashCode}';
    if (kIsWeb) {
      registerHtmlView(_viewId, widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return HtmlElementView(viewType: _viewId);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.code_rounded,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Interactive HTML Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This lesson contains an interactive HTML experience. Tap below to launch it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(widget.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_browser_rounded),
              label: const Text('Open Interactive Content'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
