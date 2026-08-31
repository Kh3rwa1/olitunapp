import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/audio_playback_providers.dart';
import '../../../../shared/models/content_item.dart';

/// Inline video playback embedded inside content detail pages.
class InlineVideoPlayer extends StatefulWidget {
  final ContentMedia media;

  const InlineVideoPlayer({super.key, required this.media});

  @override
  State<InlineVideoPlayer> createState() => InlineVideoPlayerState();
}

class InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.media.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            if (widget.media.posterUrl == null) {
              _controller!.play();
              _isPlaying = true;
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_initialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isPlaying) {
                      _controller!.pause();
                      _isPlaying = false;
                    } else {
                      _controller!.play();
                      _isPlaying = true;
                    }
                  });
                },
                child: VideoPlayer(_controller!),
              ),
              if (!_isPlaying)
                Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller!.play();
                        _isPlaying = true;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Inline audio player adapter
class InlineAudioPlayer extends StatefulWidget {
  final ContentMedia media;
  final String? transcript;
  final bool isDark;

  const InlineAudioPlayer({
    super.key,
    required this.media,
    this.transcript,
    required this.isDark,
  });

  @override
  State<InlineAudioPlayer> createState() => InlineAudioPlayerState();
}

class InlineAudioPlayerState extends State<InlineAudioPlayer> {
  // Simple custom mini audio player routed through the central
  // PlaybackController via playbackControllerProvider.
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filled(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      final playback = ref.read(playbackControllerProvider);
                      if (_isPlaying) {
                        playback.stop();
                        setState(() => _isPlaying = false);
                      } else {
                        playback.playSingle(
                          id: widget.media.url,
                          contentKind: 'lesson',
                          contentId: widget.media.url,
                          trackType: 'instruction',
                          languageCode: 'sat',
                        );
                        setState(() => _isPlaying = true);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPlaying
                              ? 'Playing Audio Pronunciation'
                              : 'Listen to audio instruction',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.media.durationSeconds != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Duration: ${widget.media.durationSeconds}s',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.transcript != null &&
                  widget.transcript!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
                Text(
                  widget.transcript!,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
