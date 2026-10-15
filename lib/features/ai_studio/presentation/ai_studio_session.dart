import 'package:flutter/material.dart';

import '../../../core/sharing/growth_share_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/ai_studio_service.dart';

/// The three AI Studio tools. Each owns its own [StudioDraft].
enum StudioTool {
  transcribe('Transcribe', Icons.graphic_eq_rounded),
  translate('Translate', Icons.translate_rounded),
  scan('Scan', Icons.document_scanner_outlined);

  const StudioTool(this.label, this.icon);
  final String label;
  final IconData icon;

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    StudioTool.transcribe => l10n.aiStudioToolTranscribe,
    StudioTool.translate => l10n.aiStudioToolTranslate,
    StudioTool.scan => l10n.aiStudioToolScan,
  };
}

/// Mutable per-tool session state owned by the AI Studio screen state.
/// Widgets only read it; mutations go through the screen's callbacks.
class StudioDraft {
  StudioDraft({this.language = 'hi-IN'});

  final result = TextEditingController();
  String language;
  String resultLanguage = 'hi-IN';
  StudioInput? input;
  StudioJob? job;
  String? error;
  bool edited = false;
  bool busy = false;
  bool selecting = false;
  // Realtime automation: runs by itself as soon as input is ready.
  bool auto = true;
  // Monotonic request id; stale responses that lose the race are dropped.
  int seq = 0;
  // Set when input changed while a request was in flight.
  bool pendingAuto = false;

  void dispose() => result.dispose();
}

enum StudioLiveState { listening, thinking, live, ready, idle }

/// Realtime status shown by the status badge.
StudioLiveState studioLiveState({
  required bool recording,
  required StudioDraft draft,
  required bool configured,
  required bool validInput,
}) {
  if (recording) return StudioLiveState.listening;
  if (draft.busy) return StudioLiveState.thinking;
  if (configured && draft.auto && validInput) {
    return StudioLiveState.live;
  }
  if (draft.result.text.trim().isNotEmpty) return StudioLiveState.ready;
  return StudioLiveState.idle;
}

/// Status line for the spark assistant while [tool] is processing.
String studioSparkStatus(StudioTool tool, AppLocalizations l10n) =>
    switch (tool) {
      StudioTool.transcribe => '${l10n.aiStudioToolTranscribe}…',
      StudioTool.translate => '${l10n.aiStudioToolTranslate}…',
      StudioTool.scan => 'Scanning & OCR converting…',
    };

/// Sub-headline for the spark assistant while [tool] is processing.
String studioSparkSubhead(StudioTool tool, StudioJob? job) => switch (tool) {
  StudioTool.transcribe => 'Transcribing speech to text… Tap spark ✨',
  StudioTool.translate => 'Translating text into Santali… Tap spark ✨',
  StudioTool.scan =>
    job != null
        ? 'Scan status: ${job.status} • Job: ${job.id}'
        : 'Extracting text from document… Tap spark ✨',
};

/// Snackbar text after copying / sharing a result.
String studioShareMessage(ShareOutcome outcome) => switch (outcome) {
  ShareOutcome.copiedToClipboard => 'Text copied to clipboard.',
  ShareOutcome.shared => 'Share sheet opened.',
  ShareOutcome.cancelled => 'Sharing cancelled.',
  ShareOutcome.downloaded => 'Text downloaded.',
  ShareOutcome.failed =>
    'Could not copy or share. Select the text to copy it manually.',
};
