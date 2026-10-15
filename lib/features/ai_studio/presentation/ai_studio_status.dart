import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'ai_studio_session.dart';

/// Status dot; pulses with [pulse] when [animate] is set.
class StudioPulseDot extends StatelessWidget {
  const StudioPulseDot({
    super.key,
    required this.color,
    required this.animate,
    required this.pulse,
  });

  final Color color;
  final bool animate;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
    }
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, _) {
        final wave = math.sin(pulse.value * 2 * math.pi);
        return Container(
          width: 5 + 2.5 * (0.5 + 0.5 * wave),
          height: 5 + 2.5 * (0.5 + 0.5 * wave),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.55 + 0.45 * wave),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6 + 4 * wave,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Live-region badge describing the realtime [state].
class StudioStatusBadge extends StatelessWidget {
  const StudioStatusBadge({
    super.key,
    required this.state,
    required this.recordingSeconds,
    required this.pulse,
  });

  final StudioLiveState state;
  final int recordingSeconds;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color, animate) = switch (state) {
      StudioLiveState.listening => (
        '00:${recordingSeconds.toString().padLeft(2, '0')}',
        AppColors.studioRecordingRed,
        true,
      ),
      StudioLiveState.thinking => (
        l10n.aiStudioThinking.toUpperCase(),
        AppColors.amberEmber,
        true,
      ),
      StudioLiveState.live => (
        l10n.aiStudioLive.toUpperCase(),
        AppColors.primary,
        false,
      ),
      StudioLiveState.ready => ('READY', AppColors.primary, false),
      StudioLiveState.idle => (
        'IDLE',
        isDark ? Colors.white54 : Colors.black45,
        false,
      ),
    };
    return Semantics(
      liveRegion: true,
      label: 'AI Studio status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudioPulseDot(color: color, animate: animate, pulse: pulse),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: state == StudioLiveState.idle
                    ? (isDark ? Colors.white54 : Colors.black45)
                    : color,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated recording level bars driven by [pulse].
class StudioWaveform extends StatelessWidget {
  const StudioWaveform({super.key, required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Recording audio levels',
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, _) {
          final t = pulse.value * 2 * math.pi;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 28; i++)
                Container(
                  width: 3,
                  height: 5 + 15 * (0.5 + 0.5 * math.sin(t * 2 + i * 0.65)),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color:
                        (i % 4 == 0
                                ? AppColors.studioRecordingRed
                                : AppColors.primary)
                            .withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Toggle for realtime automation ("Auto").
class StudioAutoPill extends StatelessWidget {
  const StudioAutoPill({super.key, required this.on, required this.onToggle});

  final bool on;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('studio-auto'),
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: on
                ? AppColors.primary.withValues(alpha: 0.14)
                : (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: on
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                on ? Icons.bolt_rounded : Icons.bolt_outlined,
                size: 15,
                color: on
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(width: 5),
              Text(
                AppLocalizations.of(context)!.aiStudioAuto,
                style: TextStyle(
                  color: on
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
