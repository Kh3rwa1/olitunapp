import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/media/authorized_media.dart';
import '../../core/media/authorized_media_provider.dart';

/// Private media uses the native Storage URL, never a JSON/base64/data URI.
/// Appwrite handles byte ranges; this widget renews the lease before expiry.
class AuthorizedMediaDisplay extends ConsumerStatefulWidget {
  const AuthorizedMediaDisplay({
    super.key,
    required this.source,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.autoplay = true,
    this.loop = true,
    this.muted = true,
  });

  final String source;
  final Widget fallback;
  final BoxFit fit;
  final bool autoplay;
  final bool loop;
  final bool muted;

  @override
  ConsumerState<AuthorizedMediaDisplay> createState() =>
      _AuthorizedMediaDisplayState();
}

class _AuthorizedMediaDisplayState extends ConsumerState<AuthorizedMediaDisplay>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  MediaLease? _lease;
  Timer? _refresh;
  int _generation = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load(preserve: false));
  }

  @override
  void didUpdateWidget(covariant AuthorizedMediaDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      unawaited(_load(preserve: false));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }

  Future<void> _load({bool preserve = true}) async {
    final generation = ++_generation;
    _refresh?.cancel();
    final old = _controller;
    final position = preserve ? old?.value.position : null;
    final playing = preserve ? old?.value.isPlaying : null;
    final volume = preserve ? old?.value.volume : null;
    final speed = preserve ? old?.value.playbackSpeed : null;
    _controller = null;
    if (mounted)
      setState(() {
        _lease = null;
        _failed = false;
      });
    VideoPlayerController? candidate;
    try {
      await old?.dispose();
      if (!mounted || generation != _generation) return;
      final service = ref.read(authorizedMediaServiceProvider);
      final lease = await service.resolve(widget.source);
      if (!mounted || generation != _generation) return;
      if (lease.mimeType?.startsWith('video/') ?? false) {
        candidate = VideoPlayerController.networkUrl(lease.uri);
        await candidate.initialize();
        if (!mounted || generation != _generation) {
          await candidate.dispose();
          return;
        }
        await candidate.setLooping(widget.loop);
        await candidate.setVolume(volume ?? (widget.muted ? 0.0 : 1.0));
        if (speed != null) await candidate.setPlaybackSpeed(speed);
        if (position != null) await candidate.seekTo(position);
        if (playing ?? widget.autoplay) await candidate.play();
        if (!mounted || generation != _generation) {
          await candidate.dispose();
          return;
        }
        _controller = candidate;
        candidate.addListener(_checkPlayerError);
      } else if (!(lease.mimeType?.startsWith('image/') ?? false) &&
          lease.mimeType != 'application/json') {
        throw const MediaAccessException();
      }
      final delay = lease.refreshAfter(service.clock());
      if (delay == null || delay <= Duration.zero) {
        throw const MediaAccessException();
      }
      _refresh = Timer(delay, () => unawaited(_load()));
      if (mounted) setState(() => _lease = lease);
    } catch (_) {
      try {
        await candidate?.dispose();
      } catch (_) {}
      if (mounted && generation == _generation) {
        _controller = null;
        _refresh?.cancel();
        setState(() {
          _lease = null;
          _failed = true;
        });
      }
    }
  }

  void _checkPlayerError() {
    if (!(_controller?.value.hasError ?? false) || _failed) return;
    // Do not log errorDescription: it can include the token URL. A user retry
    // obtains a fresh grant; never loop on 401/403 or play stale cached content.
    _refresh?.cancel();
    final controller = _controller;
    _controller = null;
    unawaited(controller?.dispose());
    if (mounted)
      setState(() {
        _failed = true;
        _lease = null;
      });
  }

  @override
  void dispose() {
    _generation++;
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authorizedMediaServiceProvider, (_, _) {
      // Logout/account changes invalidate the player as well as the lease.
      unawaited(_load(preserve: false));
    });
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.fallback,
            IconButton(
              tooltip: 'Retry media',
              onPressed: () => unawaited(_load(preserve: false)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }
    final lease = _lease;
    if (lease == null) return const Center(child: CircularProgressIndicator());
    final controller = _controller;
    if (controller == null) {
      if (lease.mimeType == 'image/svg+xml') {
        return SvgPicture.network(
          lease.uri.toString(),
          fit: widget.fit,
          errorBuilder: (_, _, _) => _retryView(),
        );
      }
      if (lease.mimeType == 'application/json') {
        return Lottie.network(
          lease.uri.toString(),
          fit: widget.fit,
          errorBuilder: (_, _, _) => _retryView(),
        );
      }
      return Image.network(
        lease.uri.toString(),
        fit: widget.fit,
        errorBuilder: (_, _, _) => _retryView(),
      );
    }
    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          unawaited(controller.pause());
        } else {
          // Resume after a long pause always rechecks entitlement.
          unawaited(_resume());
        }
      },
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

  Widget _retryView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.fallback,
        IconButton(
          tooltip: 'Retry media',
          onPressed: () => unawaited(_load(preserve: false)),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
  );

  Future<void> _resume() async {
    final generation = _generation + 1;
    await _load();
    if (mounted && generation == _generation && !_failed) {
      await _controller?.play();
    }
  }
}
