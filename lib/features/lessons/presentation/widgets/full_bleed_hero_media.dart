import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

class FullBleedHeroMedia extends StatelessWidget {
  const FullBleedHeroMedia({
    super.key,
    required this.animationUrl,
    required this.imageUrl,
    required this.fallback,
  });

  final String? animationUrl;
  final String? imageUrl;
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

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (primaryUrl == null)
            Center(child: fallback)
          else
            _HeroMediaSource(
              url: primaryUrl,
              fallbackUrl: image,
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
    if (_isSvgUrl(url)) {
      return _SvgHeroMedia(url: url, fallback: _buildFallback());
    }

    if (preferAnimation || _isLottieUrl(url)) {
      return _InteractiveLottieHero(url: url, fallback: _buildFallback());
    }

    return _HeroImage(url: url, fallback: _buildFallback());
  }

  Widget _buildFallback() {
    final image = fallbackUrl?.trim();
    if (image != null && image.isNotEmpty) {
      if (_isSvgUrl(image)) {
        return _SvgHeroMedia(
          url: image,
          fallback: Center(child: fallback),
        );
      }
      return _HeroImage(
        url: image,
        fallback: Center(child: fallback),
      );
    }
    return Center(child: fallback);
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

bool _isSvgUrl(String url) => _urlPath(url).endsWith('.svg');

bool _isLottieUrl(String url) {
  final lower = _urlPath(url);
  return lower.endsWith('.json') || lower.endsWith('.lottie');
}

String _urlPath(String url) {
  return Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
}
