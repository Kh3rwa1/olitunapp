import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sharing/growth_share_service.dart';
import '../../../core/theme/app_colors.dart';
import '../data/ai_studio_service.dart';
import '../data/studio_input_picker.dart';
import '../data/studio_recorder.dart';
import 'ai_studio_input.dart';
import 'ai_studio_layout.dart';
import 'ai_studio_processing_overlay.dart';
import 'ai_studio_result.dart';
import 'ai_studio_session.dart';
import 'ai_studio_status.dart';
import 'studio_passage_dialog.dart';

/// Private, review-first AAA+ AI workspace.
class AiStudioScreen extends ConsumerStatefulWidget {
  const AiStudioScreen({super.key});

  @override
  ConsumerState<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends ConsumerState<AiStudioScreen>
    with SingleTickerProviderStateMixin {
  static const _autoDebounce = Duration(milliseconds: 750);
  static const _pollInterval = Duration(seconds: 3);
  static const _maxPollAttempts = 20;
  static const _wideBreakpoint = 820.0;

  final _source = TextEditingController();
  final _drafts = {
    StudioTool.transcribe: StudioDraft(language: 'sat-IN'),
    StudioTool.translate: StudioDraft(),
    StudioTool.scan: StudioDraft(language: 'sat-IN'),
  };
  final _flip = FlipCardController();
  final _flipKey = GlobalKey();
  bool _flipBusy = false;
  final _share = const GrowthShareService();
  StudioTool _tool = StudioTool.transcribe;
  int _generation = 0;
  bool _recording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  Timer? _debounce;
  Timer? _poll;
  int _pollAttempts = 0;
  late final AnimationController _pulse;
  StudioDraft get _draft => _drafts[_tool]!;
  bool _sparkDismissed = false;

  bool get _isProcessing =>
      _draft.busy ||
      (_tool == StudioTool.scan &&
          _draft.job != null &&
          !_draft.job!.isTerminal &&
          _draft.result.text.trim().isEmpty);

  void _restoreSpark() => setState(() => _sparkDismissed = false);

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

  @override
  void initState() {
    super.initState();
    // Idle unless recording or thinking; keeps widget tests settling.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _debounce?.cancel();
    _poll?.cancel();
    _pulse.dispose();
    _source.dispose();
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  void _resetSession() {
    _recordingTimer?.cancel();
    _debounce?.cancel();
    _poll?.cancel();
    _pollAttempts = 0;
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
      draft.edited = false;
      draft.busy = false;
      draft.selecting = false;
    }
    unawaited(_flipTo(showResult: false));
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
    StudioInput? picked;
    try {
      final picker = ref.read(studioInputPickerProvider);
      picked = tool == StudioTool.transcribe
          ? await picker.pickAudio()
          : camera
          ? await picker.capturePage()
          : await picker.pickDocument();
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
    if (!mounted || generation != _generation || picked == null) return;
    setState(() {
      draft.input = picked;
    });
    _maybeAutoRun();
  }

  Future<void> _toggleRecording() async {
    if (_tool != StudioTool.transcribe || _draft.busy || _draft.selecting) {
      return;
    }
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
        }
      });
      if (input != null) _maybeAutoRun();
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

  void _selectTool(StudioTool tool) {
    if (_tool == tool) return;
    _debounce?.cancel();
    _poll?.cancel();
    _pollAttempts = 0;
    if (_recording) {
      _recordingTimer?.cancel();
      unawaited(ref.read(studioRecorderProvider).cancel());
    }
    // Invalidate any in-flight request for the outgoing tool so its late
    // response can never overwrite the new tool's state.
    _draft.seq++;
    _draft.busy = false;
    _draft.pendingAuto = false;
    unawaited(_flipTo(showResult: false));
    setState(() {
      _recording = false;
      _recordingSeconds = 0;
      _tool = tool;
    });
  }

  /// Flips the mobile card to the requested face. No-ops on wide layouts
  /// (no card there) and while a flip is already running.
  Future<void> _flipTo({required bool showResult}) async {
    if (_flipBusy) return;
    final face = _flipKey.currentState as FlipCardState?;
    if (face == null || MediaQuery.sizeOf(context).width >= _wideBreakpoint) {
      return;
    }
    if (face.isFront == !showResult) return;
    _flipBusy = true;
    try {
      await _flip.flipcard();
    } finally {
      _flipBusy = false;
    }
  }

