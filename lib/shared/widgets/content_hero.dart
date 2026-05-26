// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:video_player/video_player.dart';
import 'package:itun/shared/widgets/lottie_display.dart';
import 'package:itun/shared/widgets/animated_svg_display.dart';

class ContentHero extends StatefulWidget {
  final ContentItem item;
  final Color accentColor;
  final VoidCallback? onBackPressed;

  const ContentHero({
    super.key,
    required this.item,
    required this.accentColor,
    this.onBackPressed,
  });

  @override
  State<ContentHero> createState() => _ContentHeroState();
}

class _ContentHeroState extends State<ContentHero> {
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoIfNecessary();
  }

  @override
  void didUpdateWidget(covariant ContentHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.heroMedia != oldWidget.item.heroMedia) {
      _disposeVideo();
      _initializeVideoIfNecessary();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;
    _isVideoPlaying = false;
  }

  void _initializeVideoIfNecessary() {
    final media = widget.item.heroMedia;
    if (media != null && media.kind == ContentMediaKind.video) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(media.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.item.heroMedia;
    final String watermark = widget.item.title.isNotEmpty
        ? widget.item.title[0].toUpperCase()
        : 'O';

    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Core Background Gradient matching accentColor
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.accentColor,
                  widget.accentColor.withRed(
                    ((widget.accentColor.r * 255).round() - 40).clamp(0, 255),
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. Large faded Watermark backdrop text
          Positioned(
            right: -24,
            bottom: -32,
            child: Opacity(
              opacity: 0.12,
              child: Text(
                widget.item.olChiki ?? watermark,
                style: const TextStyle(
                  fontSize: 240,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'OlChiki',
                ),
              ),
            ),
          ),

          // 3. Render Hero Media (if non-null)
          if (media != null)
            Positioned.fill(child: _buildHeroMediaWidget(media)),

          // 4. Smooth bottom visual dark overlay for text contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 5. Hero Content (Back button, Title, Subtitle, tags)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.item.olChiki != null ||
                    widget.item.titleOlChiki != null) ...[
                  Text(
                    widget.item.titleOlChiki ?? widget.item.olChiki!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'OlChiki',
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  widget.item.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                if (widget.item.subtitle != null &&
                    widget.item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.item.subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
                if (widget.item.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: widget.item.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // 6. Floating Close / Back button
          Positioned(
            left: 12,
            top: 48,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed:
                    widget.onBackPressed ?? () => Navigator.maybePop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMediaWidget(ContentMedia media) {
    switch (media.kind) {
      case ContentMediaKind.image:
        return CachedNetworkImage(
          imageUrl: media.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.black12),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, color: Colors.white30, size: 48),
        );
      case ContentMediaKind.svg:
        return AnimatedSvgDisplay(
          url: media.url,
          fit: BoxFit.cover,
          placeholder: Container(color: Colors.black12),
        );
      case ContentMediaKind.lottie:
        return LottieDisplay(
          url: media.url,
          errorWidget: const Icon(Icons.broken_image, color: Colors.white30),
        );
      case ContentMediaKind.video:
        return _buildVideoPlayer(media);
      case ContentMediaKind.audio:
        return const Center(
          child: Icon(
            Icons.audiotrack_rounded,
            color: Colors.white38,
            size: 64,
          ),
        );
    }
  }

  Widget _buildVideoPlayer(ContentMedia media) {
    if (_videoController == null || !_videoInitialized) {
      // Show poster image if available
      return Stack(
        fit: StackFit.expand,
        children: [
          if (media.posterUrl != null)
            CachedNetworkImage(imageUrl: media.posterUrl!, fit: BoxFit.cover)
          else
            Container(color: Colors.black38),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (_isVideoPlaying) {
                _videoController!.pause();
                _isVideoPlaying = false;
              } else {
                _videoController!.play();
                _isVideoPlaying = true;
              }
            });
          },
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        if (!_isVideoPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: () {
                  setState(() {
                    _videoController!.play();
                    _isVideoPlaying = true;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
