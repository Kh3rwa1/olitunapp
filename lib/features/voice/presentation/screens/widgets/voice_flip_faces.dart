import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/audio/playback_controller.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/santali_voice_providers.dart';
import 'mini_bars.dart';

/// Flip FRONT: small text box with a return path to the player.
class VoiceInputFace extends StatelessWidget {
  const VoiceInputFace({
    super.key,
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.glowKey,
    required this.maxChars,
    required this.hasClip,
    required this.onFlipToBack,
    required this.onClear,
    required this.onTextChanged,
    this.onSubmit,
  });

  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey<FocusGlowFieldState> glowKey;
  final int maxChars;
  final bool hasClip;
  final VoidCallback onFlipToBack;
  final VoidCallback onClear;
  final VoidCallback onTextChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FocusGlowField(
      key: glowKey,
      focusNode: focusNode,
      borderRadius: 20,
      glowColor: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.1,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    control: true,
                  ): () {
                    if (onSubmit != null && controller.text.trim().isNotEmpty) {
                      onSubmit!();
                    }
                  },
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    meta: true,
                  ): () {
                    if (onSubmit != null && controller.text.trim().isNotEmpty) {
                      onSubmit!();
                    }
                  },
                },
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLength: maxChars,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => onTextChanged(),
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: l10n.voiceInputHint,
                    hintStyle: AppTypography.inter(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.3,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                // Return path to the player after X/edit brought us back
                // to the text.
                if (hasClip) ...[
                  GestureDetector(
                    onTap: onFlipToBack,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.graphic_eq_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.voicePlayerTab,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                const Spacer(),
                if (kIsWeb ||
                    defaultTargetPlatform == TargetPlatform.macOS ||
                    defaultTargetPlatform == TargetPlatform.windows ||
                    defaultTargetPlatform == TargetPlatform.linux) ...[
                  Text(
                    'Ctrl+Enter ↵ to create',
                    style: AppTypography.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => Text(
                    '${value.text.trim().length} / $maxChars',
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Flip BACK: player driven by the central [PlaybackController] — the same
/// engine behind every lesson surface (one global player, speed, seek,
/// loading/error states).
class VoicePlayerFace extends StatelessWidget {
  const VoicePlayerFace({
    super.key,
    required this.isDark,
    required this.clip,
    required this.player,
    required this.isLoading,
    required this.isDownloading,
    required this.onPlayTap,
    required this.onSeek,
    required this.onSpeedTap,
    required this.onDownload,
    required this.onRegenerate,
    required this.onEdit,
    required this.onDismiss,
  });

  final bool isDark;
  final VoiceClip? clip;
  final PlaybackController player;
  final bool isLoading;
  final bool isDownloading;
  final VoidCallback onPlayTap;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSpeedTap;
  final VoidCallback onDownload;
  final VoidCallback onRegenerate;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeClip = clip;
    if (activeClip == null || isLoading) {
      // Shown immediately after CREATE VOICE is tapped (the card flips
      // first, Bodhan renders second) and before the first generation.
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.voicePurple, AppColors.voiceTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MiniBars(barCount: 12, height: 24, light: true),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                isLoading ? l10n.voiceCreatingBack : l10n.voiceEmptyBack,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final state = player.state;
    final clipId = activeClip.storageFileId ?? activeClip.audioUrl;
    final mine = state.isFor('voice', clipId);
    final playing = mine && state.isPlaying;
    final loading = mine && state.isLoading;
    final styleLabel = activeClip.style.isEmpty
        ? 'Neutral'
        : voiceStyles
              .firstWhere(
                (s) => s.apiValue == activeClip.style,
                orElse: () => neutralStyle,
              )
              .label;
    final total = mine ? state.duration : Duration.zero;
    final pos = mine ? state.position : Duration.zero;
    final value = total > Duration.zero
        ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.voicePurple, AppColors.voiceTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.violetGlow,
            blurRadius: 24,
            offset: Offset(0, 10),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${activeClip.voice} • $styleLabel${activeClip.cached ? ' • instant' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _FaceIcon(
                icon: Icons.edit_rounded,
                tooltip: l10n.voiceEditText,
                onTap: onEdit,
              ),
              _FaceIcon(
                icon: Icons.close_rounded,
                tooltip: l10n.voiceDismiss,
                onTap: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Semantics(
                  label: player.playPauseSemanticsLabel,
                  button: true,
                  child: PressableScale(
                    onTap: loading ? null : onPlayTap,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                color: AppColors.indigoVivid,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppColors.indigoVivid,
                              size: 28,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MiniBars(
                        barCount: 14,
                        height: 16,
                        animate: playing,
                        light: true,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDuration(pos),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10,
                                ),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: value,
                                onChanged: total > Duration.zero
                                    ? (v) => onSeek(
                                        Duration(
                                          milliseconds:
                                              (v * total.inMilliseconds)
                                                  .round(),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(total),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _FaceChip(
                label:
                    '${state.speed.toStringAsFixed(state.speed == 0.75 || state.speed == 1.25 ? 2 : 1)}×',
                tooltip: l10n.voicePlaybackSpeed,
                onTap: onSpeedTap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FaceChip(
                  label: isDownloading ? l10n.voiceSaving : l10n.voiceDownload,
                  tooltip: l10n.voiceDownload,
                  icon: isDownloading ? null : Icons.download_rounded,
                  onTap: onDownload,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FaceChip(
                  label: l10n.voiceRegenerate,
                  tooltip: l10n.voiceRegenerate,
                  icon: Icons.refresh_rounded,
                  onTap: onRegenerate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaceIcon extends StatelessWidget {
  const _FaceIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: PressableScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _FaceChip extends StatelessWidget {
  const _FaceChip({
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 15),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
