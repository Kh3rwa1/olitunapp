part of 'ai_studio_screen.dart';

extension _AiStudioStatus on _AiStudioScreenState {
  // ── Realtime Status ──────────────────────────────────────────────────
  _LiveState _liveState(bool configured) {
    if (_recording) return _LiveState.listening;
    if (_draft.busy) return _LiveState.thinking;
    if (configured && _draft.auto && _validInput) {
      return _LiveState.live;
    }
    if (_draft.result.text.trim().isNotEmpty) return _LiveState.ready;
    return _LiveState.idle;
  }

  /// The pulse animation only runs while recording or thinking so idle
  /// frames (and widget-test pumps) always settle.
  void _syncPulse() {
    final active = _recording || _drafts.values.any((draft) => draft.busy);
    if (active && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!active && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  Widget _pulseDot(Color color, {required bool animate}) {
    if (!animate) {
      return Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) {
        final wave = math.sin(_pulse.value * 2 * math.pi);
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

  Widget _statusBadge(AppLocalizations l10n, bool configured) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = _liveState(configured);
    final (label, color, animate) = switch (state) {
      _LiveState.listening => (
        '00:${_recordingSeconds.toString().padLeft(2, '0')}',
        AppColors.studioRecordingRed,
        true,
      ),
      _LiveState.thinking => (
        l10n.aiStudioThinking.toUpperCase(),
        AppColors.amberEmber,
        true,
      ),
      _LiveState.live => (
        l10n.aiStudioLive.toUpperCase(),
        AppColors.primary,
        false,
      ),
      _LiveState.ready => ('READY', AppColors.primary, false),
      _LiveState.idle => (
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
            _pulseDot(color, animate: animate),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: state == _LiveState.idle
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

  Widget _waveform() {
    return Semantics(
      label: 'Recording audio levels',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) {
          final t = _pulse.value * 2 * math.pi;
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

  Widget _autoPill(_Draft draft, bool isDark) {
    final on = draft.auto;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('studio-auto'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _setState(() => draft.auto = !draft.auto);
          if (draft.auto) _maybeAutoRun();
        },
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