  /// Fires the current tool by itself when it is armed: Auto is on, the
  /// backend is configured and the input is valid. Safe to call from any
  /// input change; it no-ops unless everything is ready.
  void _maybeAutoRun() {
    final draft = _draft;
    final tool = _tool;
    if (!draft.auto) return;
    if (_recording || draft.selecting) return;
    final service = ref.read(aiStudioServiceProvider);
    if (!service.configured || !_validInput) return;
    // Realtime translate waits for a word-ish input to spare paid calls;
    // the manual button still accepts a single character.
    if (tool == StudioTool.translate && _source.text.trim().length < 2) return;
    // A running scan owns its own auto-poll loop.
    if (tool == StudioTool.scan &&
        draft.job != null &&
        !draft.job!.isTerminal) {
      return;
    }
    if (draft.busy) {
      draft.pendingAuto = true;
      return;
    }
    unawaited(_process(flipOnStart: tool != StudioTool.translate));
  }

  void _onSourceChanged() {
    _debounce?.cancel();
    setState(() {});
    if (_tool != StudioTool.translate) return;
    _debounce = Timer(_autoDebounce, () {
      if (mounted) _maybeAutoRun();
    });
  }

  void _schedulePoll() {
    _poll?.cancel();
    final generation = _generation;
    if (_tool != StudioTool.scan) return;
    final draft = _draft;
    final job = draft.job;
    if (job == null || job.isTerminal) return;
    final jobId = job.id;
    _poll = Timer(_pollInterval, () {
      if (!mounted || generation != _generation || _tool != StudioTool.scan) {
        return;
      }
      final current = _draft;
      if (current.job?.id != jobId || current.job!.isTerminal) return;
      if (current.busy) {
        // A manual check is in flight; its completion reschedules us.
        _schedulePoll();
        return;
      }
      if (_pollAttempts >= _maxPollAttempts) return;
      _pollAttempts++;
      unawaited(_process(checkStatus: true, autoPoll: true));
    });
  }

  Future<void> _process({
    bool checkStatus = false,
    bool autoPoll = false,
    bool flipOnStart = true,
  }) async {
    final draft = _draft;
    final tool = _tool;
    final generation = _generation;
    final service = ref.read(aiStudioServiceProvider);
    if (draft.busy || !service.configured) return;
    if (!checkStatus && !_validInput) return;
    if (checkStatus && draft.job == null) return;
    final seq = ++draft.seq;
    draft.pendingAuto = false;
    _poll?.cancel();
    if (!checkStatus) _pollAttempts = 0;
    setState(() {
      draft.busy = true;
      draft.error = null;
      if (!autoPoll) _sparkDismissed = false;
    });
    if (!checkStatus && !autoPoll && flipOnStart) {
      unawaited(_flipTo(showResult: true));
    }
    bool alive() =>
        mounted &&
        generation == _generation &&
        _tool == tool &&
        draft.seq == seq;
    try {
      if (tool == StudioTool.scan) {
        final job = checkStatus
            ? await service.pollOcr(draft.job!.id)
            : await service.startOcr(draft.input!, draft.language);
        if (!alive()) return;
        setState(() {
          draft.job = job;
          draft.resultLanguage = draft.language;
          if (!draft.edited) draft.result.text = job.text;
        });
        unawaited(_flipTo(showResult: true));
      } else {
        final text = tool == StudioTool.translate
            ? await service.translate(_source.text.trim(), draft.language)
            : await service.transcribe(draft.input!, draft.language);
        if (!alive()) return;
        setState(() {
          draft.result.text = text;
          draft.edited = false;
          if (text.trim().isEmpty) {
            draft.error =
                'No text was returned. Review your input before retrying.';
          }
        });
        unawaited(_flipTo(showResult: true));
      }
    } catch (error) {
      // Silent for background auto-polls (the loop retries); loud for
      // anything the user explicitly started or armed.
      if (alive() && !autoPoll) {
        setState(() {
          draft.error = error is StudioException
              ? error.userMessage
              : checkStatus
              ? 'Could not check this scan. Your job is saved here; try Check status again.'
              : 'Processing failed. Check your connection, sign-in and usage allowance. '
                    'Your input is still here. Retrying may use paid processing again.';
        });
        if (!checkStatus) unawaited(_flipTo(showResult: false)); // show error
      }
    } finally {
      if (draft.seq == seq) draft.busy = false;
    }
    if (!mounted || generation != _generation) return;
    setState(() {});
    if (draft.seq != seq || _tool != tool) return;
    if (tool == StudioTool.scan &&
        draft.job != null &&
        !draft.job!.isTerminal) {
      _schedulePoll();
    } else if (draft.pendingAuto) {
      draft.pendingAuto = false;
      _maybeAutoRun();
    }
  }

