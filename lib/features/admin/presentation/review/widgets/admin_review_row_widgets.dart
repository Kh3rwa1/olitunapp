part of '../admin_review_screen.dart';

// Queue row widgets for the admin review screen.

class _ReviewCard extends StatelessWidget {
  final bool selected;
  final bool isDark;
  final VoidCallback? onToggleSelect;
  final Widget leading;
  final String title;
  final Widget subtitle;
  final Widget trailing;

  const _ReviewCard({
    required this.selected,
    required this.isDark,
    this.onToggleSelect,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleSelect,
      borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminTokens.raised(isDark),
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.6)
                : AdminTokens.border(isDark),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: AdminTokens.raisedShadow(isDark),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AdminTokens.textPrimary(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  subtitle,
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _AudioTrackMeta extends StatelessWidget {
  final AdminAudioTrackRow track;
  final bool isDark;

  const _AudioTrackMeta({required this.track, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _MetaBadge(
          label: track.languageCode,
          icon: Icons.language_rounded,
          color: Colors.blue,
          isDark: isDark,
        ),
        _MetaBadge(
          label: track.trackType,
          icon: Icons.waves_rounded,
          color: Colors.deepPurple,
          isDark: isDark,
        ),
        if (track.isHumanRecorded)
          _MetaBadge(
            label: 'Human',
            icon: Icons.mic_rounded,
            color: Colors.green,
            isDark: isDark,
          )
        else
          _MetaBadge(
            label: 'Gen: ${track.generationStatus ?? 'unknown'}',
            icon: Icons.smart_toy_rounded,
            color: _generationColor(track.generationStatus),
            isDark: isDark,
          ),
        if (track.errorMessage != null)
          _MetaBadge(
            label: track.errorMessage!,
            icon: Icons.error_outline_rounded,
            color: Colors.red,
            isDark: isDark,
          ),
      ],
    );
  }

  Color _generationColor(String? status) {
    if (status == 'completed') return Colors.green;
    if (status == 'failed') return Colors.red;
    if (status == 'queued' || status == 'processing') return Colors.orange;
    return Colors.grey;
  }
}

class _LocalizedMeta extends StatelessWidget {
  final AdminLocalizedContentRow row;
  final bool isDark;

  const _LocalizedMeta({required this.row, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (row.meaning != null) 'Meaning: ${row.meaning!}',
      if (row.explanation != null) 'Explanation: ${row.explanation!}',
    ];
    return Text(
      parts.isEmpty ? '—' : parts.join('  ·  '),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: AdminTokens.textSecondary(isDark),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetaBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark
                ? color.withValues(alpha: 0.85)
                : color.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? color.withValues(alpha: 0.85)
                  : color.withValues(alpha: 0.9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PreviewButton extends ConsumerStatefulWidget {
  final String audioUrl;

  const _PreviewButton({required this.audioUrl});

  @override
  ConsumerState<_PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends ConsumerState<_PreviewButton> {
  bool _playing = false;

  Future<void> _toggle() async {
    final audio = ref.read(audioServiceProvider);
    if (_playing) {
      await audio.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final ok = await audio.tryPlayUrl(widget.audioUrl);
    if (!mounted) return;
    setState(() => _playing = ok);
    if (ok) {
      // Update the button when playback finishes naturally.
      audio.isPlayingStream.listen((playing) {
        if (!playing && mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  void dispose() {
    if (_playing) {
      ref.read(audioServiceProvider).stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _playing ? 'Pause preview' : 'Play preview',
      icon: Icon(
        _playing ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
        size: 22,
        color: AppColors.primary,
      ),
      onPressed: _toggle,
    );
  }
}

class _DecisionButtons extends StatelessWidget {
  final bool isDark;
  final bool canDecide;
  final bool approveEnabled;
  final String? approveTooltip;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _DecisionButtons({
    required this.isDark,
    required this.canDecide,
    required this.approveEnabled,
    this.approveTooltip,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (!canDecide) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: approveTooltip ?? 'Approve',
          child: IconButton(
            icon: Icon(
              Icons.check_circle_outline_rounded,
              size: 21,
              color: approveEnabled
                  ? Colors.green
                  : (isDark ? Colors.white24 : Colors.black12),
            ),
            onPressed: approveEnabled ? onApprove : null,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.cancel_outlined,
            size: 21,
            color: AppColors.error,
          ),
          onPressed: onReject,
          tooltip: 'Reject',
        ),
      ],
    );
  }
}
