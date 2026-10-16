import 'package:flutter/material.dart';

import '../../../core/ads/widgets/fill_space_native_ad.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/ai_spark_assistant.dart';
import '../data/ai_studio_service.dart';
import 'ai_studio_input_tools.dart';
import 'ai_studio_layout.dart';
import 'ai_studio_session.dart';
import 'ai_studio_status.dart';

/// Input side of the studio: language picker, the active tool's form, and
/// the auto / process footer. All mutations go through callbacks.
class StudioInputPanel extends StatelessWidget {
  const StudioInputPanel({
    super.key,
    required this.tool,
    required this.draft,
    required this.source,
    required this.configured,
    required this.validInput,
    required this.recording,
    required this.recordingSeconds,
    required this.pulse,
    required this.flex,
    required this.isMobile,
    required this.onLanguageChanged,
    required this.onProcess,
    required this.onToggleAuto,
    required this.onRestoreSpark,
    required this.onToggleRecording,
    required this.onPick,
    required this.onSourceChanged,
    this.showAd = true,
  });

  final StudioTool tool;
  final StudioDraft draft;
  final TextEditingController source;
  final bool configured;
  final bool validInput;
  final bool recording;
  final int recordingSeconds;
  final Animation<double> pulse;
  final bool flex;
  final bool isMobile;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onProcess;
  final VoidCallback onToggleAuto;
  final VoidCallback onRestoreSpark;
  final VoidCallback onToggleRecording;

  /// Called with `camera: true` for page capture.
  final void Function(bool camera) onPick;
  final VoidCallback onSourceChanged;

  /// Native ad in the panel's blank space (off while the processing overlay
  /// shows its own, so ads never stack).
  final bool showAd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locked = draft.busy || draft.selecting || recording;
    final scanPending =
        tool == StudioTool.scan && draft.job != null && !draft.job!.isTerminal;
    final languages = studioLanguages.entries.where(
      (entry) => tool != StudioTool.translate || entry.key != 'sat-IN',
    );
    final panelTitle = switch (tool) {
      StudioTool.translate => l10n.aiStudioYourText,
      StudioTool.transcribe => l10n.aiStudioYourAudio,
      StudioTool.scan => l10n.aiStudioYourDocument,
    };

    final header = LayoutBuilder(
      builder: (context, headerConstraints) {
        final compact =
            headerConstraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(16) > 20;

        final titleWidget = Semantics(
          header: true,
          child: Text(
            panelTitle,
            style: AppTypography.inter(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );

        final dropdownWidget = SizedBox(
          width: compact ? double.infinity : (isMobile ? 136 : 154),
          height: 36,
          child: DropdownButtonFormField<String>(
            key: ValueKey('language-${tool.name}-${draft.language}'),
            initialValue: draft.language,
            isExpanded: true,
            dropdownColor: isDark ? AppColors.studioDropdownDark : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              filled: true,
              fillColor: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.04,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            items: [
              for (final entry in languages)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: locked || scanPending
                ? null
                : (value) {
                    if (value != null) onLanguageChanged(value);
                  },
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [titleWidget, const SizedBox(height: 6), dropdownWidget],
          );
        }

        return Row(
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 8),
            dropdownWidget,
          ],
        );
      },
    );

    Widget body;
    if (tool == StudioTool.translate) {
      body = StudioTranslateInput(
        controller: source,
        enabled: !locked,
        canSubmit: configured && !locked && validInput,
        isMobile: isMobile,
        onSubmit: onProcess,
        onChanged: onSourceChanged,
      );
    } else if (tool == StudioTool.transcribe) {
      body = StudioTranscribeInput(
        draft: draft,
        locked: locked,
        recording: recording,
        recordingSeconds: recordingSeconds,
        pulse: pulse,
        isMobile: isMobile,
        onToggleRecording: onToggleRecording,
        onPick: () => onPick(false),
      );
    } else {
      body = StudioScanInput(
        draft: draft,
        enabled: !(locked || scanPending),
        isMobile: isMobile,
        onPick: onPick,
      );
    }

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (draft.error != null) ...[
          StudioNotice(
            draft.error!,
            error: true,
            icon: Icons.error_outline_rounded,
          ),
          const SizedBox(height: 8),
        ],
        if (draft.busy) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              semanticsLabel: 'AI processing in progress',
              color: AppColors.primary,
              backgroundColor: AppColors.studioProgressBg,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: AiSparkAssistant(
              statusText: l10n.aiStudioThinking,
              subheadText: 'Tap to view full screen spark ✨',
              compact: true,
              size: 28,
              onTap: onRestoreSpark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!scanPending) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              StudioAutoPill(on: draft.auto, onToggle: onToggleAuto),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('studio-process'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.elevatedButtonFg,
                    disabledBackgroundColor:
                        (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.06,
                        ),
                    disabledForegroundColor: isDark
                        ? Colors.white24
                        : Colors.black26,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: configured && !locked && validInput
                      ? onProcess
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tool.icon, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          draft.busy
                              ? l10n.aiStudioProcessing
                              : l10n.aiStudioProcessWithAi(
                                  tool.localizedLabel(l10n),
                                ),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: isMobile ? 13 : 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return StudioCard(
      header: header,
      body: body,
      footer: footer,
      filler: showAd
          ? const FillSpaceNativeAd(placement: 'ai_studio_input')
          : null,
      flex: flex,
      isMobile: isMobile,
    );
  }
}

/// Tool 1: record or upload audio for transcription.
class StudioTranscribeInput extends StatelessWidget {
  const StudioTranscribeInput({
    super.key,
    required this.draft,
    required this.locked,
    required this.recording,
    required this.recordingSeconds,
    required this.pulse,
    required this.isMobile,
    required this.onToggleRecording,
    required this.onPick,
  });

  final StudioDraft draft;
  final bool locked;
  final bool recording;
  final int recordingSeconds;
  final Animation<double> pulse;
  final bool isMobile;
  final VoidCallback onToggleRecording;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 16 : 22,
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.03,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: recording
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.06,
                    ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: draft.busy || draft.selecting ? null : onToggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isMobile ? 64 : 70,
                  height: isMobile ? 64 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recording
                        ? AppColors.studioRecordingRed
                        : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (recording
                                    ? AppColors.studioRecordingRed
                                    : AppColors.primary)
                                .withValues(alpha: 0.35),
                        blurRadius: recording ? 20 : 12,
                        spreadRadius: recording ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    recording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: isMobile ? 28 : 32,
                    color: recording
                        ? Colors.white
                        : AppColors.elevatedButtonFg,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 10 : 14),
              FilledButton.tonal(
                key: const Key('studio-record'),
                style: FilledButton.styleFrom(
                  backgroundColor: recording
                      ? AppColors.studioRecordingRed.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: recording
                      ? AppColors.studioRecordingRed
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: draft.busy || draft.selecting
                    ? null
                    : onToggleRecording,
                child: Text(
                  recording
                      ? l10n.aiStudioStopRecording(
                          recordingSeconds.toString().padLeft(2, '0'),
                        )
                      : l10n.aiStudioRecordVoice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (recording) ...[
                const SizedBox(height: 10),
                StudioWaveform(pulse: pulse),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.aiStudioListening,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 14),
        if (draft.input != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.audiotrack_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    draft.input!.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('studio-pick'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black87,
              side: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.12,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: locked ? null : onPick,
            icon: const Icon(Icons.upload_file_outlined, size: 15),
            label: Text(
              draft.selecting
                  ? l10n.aiStudioOpening
                  : draft.input == null
                  ? l10n.aiStudioUploadWav
                  : l10n.aiStudioReplaceRecording,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
