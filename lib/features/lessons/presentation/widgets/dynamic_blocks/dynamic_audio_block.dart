import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/presentation/animations/scale_button.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../content/presentation/providers/audio_playback_providers.dart';
import '../../../domain/entities/lesson_entity.dart';

class DynamicAudioBlock extends ConsumerWidget {
  const DynamicAudioBlock({
    super.key,
    required this.block,
    required this.isDark,
    required this.accentColor,
  });

  final LessonBlockEntity block;
  final bool isDark;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioUrl = block.audioUrl?.trim();
    if (audioUrl == null || audioUrl.isEmpty) return const SizedBox.shrink();
    final label = block.textLatin?.trim().isNotEmpty == true
        ? block.textLatin!.trim()
        : 'Play audio';

    return ScaleButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        ref
            .read(playbackControllerProvider)
            .playSingle(
              id: audioUrl,
              contentKind: 'lesson',
              contentId: block.textOlChiki ?? block.textLatin ?? block.type,
              trackType: 'instruction',
              languageCode: 'sat',
            );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_fill_rounded, color: accentColor, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
