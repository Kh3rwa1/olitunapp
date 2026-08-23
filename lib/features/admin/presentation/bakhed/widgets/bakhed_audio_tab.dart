import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../shared/providers/providers.dart';
import '../controllers/bakhed_editor_controller.dart';

import '../../widgets/media_picker_field.dart';
import 'bakhed_synced_audio_player.dart';

/// Audio tab of the Bakhed editor with waveform visualisation.
class BakhedAudioTab extends ConsumerWidget {
  final String bakhedId;
  const BakhedAudioTab({super.key, required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = ref.watch(
      bakhedEditorControllerProvider(bakhedId).select((s) => s.item.value),
    );
    if (item == null) return const SizedBox();

    final notifier = ref.read(
      bakhedEditorControllerProvider(bakhedId).notifier,
    );
    final hasAudio = item.audioUrl != null && item.audioUrl!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Card(
          color: AdminTokens.raised(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
            side: BorderSide(color: AdminTokens.border(isDark)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rhyme Audio Track',
                  style: AdminTokens.sectionTitle(isDark),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload an MP3 play-along audio file. This will enable synchronized scrolling lyrics and word-by-word reading highlighting in the learner interface.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                MediaPickerField(
                  label: 'Audio File (MP3)',
                  kind: ContentMediaKind.audio,
                  value: item.audioUrl != null && item.audioUrl!.isNotEmpty
                      ? ContentMedia(
                          url: item.audioUrl!,
                          fileId: item.audioFileId ?? '',
                          kind: ContentMediaKind.audio,
                        )
                      : null,
                  onUploadStateChanged: notifier.setUploadInProgress,
                  onRemove: notifier.markForDeletion,
                  onChanged: (media) {
                    notifier.updateAudio(
                      media?.url,
                      media?.fileId,
                      media?.durationMs ??
                          (media?.durationSeconds != null
                              ? media!.durationSeconds! * 1000
                              : null),
                    );
                    if (media?.url != null && media!.url.isNotEmpty) {
                      ref
                          .read(bakhedAudioPlayerProvider(bakhedId))
                          .setUrl(media.url)
                          .catchError((_) => null);
                    }
                  },
                ),

                if (hasAudio) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    'Audio Playback Preview',
                    style: AdminTokens.sectionTitle(isDark),
                  ),
                  const SizedBox(height: 16),
                  BakhedSyncedAudioPlayer(bakhedId: bakhedId),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AdminWaveformPainter extends CustomPainter {
  final Color color;
  AdminWaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    const int bars = 40;
    final double spacing = width / bars;

    final heights = [
      0.3,
      0.4,
      0.6,
      0.8,
      0.5,
      0.3,
      0.4,
      0.7,
      0.9,
      0.6,
      0.4,
      0.3,
      0.5,
      0.8,
      0.7,
      0.5,
      0.4,
      0.6,
      0.8,
      0.5,
      0.3,
      0.4,
      0.6,
      0.8,
      0.5,
      0.3,
      0.4,
      0.7,
      0.9,
      0.6,
      0.4,
      0.3,
      0.5,
      0.8,
      0.7,
      0.5,
      0.4,
      0.6,
      0.8,
      0.5,
    ];

    for (int i = 0; i < bars; i++) {
      final double x = i * spacing;
      final double barHeight = height * heights[i % heights.length];
      final double yStart = (height - barHeight) / 2;
      final double yEnd = yStart + barHeight;
      canvas.drawLine(Offset(x, yStart), Offset(x, yEnd), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
