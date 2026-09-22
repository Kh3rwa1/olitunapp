import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sharing/growth_share_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/ai_studio_service.dart';
import '../data/studio_input_picker.dart';
import '../data/studio_recorder.dart';
import 'studio_passage_dialog.dart';

part 'ai_studio_status.dart';
part 'ai_studio_layout.dart';
part 'ai_studio_input.dart';
part 'ai_studio_input_tools.dart';
part 'ai_studio_result.dart';

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
  _Draft({this.language = 'hi-IN'});

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

enum _LiveState { listening, thinking, live, ready, idle }

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
    _Tool.transcribe: _Draft(language: 'sat-IN'),
    _Tool.translate: _Draft(),
    _Tool.scan: _Draft(language: 'sat-IN'),
  };
  final _flip = FlipCardController();
  final _flipKey = GlobalKey();
  bool _flipBusy = false;
  final _share = const GrowthShareService();
  _Tool _tool = _Tool.transcribe;
  int _generation = 0;
  bool _recording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  Timer? _debounce;
  Timer? _poll;
  int _pollAttempts = 0;
  late final AnimationController _pulse;
  _Draft get _draft => _drafts[_tool]!;

  void _setState(VoidCallback fn) => setState(fn);

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
      picked = tool == _Tool.transcribe
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

  void _selectTool(_Tool tool) {
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
    if (tool == _Tool.translate && _source.text.trim().length < 2) return;
    // A running scan owns its own auto-poll loop.
    if (tool == _Tool.scan && draft.job != null && !draft.job!.isTerminal) {
      return;
    }
    if (draft.busy) {
      draft.pendingAuto = true;
      return;
    }
    unawaited(_process());
  }

  void _onSourceChanged() {
    _debounce?.cancel();
    setState(() {});
    if (_tool != _Tool.translate) return;
    _debounce = Timer(_autoDebounce, () {
      if (mounted) _maybeAutoRun();
    });
  }

  void _schedulePoll() {
    _poll?.cancel();
    final generation = _generation;
    if (_tool != _Tool.scan) return;
    final draft = _draft;
    final job = draft.job;
    if (job == null || job.isTerminal) return;
    final jobId = job.id;
    _poll = Timer(_pollInterval, () {
      if (!mounted || generation != _generation || _tool != _Tool.scan) return;
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
    });
    bool alive() =>
        mounted &&
        generation == _generation &&
        _tool == tool &&
        draft.seq == seq;
    try {
      if (tool == _Tool.scan) {
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
        final text = tool == _Tool.translate
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
      }
    } finally {
      if (draft.seq == seq) draft.busy = false;
    }
    if (!mounted || generation != _generation) return;
    setState(() {});
    if (draft.seq != seq || _tool != tool) return;
    if (tool == _Tool.scan && draft.job != null && !draft.job!.isTerminal) {
      _schedulePoll();
    } else if (draft.pendingAuto) {
      draft.pendingAuto = false;
      _maybeAutoRun();
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
        _tool = _Tool.translate;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    _syncPulse();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.translatorDarkBg
          : AppColors.studioLightBg,
      appBar: _buildAppBar(l10n, isDark),
      body: Stack(
        children: [
          _buildAtmosphere(isDark),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;

                if (!isWide) {
                  return _buildMobileSingleScreenBody(
                    service.configured,
                    l10n,
                    isDark,
                  );
                }

                return _buildDesktopSingleScreenBody(
                  service.configured,
                  l10n,
                  isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