  bool get _validInput => _tool == StudioTool.translate
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
        title: voice
            ? 'Choose text for Voice Studio'
            : 'Choose text to translate',
        action: voice ? 'Open Voice Studio' : 'Use in Translate',
      ),
    );
    if (!mounted || generation != _generation || passage == null) return;
    if (voice) {
      context.push('/voice', extra: passage);
    } else {
      setState(() {
        _source.text = passage;
        _tool = StudioTool.translate;
        _draft.language = sourceLanguage == 'sat-IN' ? 'hi-IN' : sourceLanguage;
        _draft.error = null;
      });
      unawaited(_flipTo(showResult: false));
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
    final message = studioShareMessage(outcome);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _statusBadge(bool configured) => StudioStatusBadge(
    state: studioLiveState(
      recording: _recording,
      draft: _draft,
      configured: configured,
      validInput: _validInput,
    ),
    recordingSeconds: _recordingSeconds,
    pulse: _pulse,
  );

  Widget _inputPanel(bool configured, {required bool isMobile}) {
    final draft = _draft;
    return StudioInputPanel(
      tool: _tool,
      draft: draft,
      source: _source,
      configured: configured,
      validInput: _validInput,
      recording: _recording,
      recordingSeconds: _recordingSeconds,
      pulse: _pulse,
      flex: true,
      isMobile: isMobile,
      onLanguageChanged: (value) {
        setState(() => draft.language = value);
        _maybeAutoRun();
      },
      onProcess: () => unawaited(_process()),
      onToggleAuto: () {
        setState(() => draft.auto = !draft.auto);
        if (draft.auto) _maybeAutoRun();
      },
      onRestoreSpark: _restoreSpark,
      onToggleRecording: _toggleRecording,
      onPick: (camera) => _pick(camera: camera),
      onSourceChanged: _onSourceChanged,
    );
  }

  Widget _resultPanel(bool configured, {required bool isMobile}) {
    final draft = _draft;
    return StudioResultPanel(
      tool: _tool,
      draft: draft,
      configured: configured,
      translateBusy: _drafts[StudioTool.translate]!.busy,
      statusBadge: _statusBadge(configured),
      flex: true,
      isMobile: isMobile,
      onRestoreSpark: _restoreSpark,
      onCheckStatus: () => _process(checkStatus: true),
      onReplaceWithScan: () => setState(() {
        draft.result.text = draft.job!.text;
        draft.edited = false;
      }),
      onEdited: () => setState(() => draft.edited = true),
      onShare: (copy) => _shareResult(copy: copy),
      onSend: (voice) => _sendResult(voice: voice),
      onEditSource: () => unawaited(_flipTo(showResult: false)),
    );
  }

  /// Scan/transcribe run long enough for an overlay ad to be seen; the
  /// translate overlay only flashes while typing.
  bool get _showsProcessingAd =>
      _isProcessing && !_sparkDismissed && _tool != StudioTool.translate;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(aiStudioServiceProvider);
    ref.listen(aiStudioServiceProvider, (previous, next) {
      if (previous != null && !identical(previous, next)) _resetSession();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    _syncPulse();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.translatorDarkBg
          : AppColors.studioLightBg,
      appBar: StudioAppBar(statusBadge: _statusBadge(service.configured)),
      // One ad at a time: the bar steps aside while the overlay shows its own.
      bottomNavigationBar: _showsProcessingAd ? null : const StudioBottomAd(),
      body: Stack(
        children: [
          const StudioAtmosphere(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= _wideBreakpoint;
                return StudioWorkspaceBody(
                  isWide: isWide,
                  configured: service.configured,
                  toolSwitcher: StudioToolSwitcher(
                    selected: _tool,
                    onSelect: _selectTool,
                  ),
                  inputPanel: _inputPanel(
                    service.configured,
                    isMobile: !isWide,
                  ),
                  resultPanel: _resultPanel(
                    service.configured,
                    isMobile: !isWide,
                  ),
                  flipKey: _flipKey,
                  flipController: _flip,
                );
              },
            ),
          ),
          Positioned.fill(
            child: StudioProcessingOverlay(
              visible: _isProcessing && !_sparkDismissed,
              showAd: _showsProcessingAd,
              tool: _tool,
              job: _draft.job,
              isDark: isDark,
              onDismiss: () => setState(() => _sparkDismissed = true),
            ),
          ),
        ],
      ),
    );
  }
}
