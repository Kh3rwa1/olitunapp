import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../core/sharing/growth_share_service.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/ai_studio_service.dart';
import '../data/studio_input_picker.dart';
import '../data/studio_recorder.dart';
import 'studio_passage_dialog.dart';

enum _Tool {
  transcribe('Transcribe', Icons.graphic_eq_rounded),
  translate('Translate', Icons.translate_rounded),
  scan('Scan', Icons.document_scanner_outlined);

  const _Tool(this.label, this.icon);
  final String label;
  final IconData icon;

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    _Tool.transcribe => l10n.aiStudioToolTranscribe,
    _Tool.translate => l10n.aiStudioToolTranslate,
    _Tool.scan => l10n.aiStudioToolScan,
  };
}

class _Draft {
  final result = TextEditingController();
  String language = 'hi-IN';
  String resultLanguage = 'hi-IN';
  StudioInput? input;
  StudioJob? job;
  String? error;
  bool consent = false;
  bool edited = false;
  bool busy = false;
  bool selecting = false;

  void dispose() => result.dispose();
}

/// Private, review-first workspace. Inputs and jobs live only in this screen.
class AiStudioScreen extends ConsumerStatefulWidget {
  const AiStudioScreen({super.key});

  @override
  ConsumerState<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends ConsumerState<AiStudioScreen> {
  final _source = TextEditingController();
  final _drafts = {for (final tool in _Tool.values) tool: _Draft()};
  final _share = const GrowthShareService();
  _Tool _tool = _Tool.transcribe;
  int _generation = 0;
  bool _recording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  _Draft get _draft => _drafts[_tool]!;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _source.dispose();
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  void _resetSession() {
    _recordingTimer?.cancel();
    if (_recording) {
      unawaited(ref.read(studioRecorderProvider).cancel());
    }
    _recording = false;
    _recordingSeconds = 0;
    _generation++;
    _source.clear();
    for (final draft in _drafts.values) {
      draft.result.clear();
      draft.input = null;
      draft.job = null;
      draft.error = null;
      draft.consent = false;
      draft.edited = false;
      draft.busy = false;
      draft.selecting = false;
    }
    setState(() {});
  }

  Future<void> _pick({bool camera = false}) async {
    final draft = _draft;
    final generation = _generation;
    final tool = _tool;
    setState(() {
      draft.selecting = true;
      draft.error = null;
    });
    try {
      final picker = ref.read(studioInputPickerProvider);
      final input = tool == _Tool.transcribe
          ? await picker.pickAudio()
          : camera
          ? await picker.capturePage()
          : await picker.pickDocument();
      if (!mounted || generation != _generation || input == null) return;
      setState(() {
        draft.input = input;
        draft.consent = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          draft.error =
              'Could not open this file. Check the format and size, '
              'or allow camera access and try again.';
        });
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => draft.selecting = false);
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_tool != _Tool.transcribe || _draft.busy || _draft.selecting) return;
    final draft = _draft;
    final recorder = ref.read(studioRecorderProvider);
    final generation = _generation;
    try {
      if (!_recording) {
        await recorder.start();
        if (!mounted || generation != _generation) {
          await recorder.cancel();
          return;
        }
        setState(() {
          draft.error = null;
          _recording = true;
          _recordingSeconds = 0;
        });
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || generation != _generation || !_recording) {
            timer.cancel();
            return;
          }
          if (_recordingSeconds >= 29) {
            unawaited(_toggleRecording());
            return;
          }
          setState(() => _recordingSeconds++);
        });
        return;
      }

      _recordingTimer?.cancel();
      final input = await recorder.stop();
      if (!mounted || generation != _generation) return;
      setState(() {
        _recording = false;
        _recordingSeconds = 0;
        if (input == null) {
          draft.error =
              'No speech was captured. Check microphone access and try again.';
        } else {
          draft.input = input;
          draft.consent = false;
        }
      });
    } on StudioException catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _recording = false;
          _recordingSeconds = 0;
          draft.error = error.userMessage;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _recording = false;
          _recordingSeconds = 0;
          draft.error =
              'Could not start the microphone. Allow access and make sure no other app is using it.';
        });
      }
    }
  }

  void _selectTool(_Tool tool) {
    if (_tool == tool) return;
    if (_recording) {
      _recordingTimer?.cancel();
      unawaited(ref.read(studioRecorderProvider).cancel());
    }
    setState(() {
      _recording = false;
      _recordingSeconds = 0;
      _tool = tool;
    });
  }

  Future<void> _process({bool checkStatus = false}) async {
    final draft = _draft;
    final tool = _tool;
    final generation = _generation;
    final service = ref.read(aiStudioServiceProvider);
    if (draft.busy || !service.configured || !draft.consent) return;
    if (!checkStatus && !_validInput) return;
    setState(() {
      draft.busy = true;
      draft.error = null;
    });
    try {
      if (tool == _Tool.scan) {
        final job = checkStatus
            ? await service.pollOcr(draft.job!.id)
            : await service.startOcr(draft.input!, draft.language);
        if (!mounted || generation != _generation) return;
        setState(() {
          draft.job = job;
          draft.resultLanguage = draft.language;
          // Manual edits survive later status checks. Latest extracted text
          // remains available via the explicit restore action.
          if (!draft.edited) draft.result.text = job.text;
        });
      } else {
        final text = tool == _Tool.translate
            ? await service.translate(_source.text.trim(), draft.language)
            : await service.transcribe(draft.input!, draft.language);
        if (!mounted || generation != _generation) return;
        setState(() {
          draft.result.text = text;
          draft.edited = false;
          if (text.trim().isEmpty) {
            draft.error =
                'No text was returned. Review your input before retrying.';
          }
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          draft.error = error is StudioException
              ? error.userMessage
              : checkStatus
              ? 'Could not check this scan. Your job is saved here; try Check status again.'
              : 'Processing failed. Check your connection, sign-in and usage allowance. '
                    'Your input is still here. Retrying may use paid processing again.';
        });
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => draft.busy = false);
      }
    }
  }

  bool get _validInput => _tool == _Tool.translate
      ? _source.text.trim().isNotEmpty &&
            _source.text.trim().runes.length <= 2000
      : _draft.input != null;

  Future<void> _sendResult({required bool voice}) async {
    final generation = _generation;
    final sourceLanguage = _draft.language;
    final passage = await showDialog<String>(
      context: context,
      builder: (_) => StudioPassageDialog(
        text: _draft.result.text,
        limit: voice ? 600 : 2000,
        title: voice ? 'Choose text for Bodhan' : 'Choose text to translate',
        action: voice ? 'Open Bodhan' : 'Use in Translate',
      ),
    );
    if (!mounted || generation != _generation || passage == null) return;
    if (voice) {
      context.push('/voice', extra: passage);
    } else {
      setState(() {
        _source.text = passage;
        _tool = _Tool.translate;
        _draft.language = sourceLanguage == 'sat-IN' ? 'hi-IN' : sourceLanguage;
        _draft.consent = false;
        _draft.error = null;
      });
    }
  }

  Future<void> _shareResult({required bool copy}) async {
    final generation = _generation;
    final box = context.findRenderObject() as RenderBox?;
    final text = _draft.result.text.trim();
    final outcome = copy
        ? await _share.copyTextToClipboard(text)
        : await _share.shareText(
            text: text,
            title: 'AI Studio text',
            shareOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          );
    if (!mounted || generation != _generation) return;
    final message = switch (outcome) {
      ShareOutcome.copiedToClipboard => 'Text copied to clipboard.',
      ShareOutcome.shared => 'Share sheet opened.',
      ShareOutcome.cancelled => 'Sharing cancelled.',
      ShareOutcome.downloaded => 'Text downloaded.',
      ShareOutcome.failed =>
        'Could not copy or share. Select the text to copy it manually.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.watch(aiStudioServiceProvider);
    ref.listen(aiStudioServiceProvider, (previous, next) {
      if (previous != null && !identical(previous, next)) _resetSession();
    });
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiStudioTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveLayout.pagePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(l10n),
                  AppSpacing.gapH24,
                  if (!service.configured) ...[
                    _notice(
                      l10n.aiStudioNotConfigured,
                      icon: Icons.cloud_off_outlined,
                    ),
                    AppSpacing.gapH16,
                  ],
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final tool in _Tool.values)
                        ChoiceChip(
                          key: Key('tool-${tool.name}'),
                          avatar: Icon(tool.icon, size: 20),
                          label: Text(tool.localizedLabel(l10n)),
                          selected: _tool == tool,
                          padding: AppSpacing.edgeInsetsMd,
                          onSelected: (_) => _selectTool(tool),
                        ),
                    ],
                  ),
                  AppSpacing.gapH24,
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final input = _inputPanel(service.configured, l10n);
                      final output = _resultPanel(l10n);
                      // Stack sooner with larger text so both editors stay usable.
                      final wide =
                          constraints.maxWidth >= 900 &&
                          MediaQuery.textScalerOf(context).scale(16) <= 22;
                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: input),
                                AppSpacing.gapW24,
                                Expanded(child: output),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [input, AppSpacing.gapH24, output],
                            );
                    },
                  ),
                  AppSpacing.gapH24,
                  TextButton.icon(
                    onPressed: () => context.push('/translate'),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(l10n.aiStudioLookingForConverter),
                  ),
                  AppSpacing.gapH8,
                  Text(
                    l10n.aiStudioDisclaimer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapH24,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.edgeInsetsXxl,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.borderXxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined, color: colors.onPrimaryContainer),
          AppSpacing.gapH12,
          Text(
            l10n.aiStudioHeadline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          AppSpacing.gapH12,
          Text(
            l10n.aiStudioSubhead,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
          ),
          AppSpacing.gapH20,
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              for (final label in [
                l10n.aiStudioStep1,
                l10n.aiStudioStep2,
                l10n.aiStudioStep3,
              ])
                Text(label, style: TextStyle(color: colors.onPrimaryContainer)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel({required String title, required List<Widget> children}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.edgeInsetsXl,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          AppSpacing.gapH20,
          ...children,
        ],
      ),
    );
  }

  Widget _notice(
    String text, {
    IconData icon = Icons.info_outline,
    bool error = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: AppSpacing.edgeInsetsLg,
        decoration: BoxDecoration(
          color: error ? colors.errorContainer : colors.surfaceContainerHighest,
          borderRadius: AppRadius.borderMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: error ? colors.onErrorContainer : colors.onSurface,
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: error ? colors.onErrorContainer : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputPanel(bool configured, AppLocalizations l10n) {
    final draft = _draft;
    final locked = draft.busy || draft.selecting || _recording;
    final scanPending =
        _tool == _Tool.scan && draft.job != null && !draft.job!.isTerminal;
    final languages = studioLanguages.entries.where(
      (entry) => _tool != _Tool.translate || entry.key != 'sat-IN',
    );
    final panelTitle = switch (_tool) {
      _Tool.translate => l10n.aiStudioYourText,
      _Tool.transcribe => l10n.aiStudioYourAudio,
      _Tool.scan => l10n.aiStudioYourDocument,
    };
    return _panel(
      title: panelTitle,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('language-${_tool.name}-${draft.language}'),
          initialValue: draft.language,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.aiStudioSourceLanguage,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final entry in languages)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: locked || scanPending
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      draft.language = value;
                      draft.consent = false;
                    });
                  }
                },
        ),
        AppSpacing.gapH16,
        if (_tool == _Tool.translate) ...[
          Text(l10n.aiStudioTranslateNote),
          AppSpacing.gapH12,
          TextField(
            key: const Key('studio-source'),
            controller: _source,
            enabled: !locked,
            minLines: 5,
            maxLines: 10,
            maxLength: 2000,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            onChanged: (_) => setState(() => draft.consent = false),
            decoration: InputDecoration(
              labelText: l10n.aiStudioTextToTranslate,
              alignLabelWithHint: true,
              hintText: l10n.aiStudioTextPlaceholder,
              border: const OutlineInputBorder(),
              errorText: _source.text.trim().runes.length > 2000
                  ? l10n.aiStudioTextLimitError
                  : null,
              errorMaxLines: 3,
            ),
          ),
        ] else if (_tool == _Tool.transcribe) ...[
          Text(l10n.aiStudioSpeakNote),
          AppSpacing.gapH16,
          FilledButton.icon(
            key: const Key('studio-record'),
            onPressed: draft.busy || draft.selecting ? null : _toggleRecording,
            icon: const Icon(Icons.mic_rounded),
            label: Text(
              _recording
                  ? l10n.aiStudioStopRecording(
                      _recordingSeconds.toString().padLeft(2, '0'),
                    )
                  : l10n.aiStudioRecordVoice,
            ),
          ),
          if (_recording) ...[
            AppSpacing.gapH8,
            Semantics(liveRegion: true, child: Text(l10n.aiStudioListening)),
          ],
          AppSpacing.gapH16,
          const Divider(),
          AppSpacing.gapH12,
          Text(l10n.aiStudioOrExistingRecording),
          AppSpacing.gapH8,
          if (draft.input != null) ...[
            _notice(draft.input!.name, icon: Icons.audiotrack_outlined),
            AppSpacing.gapH12,
          ],
          OutlinedButton.icon(
            key: const Key('studio-pick'),
            onPressed: locked ? null : _pick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(
              draft.selecting
                  ? l10n.aiStudioOpening
                  : draft.input == null
                  ? l10n.aiStudioUploadWav
                  : l10n.aiStudioReplaceRecording,
            ),
          ),
        ] else ...[
          Text(l10n.aiStudioDocNote),
          AppSpacing.gapH16,
          if (draft.input != null) ...[
            _notice(draft.input!.name, icon: Icons.insert_drive_file_outlined),
            AppSpacing.gapH12,
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                key: const Key('studio-pick'),
                onPressed: locked || scanPending ? null : _pick,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  draft.selecting
                      ? l10n.aiStudioOpening
                      : draft.input == null
                      ? l10n.aiStudioChooseFile
                      : l10n.aiStudioReplaceFile,
                ),
              ),
              if (_tool == _Tool.scan)
                OutlinedButton.icon(
                  key: const Key('studio-camera'),
                  onPressed: locked || scanPending
                      ? null
                      : () => _pick(camera: true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(l10n.aiStudioCapturePage),
                ),
            ],
          ),
        ],
        AppSpacing.gapH20,
        // The enclosing card paints a background color on a DecoratedBox;
        // ListTile asserts against that. A transparent Material restores the
        // tile's own ink surface without changing the card's look.
        Material(
          type: MaterialType.transparency,
          child: CheckboxListTile(
            key: const Key('studio-consent'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: draft.consent,
            onChanged: locked || scanPending
                ? null
                : (value) => setState(() => draft.consent = value ?? false),
            title: Text(l10n.aiStudioConsentTitle),
            subtitle: Text(l10n.aiStudioConsentSubtitle),
          ),
        ),
        AppSpacing.gapH16,
        if (draft.error != null) ...[
          _notice(draft.error!, error: true, icon: Icons.error_outline),
          AppSpacing.gapH16,
        ],
        if (draft.busy) ...[
          const LinearProgressIndicator(
            semanticsLabel: 'AI processing in progress',
          ),
          AppSpacing.gapH12,
          Semantics(liveRegion: true, child: Text(l10n.aiStudioProcessing)),
          AppSpacing.gapH12,
        ],
        if (!scanPending)
          FilledButton.icon(
            key: const Key('studio-process'),
            onPressed: configured && !locked && draft.consent && _validInput
                ? _process
                : null,
            icon: Icon(_tool.icon),
            label: Text(
              draft.busy
                  ? l10n.aiStudioProcessing
                  : l10n.aiStudioProcessWithAi(_tool.localizedLabel(l10n)),
            ),
          ),
      ],
    );
  }

  Widget _resultPanel(AppLocalizations l10n) {
    final draft = _draft;
    final hasText = draft.result.text.trim().isNotEmpty;
    final job = draft.job;
    return _panel(
      title: l10n.aiStudioReviewAndUse,
      children: [
        if (_tool == _Tool.scan && job != null) ...[
          _notice(
            'Scan status: ${job.status}. '
            '${job.isTerminal ? 'Review any available text below.' : 'Use Check status for updates. Keep this screen open to retain this job.'}',
            icon: job.isTerminal
                ? Icons.description_outlined
                : Icons.hourglass_top_rounded,
          ),
          AppSpacing.gapH8,
          SelectableText(
            'Job: ${job.id}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          AppSpacing.gapH12,
          if (!job.isTerminal)
            OutlinedButton.icon(
              key: const Key('studio-check-status'),
              onPressed:
                  draft.busy || !ref.watch(aiStudioServiceProvider).configured
                  ? null
                  : () => _process(checkStatus: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Check status'),
            ),
          if (draft.edited && job.text.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                draft.result.text = job.text;
                draft.edited = false;
              }),
              child: const Text('Replace my edits with latest scan text'),
            ),
          AppSpacing.gapH16,
        ],
        if (!hasText && !draft.edited) ...[
          const Icon(Icons.edit_note_rounded, size: 48),
          AppSpacing.gapH12,
          Text(l10n.aiStudioResultPlaceholder, textAlign: TextAlign.center),
          AppSpacing.gapH8,
          Text(l10n.aiStudioResultDisclaimer, textAlign: TextAlign.center),
          AppSpacing.gapH24,
        ] else ...[
          TextField(
            key: ValueKey('studio-result-${_tool.name}'),
            controller: draft.result,
            minLines: 7,
            maxLines: 15,
            onChanged: (_) => setState(() => draft.edited = true),
            decoration: InputDecoration(
              labelText: l10n.aiStudioEditableResult,
              alignLabelWithHint: true,
              helperText: l10n.aiStudioReviewHelper,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
          AppSpacing.gapH16,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: hasText ? () => _shareResult(copy: true) : null,
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.aiStudioCopy),
              ),
              OutlinedButton.icon(
                onPressed: hasText ? () => _shareResult(copy: false) : null,
                icon: const Icon(
                  kIsWeb ? Icons.content_paste_outlined : Icons.share_outlined,
                ),
                label: Text(
                  kIsWeb ? l10n.aiStudioCopyToShare : l10n.aiStudioShare,
                ),
              ),
              if (_tool != _Tool.translate)
                OutlinedButton.icon(
                  onPressed:
                      hasText &&
                          draft.language != 'sat-IN' &&
                          !_drafts[_Tool.translate]!.busy
                      ? () => _sendResult(voice: false)
                      : null,
                  icon: const Icon(Icons.translate_rounded),
                  label: Text(l10n.aiStudioTranslateResult),
                ),
              OutlinedButton.icon(
                onPressed: hasText ? () => _sendResult(voice: true) : null,
                icon: const Icon(Icons.record_voice_over_outlined),
                label: Text(l10n.aiStudioSendToBodhan),
              ),
            ],
          ),
          AppSpacing.gapH12,
          Text(l10n.aiStudioBodhanNote),
          if (_tool != _Tool.translate && draft.language == 'sat-IN') ...[
            AppSpacing.gapH8,
            const Text('Translation is not available for Santali source text.'),
          ],
        ],
      ],
    );
  }
}
