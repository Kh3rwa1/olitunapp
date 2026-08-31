import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/playback_controller.dart';
import '../../../../shared/providers/language_settings_providers.dart';
import '../../domain/entities/audio_track_entity.dart';
import '../providers/audio_playback_providers.dart';

/// Mode-aware audio controls for a content item (spec §11).
///
/// Offers the pedagogical clip set: Santali (normal), Slow, Meaning
/// (teaching-language clip), Repeat, playback speed, and a progress
/// indicator. All taps route through the central
/// [PlaybackController] — there is exactly one global player, and
/// starting any clip here interrupts whatever was playing elsewhere.
///
/// NEVER autoplays on open: audio only starts from an explicit tap.
///
/// This widget deliberately uses a manual listener + `setState`
/// instead of a StreamProvider over `stateStream`, because the
/// controller emits on every position tick and a provider would
/// rebuild the whole subtree at that rate.
class AudioControlsBar extends ConsumerStatefulWidget {
  final AudioBundle bundle;

  const AudioControlsBar({super.key, required this.bundle});

  @override
  ConsumerState<AudioControlsBar> createState() => _AudioControlsBarState();
}

class _AudioControlsBarState extends ConsumerState<AudioControlsBar> {
  static const List<double> _speedCycle = [1.0, 0.75, 1.25, 1.5];

  PlaybackController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The controller is an app-scoped Provider; bind + listen once.
    final controller = ref.read(playbackControllerProvider);
    if (!identical(_controller, controller)) {
      _controller?.removeListener(_onPlaybackChanged);
      _controller = controller;
      controller.addListener(_onPlaybackChanged);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlaybackChanged);
    _controller = null;
    super.dispose();
  }

  void _onPlaybackChanged(PlaybackState state) {
    if (mounted) setState(() {});
  }

  PlaybackController get _playback => _controller!;

  PlaybackState get _state => _playback.state;

  bool get _isThisItem =>
      _state.isFor(widget.bundle.contentKind, widget.bundle.contentId);

  bool get _hasSantaliAudio => widget.bundle.santaliAudioUrl != null;

  void _playSantali(LessonAudioMode mode) {
    final chain = widget.bundle.playbackChain(mode);
    if (chain == null) return; // Button is disabled in this case.
    _playback.play(chain);
  }

  void _onMainTap(LessonAudioMode mode) {
    if (_isThisItem && !_state.isIdle) {
      _playback.togglePlayPause();
      return;
    }
    _playSantali(mode);
  }

  void _onSlowTap() {
    final url = widget.bundle.slowAudioUrl;
    if (url == null) return;
    _playback.playSingle(
      id: url,
      contentKind: widget.bundle.contentKind,
      contentId: widget.bundle.contentId,
      trackType: TrackType.targetSlow.name,
      languageCode: 'sat',
    );
  }

  void _onMeaningTap() {
    final request = widget.bundle.meaningPlaybackRequest();
    if (request == null) return; // Button is disabled in this case.
    _playback.play(request);
  }

  void _onSpeedTap() {
    final current = _state.speed;
    final index = _speedCycle.indexOf(current);
    final next = _speedCycle[(index + 1) % _speedCycle.length];
    _playback.setSpeed(next);
  }

  String _label(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Watched so a mode change (targetOnly/bilingual/translationOnDemand)
    // re-resolves the chain on the next tap without rebuilding logic here.
    final mode = ref.watch(lessonAudioModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool showProgress = _isThisItem && !_state.isIdle;
    final bool hasSlow = widget.bundle.slowAudioUrl != null;
    final bool hasMeaning = widget.bundle.meaningPlaybackRequest() != null;
    final bool hasSantali = _hasSantaliAudio;

    final icon = _isThisItem && _state.isPlaying
        ? Icons.pause_rounded
        : Icons.volume_up_rounded;
    final mainLabel = _isThisItem && !_state.isIdle
        ? _playback.playPauseSemanticsLabel
        : (hasSantali ? 'Play Santali audio' : 'Audio unavailable');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showProgress) ...[
          Row(
            children: [
              Text(
                _label(_state.position),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: const [],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    height: 26,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: _state.duration > Duration.zero
                            ? _state.position.inMilliseconds
                                  .clamp(0, _state.duration.inMilliseconds)
                                  .toDouble()
                            : 0,
                        max: _state.duration > Duration.zero
                            ? _state.duration.inMilliseconds.toDouble()
                            : 1,
                        onChanged: _state.duration > Duration.zero
                            ? (value) => _playback.seek(
                                Duration(milliseconds: value.round()),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              Text(_label(_state.duration)),
            ],
          ),
        ],
        if (_isThisItem && _state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        Row(
          children: [
            _ControlButton(
              icon: icon,
              tooltip: mainLabel,
              onPressed: hasSantali ? () => _onMainTap(mode) : null,
              highlighted: true,
            ),
            const SizedBox(width: 8),
            _ControlButton(
              icon: Icons.slow_motion_video_rounded,
              tooltip: hasSlow
                  ? 'Play Santali slowly'
                  : 'Slow audio unavailable',
              onPressed: hasSlow ? _onSlowTap : null,
            ),
            const SizedBox(width: 8),
            _ControlButton(
              icon: Icons.translate_rounded,
              tooltip: hasMeaning
                  ? 'Play meaning in ${_teachingLabel(mode)}'
                  : 'Meaning audio unavailable',
              onPressed: hasMeaning ? _onMeaningTap : null,
            ),
            const SizedBox(width: 8),
            _ControlButton(
              icon: Icons.replay_rounded,
              tooltip: _playback.replaySemanticsLabel,
              onPressed: _isThisItem && !_state.isIdle
                  ? _playback.replay
                  : null,
            ),
            const Spacer(),
            _SpeedButton(speed: _state.speed, onTap: _onSpeedTap),
          ],
        ),
      ],
    );
  }

  String _teachingLabel(LessonAudioMode mode) =>
      widget.bundle.teachingLanguage == 'sat'
      ? 'Santali'
      : widget.bundle.teachingLanguage.toUpperCase();
}

/// One round icon button in the bar. Disabled (null [onPressed]) means
/// the clip is genuinely unavailable — spec: missing tracks are shown
/// as unavailable, never played as silence.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool highlighted;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        enabled: onPressed != null,
        child: IconButton(
          icon: Icon(icon),
          color: highlighted ? colorScheme.primary : colorScheme.onSurface,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: highlighted
                ? colorScheme.primary.withValues(alpha: 0.12)
                : null,
            disabledBackgroundColor: colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: highlighted
                  ? BorderSide(color: colorScheme.primary)
                  : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cycles playback speed between 1.0× → 0.75× → 1.25× → 1.5×.
class _SpeedButton extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const _SpeedButton({required this.speed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Playback speed ${speed}x',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(
            '${speed.toStringAsFixed(speed == 0.75 || speed == 1.25 ? 2 : 1)}×',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
