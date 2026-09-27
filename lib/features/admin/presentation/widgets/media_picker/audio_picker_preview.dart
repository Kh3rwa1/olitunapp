import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/models/content_item.dart';

/// Interactive preview card for audio tracks in admin media pickers.
/// Displays audio playback controls, file label, and play state.
class AudioPickerPreview extends ConsumerStatefulWidget {
  final ContentMedia media;
  final bool isDark;

  const AudioPickerPreview({
    super.key,
    required this.media,
    required this.isDark,
  });

  @override
  ConsumerState<AudioPickerPreview> createState() => _AudioPickerPreviewState();
}

class _AudioPickerPreviewState extends ConsumerState<AudioPickerPreview> {
  bool _isPlaying = false;
  StreamSubscription<bool>? _playSub;

  @override
  void initState() {
    super.initState();
    _playSub = ref.read(audioServiceProvider).isPlayingStream.listen((playing) {
      if (mounted) {
        final currentUrl = ref.read(audioServiceProvider).currentUrl;
        final isThisPlaying = playing && currentUrl == widget.media.url;
        if (_isPlaying != isThisPlaying) {
          setState(() => _isPlaying = isThisPlaying);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant AudioPickerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.media.url != oldWidget.media.url) {
      if (_isPlaying) {
        ref.read(audioServiceProvider).stop();
        _isPlaying = false;
      }
    }
  }

  @override
  void dispose() {
    _playSub?.cancel();
    if (_isPlaying) {
      ref.read(audioServiceProvider).stop();
    }
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final audio = ref.read(audioServiceProvider);
    if (_isPlaying) {
      await audio.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (widget.media.url.trim().isEmpty) return;
      setState(() => _isPlaying = true);
      final ok = await audio.tryPlayUrl(
        widget.media.url,
        title: 'Pronunciation Preview',
      );
      if (!ok && mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  String _resolveLabel() {
    if (widget.media.fileId.trim().isNotEmpty) {
      return widget.media.fileId.trim();
    }
    final uri = Uri.tryParse(widget.media.url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return 'Pronunciation Track';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final trackLabel = _resolveLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPlaying
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: _isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _togglePlayback,
            icon: Icon(
              _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 26,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  _isPlaying ? Colors.redAccent : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
            tooltip: _isPlaying ? 'Stop preview' : 'Play audio preview',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.audiotrack_rounded,
                      size: 16,
                      color: _isPlaying
                          ? AppColors.primary
                          : (isDark ? Colors.amber[300] : Colors.amber[800]),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        trackLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isPlaying
                      ? 'Playing pronunciation audio...'
                      : 'Audio track ready · Tap to test playback',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isPlaying
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'AUDIO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
