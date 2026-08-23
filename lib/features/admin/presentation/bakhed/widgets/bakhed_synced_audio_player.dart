import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../controllers/bakhed_editor_controller.dart';
import 'bakhed_audio_tab.dart' show AdminWaveformPainter;

/// Synced audio playback surface shared by the audio and lyrics tabs.
class BakhedSyncedAudioPlayer extends ConsumerWidget {
  final String bakhedId;
  const BakhedSyncedAudioPlayer({super.key, required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(bakhedAudioPlayerProvider(bakhedId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      initialData: player.playerState,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing ?? false;

        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          initialData: player.duration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: player.positionStream,
              initialData: player.position,
              builder: (context, positionSnapshot) {
                var position = positionSnapshot.data ?? Duration.zero;
                if (position > duration) {
                  position = duration;
                }

                String formatDuration(Duration d) {
                  final minutes = d.inMinutes
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0');
                  final seconds = d.inSeconds
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0');
                  return '$minutes:$seconds';
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: AdminWaveformPainter(
                          color: playing
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            playing
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            if (playing) {
                              player.pause();
                            } else {
                              player.play();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatDuration(position),
                          style: AdminTokens.body(isDark).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: position.inMilliseconds.toDouble(),
                            max: duration.inMilliseconds.toDouble() > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              player.seek(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                        Text(
                          formatDuration(duration),
                          style: AdminTokens.body(isDark).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 3. Lyrics Timeline Editor Tab
// ==========================================
