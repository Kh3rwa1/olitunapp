import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/santali_voice_providers.dart';

/// Small caps section label.
class MiniSectionLabel extends StatelessWidget {
  const MiniSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.inter(
        color: AppColors.primary,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }
}

/// Single-line horizontal sample phrase chips.
class SampleChips extends StatelessWidget {
  const SampleChips({
    super.key,
    required this.isDark,
    required this.samples,
    required this.onPick,
  });

  final bool isDark;
  final List<String> samples;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < samples.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            PressableScale(
              onTap: () {
                HapticFeedback.lightImpact();
                onPick(samples[i]);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.16 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  samples[i].length > 20
                      ? '${samples[i].substring(0, 20)}…'
                      : samples[i],
                  style: const TextStyle(
                    fontFamily: 'OlChiki',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Voice pills — Phulmani / Sibu only.
class VoicePillSelector extends ConsumerWidget {
  const VoicePillSelector({
    super.key,
    required this.isDark,
    required this.selected,
    this.stacked = false,
  });

  final bool isDark;
  final String selected;
  final bool stacked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MiniSectionLabel(l10n.voicePickerHeader),
        const SizedBox(height: 6),
        if (stacked)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < santaliVoices.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _VoicePill(
                  isDark: isDark,
                  voice: santaliVoices[i],
                  selected: selected,
                  onSelect: (name) =>
                      ref.read(santaliVoiceNameProvider.notifier).select(name),
                ),
              ],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < santaliVoices.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _VoicePill(
                    isDark: isDark,
                    voice: santaliVoices[i],
                    selected: selected,
                    onSelect: (name) => ref
                        .read(santaliVoiceNameProvider.notifier)
                        .select(name),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _VoicePill extends StatelessWidget {
  const _VoicePill({
    required this.isDark,
    required this.voice,
    required this.selected,
    required this.onSelect,
  });

  final bool isDark;
  final BodhanVoice voice;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == voice.name;
    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelect(voice.name);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.accentPurpleDark, AppColors.indigoVivid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.35)
                : (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.12,
                  ),
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.violetGlow,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              voice.isFemale ? Icons.face_3_rounded : Icons.face_rounded,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${voice.name} • ${voice.genderLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// Style picker — horizontal rail on mobile, wrap grid on desktop.
class StyleRailSelector extends ConsumerWidget {
  const StyleRailSelector({
    super.key,
    required this.isDark,
    required this.selected,
    this.grid = false,
  });

  final bool isDark;
  final String selected;
  final bool grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = [
      for (var i = 0; i < voiceStyles.length; i++)
        _StyleChip(
          isDark: isDark,
          style: voiceStyles[i],
          selected: selected,
          onSelect: (value) =>
              ref.read(santaliVoiceStyleProvider.notifier).select(value),
        ),
    ];
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MiniSectionLabel(l10n.voiceStyleHeader),
        const SizedBox(height: 6),
        if (grid)
          Wrap(spacing: 8, runSpacing: 8, children: chips)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  chips[i],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.isDark,
    required this.style,
    required this.selected,
    required this.onSelect,
  });

  final bool isDark;
  final VoiceStyle style;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == style.apiValue;
    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelect(style.apiValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.accentPurpleDark, AppColors.indigoVivid],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.14,
                  ),
          ),
        ),
        child: Text(
          style.label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
