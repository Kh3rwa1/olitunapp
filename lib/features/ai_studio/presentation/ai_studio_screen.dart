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
          setState(() => draft.auto = !draft.auto);
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

  // ── Atmospheric Background ───────────────────────────────────────────
  Widget _buildAtmosphere(bool isDark) {
    if (!isDark) return const SizedBox.shrink();
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.translatorDarkBg,
              AppColors.translatorDarkMid,
              AppColors.studioAtmosphereDark,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -100,
              child: Container(
                width: 440,
                height: 440,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.bakhedGlowBlue.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sleek Studio Navigation Header ────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.translatorDarkBg.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 52,
      leadingWidth: 50,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.06,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.aiStudioTitle,
            style: AppTypography.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(l10n, ref.watch(aiStudioServiceProvider).configured),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Center(
            child: IconButton(
              tooltip: l10n.aiStudioLookingForConverter,
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.06,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              onPressed: () => context.push('/translate'),
            ),
          ),
        ),
      ],
    );
  }

  // ── Tool Switcher Pill Capsule ───────────────────────────────────────
  Widget _buildToolSwitcher(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final tool in _Tool.values) _toolPill(tool, l10n, isDark),
          ],
        ),
      ),
    );
  }

  Widget _toolPill(_Tool tool, AppLocalizations l10n, bool isDark) {
    final selected = _tool == tool;
    return Material(
      key: Key('tool-${tool.name}'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => _selectTool(tool),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tool.icon,
                size: 14,
                color: selected
                    ? AppColors.elevatedButtonFg
                    : isDark
                    ? Colors.white70
                    : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                tool.localizedLabel(l10n),
                style: TextStyle(
                  color: selected
                      ? AppColors.elevatedButtonFg
                      : isDark
                      ? Colors.white70
                      : Colors.black87,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Desktop Single Screen Viewport (Two Columns, Non-Scrollable) ──────
  Widget _buildDesktopSingleScreenBody(
    bool configured,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolSwitcher(l10n, isDark),
          const SizedBox(height: 12),
          if (!configured) ...[
            _notice(l10n.aiStudioNotConfigured, icon: Icons.cloud_off_outlined),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _inputPanel(
                    configured,
                    l10n,
                    isDark,
                    flex: true,
                    isMobile: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: _resultPanel(
                    l10n,
                    isDark,
                    flex: true,
                    isMobile: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiStudioDisclaimer,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Mobile Flip Viewport (Input front, Result back) ──────────────────
  Widget _buildMobileSingleScreenBody(
    bool configured,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolSwitcher(l10n, isDark),
          const SizedBox(height: 8),
          if (!configured) ...[
            _notice(l10n.aiStudioNotConfigured, icon: Icons.cloud_off_outlined),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: FlipCard(
              key: _flipKey,
              controller: _flip,
              rotateSide: RotateSide.right,
              animationDuration: const Duration(milliseconds: 550),
              frontWidget: _inputPanel(
                configured,
                l10n,
                isDark,
                flex: true,
                isMobile: true,
              ),
              backWidget: _resultPanel(
                l10n,
                isDark,
                flex: true,
                isMobile: true,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.aiStudioDisclaimer,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Glass Studio Workspace Card ──────────────────────────────────────
  Widget _studioCard({
    required Widget header,
    required Widget body,
    Widget? footer,
    required bool isDark,
    required bool flex,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.studioCardDark : Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            SizedBox(height: isMobile ? 10 : 14),
            if (flex)
              Expanded(child: SingleChildScrollView(child: body))
            else
              body,
            if (footer != null) ...[
              SizedBox(height: isMobile ? 10 : 14),
              footer,
            ],
          ],
        ),
      ),
    );
  }

  // ── Notice Banner ────────────────────────────────────────────────────
  Widget _notice(
    String text, {
    IconData icon = Icons.info_outline,
    bool error = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = error
        ? (isDark
              ? AppColors.studioNoticeErrorDark
              : AppColors.studioNoticeErrorLight)
        : (isDark
              ? AppColors.studioNoticeInfoDark
              : AppColors.studioNoticeInfoLight);
    final fg = error
        ? AppColors.studioNoticeErrorFg
        : (isDark ? Colors.white70 : AppColors.studioNoticeInfoFg);

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: error
                ? AppColors.error.withValues(alpha: 0.3)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input Panel ──────────────────────────────────────────────────────
  Widget _inputPanel(
    bool configured,
    AppLocalizations l10n,
    bool isDark, {
    required bool flex,
    required bool isMobile,
  }) {
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
            key: ValueKey('language-${_tool.name}-${draft.language}'),
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
                    if (value != null) {
                      setState(() => draft.language = value);
                      _maybeAutoRun();
                    }
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
    if (_tool == _Tool.translate) {
      body = _buildTranslateInput(
        configured,
        locked,
        draft,
        l10n,
        isDark,
        isMobile,
      );
    } else if (_tool == _Tool.transcribe) {
      body = _buildTranscribeInput(locked, draft, l10n, isDark, isMobile);
    } else {
      body = _buildScanInput(
        locked,
        scanPending,
        draft,
        l10n,
        isDark,
        isMobile,
      );
    }

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (draft.error != null) ...[
          _notice(draft.error!, error: true, icon: Icons.error_outline_rounded),
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
          const SizedBox(height: 5),
          Semantics(
            liveRegion: true,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final dots = '.' * (1 + ((_pulse.value * 3).floor() % 3));
                return Text(
                  '${l10n.aiStudioThinking}${dots}',
                  style: const TextStyle(
                    color: AppColors.amberEmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!scanPending) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _autoPill(draft, isDark),
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
                  onPressed: configured && !locked && _validInput
                      ? () => unawaited(_process())
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_tool.icon, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          draft.busy
                              ? l10n.aiStudioProcessing
                              : l10n.aiStudioProcessWithAi(
                                  _tool.localizedLabel(l10n),
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

    return _studioCard(
      header: header,
      body: body,
      footer: footer,
      isDark: isDark,
      flex: flex,
      isMobile: isMobile,
    );
  }

  // ── Tool 1: Transcribe Input ─────────────────────────────────────────
  Widget _buildTranscribeInput(
    bool locked,
    _Draft draft,
    AppLocalizations l10n,
    bool isDark,
    bool isMobile,
  ) {
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
              color: _recording
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
                onTap: draft.busy || draft.selecting ? null : _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isMobile ? 64 : 70,
                  height: isMobile ? 64 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _recording
                        ? AppColors.studioRecordingRed
                        : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_recording
                                    ? AppColors.studioRecordingRed
                                    : AppColors.primary)
                                .withValues(alpha: 0.35),
                        blurRadius: _recording ? 20 : 12,
                        spreadRadius: _recording ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _recording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: isMobile ? 28 : 32,
                    color: _recording
                        ? Colors.white
                        : AppColors.elevatedButtonFg,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 10 : 14),
              FilledButton.tonal(
                key: const Key('studio-record'),
                style: FilledButton.styleFrom(
                  backgroundColor: _recording
                      ? AppColors.studioRecordingRed.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: _recording
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
                    : _toggleRecording,
                child: Text(
                  _recording
                      ? l10n.aiStudioStopRecording(
                          _recordingSeconds.toString().padLeft(2, '0'),
                        )
                      : l10n.aiStudioRecordVoice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (_recording) ...[
                const SizedBox(height: 10),
                _waveform(),
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
            onPressed: locked ? null : _pick,
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

  // ── Tool 2: Translate Input ──────────────────────────────────────────
  Widget _buildTranslateInput(
    bool configured,
    bool locked,
    _Draft draft,
    AppLocalizations l10n,
    bool isDark,
    bool isMobile,
  ) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (configured && !locked && _validInput) {
            _process();
          }
        },
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (configured && !locked && _validInput) {
            _process();
          }
        },
      },
      child: TextField(
        key: const Key('studio-source'),
        controller: _source,
        enabled: !locked,
        minLines: isMobile ? 4 : 5,
        maxLines: null,
        maxLength: 2000,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: isMobile ? 13.5 : 14,
          height: 1.45,
        ),
        onChanged: (_) => _onSourceChanged(),
        decoration: InputDecoration(
          hintText: l10n.aiStudioTextPlaceholder,
          hintStyle: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.35,
            ),
            fontSize: 13,
          ),
          filled: true,
          fillColor: (isDark ? Colors.black : Colors.white).withValues(
            alpha: 0.25,
          ),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.08,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.08,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorText: _source.text.trim().runes.length > 2000
              ? l10n.aiStudioTextLimitError
              : null,
          helperText:
              (!isMobile &&
                  (kIsWeb ||
                      defaultTargetPlatform == TargetPlatform.macOS ||
                      defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.linux))
              ? 'Press Ctrl+Enter / ⌘+Enter to submit'
              : null,
          helperStyle: TextStyle(
            fontSize: 10,
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.4,
            ),
          ),
          counterStyle: TextStyle(
            fontSize: 10,
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tool 3: Scan Input ───────────────────────────────────────────────
  Widget _buildScanInput(
    bool locked,
    bool scanPending,
    _Draft draft,
    AppLocalizations l10n,
    bool isDark,
    bool isMobile,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 18 : 24,
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.03,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.06,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: isMobile ? 30 : 36,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.aiStudioUploadPrompt,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                AppLocalizations.of(context)!.aiStudioUploadFormats,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10.5,
                ),
              ),
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
                  Icons.insert_drive_file_outlined,
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
        LayoutBuilder(
          builder: (context, boxConstraints) {
            final compact = boxConstraints.maxWidth < 240;
            final pickButton = OutlinedButton.icon(
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
              onPressed: locked || scanPending ? null : _pick,
              icon: const Icon(Icons.upload_file_outlined, size: 15),
              label: Text(
                draft.selecting
                    ? l10n.aiStudioOpening
                    : draft.input == null
                    ? l10n.aiStudioChooseFile
                    : l10n.aiStudioReplaceFile,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );

            final cameraButton = OutlinedButton.icon(
              key: const Key('studio-camera'),
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
              onPressed: locked || scanPending
                  ? null
                  : () => _pick(camera: true),
              icon: const Icon(Icons.camera_alt_outlined, size: 15),
              label: Text(
                l10n.aiStudioCapturePage,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [pickButton, const SizedBox(height: 6), cameraButton],
              );
            }

            return Row(
              children: [
                Expanded(child: pickButton),
                const SizedBox(width: 8),
                Expanded(child: cameraButton),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Result Panel ─────────────────────────────────────────────────────
  Widget _resultPanel(
    AppLocalizations l10n,
    bool isDark, {
    required bool flex,
    required bool isMobile,
  }) {
    final draft = _draft;
    final hasText = draft.result.text.trim().isNotEmpty;
    final job = draft.job;

    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              l10n.aiStudioReviewAndUse,
              style: AppTypography.inter(
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(l10n, ref.watch(aiStudioServiceProvider).configured),
      ],
    );

    Widget body;
    if (_tool == _Tool.scan && job != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _notice(
            job.isTerminal
                ? 'Scan status: ${job.status}. Review any available text below.'
                : (draft.auto
                      ? l10n.aiStudioScanningLive
                      : 'Scan status: ${job.status}. Use Check status for updates. Keep this screen open to retain this job.'),
            icon: job.isTerminal
                ? Icons.description_outlined
                : Icons.hourglass_top_rounded,
          ),
          const SizedBox(height: 6),
          SelectableText(
            AppLocalizations.of(context)!.aiStudioJobId(id: job.id),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 6),
          if (!job.isTerminal) ...[
            OutlinedButton.icon(
              key: const Key('studio-check-status'),
              onPressed:
                  draft.busy || !ref.watch(aiStudioServiceProvider).configured
                  ? null
                  : () => _process(checkStatus: true),
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: Text(
                AppLocalizations.of(context)!.aiStudioCheckStatus,
                style: TextStyle(fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (draft.edited && job.text.isNotEmpty) ...[
            TextButton(
              onPressed: () => setState(() {
                draft.result.text = job.text;
                draft.edited = false;
              }),
              child: Text(
                AppLocalizations.of(context)!.aiStudioReplaceWithScan,
                style: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 6),
          ],
          _buildResultEditor(draft, l10n, isDark, isMobile),
        ],
      );
    } else if (!hasText && !draft.edited) {
      body = Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isMobile ? 44 : 52,
                height: isMobile ? 44 : 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: isMobile ? 20 : 24,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.aiStudioResultPlaceholder,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: isMobile ? 13 : 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.aiStudioResultDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black45,
                  fontSize: isMobile ? 10.5 : 11,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = _buildResultEditor(draft, l10n, isDark, isMobile);
    }

    Widget? footer;
    if (hasText || draft.edited) {
      footer = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: hasText ? () => _shareResult(copy: true) : null,
                icon: const Icon(Icons.copy_outlined, size: 14),
                label: Text(
                  l10n.aiStudioCopy,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: hasText ? () => _shareResult(copy: false) : null,
                icon: const Icon(
                  kIsWeb ? Icons.content_paste_outlined : Icons.share_outlined,
                  size: 14,
                ),
                label: Text(
                  kIsWeb ? l10n.aiStudioCopyToShare : l10n.aiStudioShare,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_tool != _Tool.translate)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    side: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.12,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed:
                      hasText &&
                          draft.language != 'sat-IN' &&
                          !_drafts[_Tool.translate]!.busy
                      ? () => _sendResult(voice: false)
                      : null,
                  icon: const Icon(Icons.translate_rounded, size: 14),
                  label: Text(
                    l10n.aiStudioTranslateResult,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: hasText ? () => _sendResult(voice: true) : null,
                icon: const Icon(Icons.graphic_eq_rounded, size: 14),
                label: Text(
                  l10n.aiStudioSendToVoiceStudio,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => unawaited(_flipTo(showResult: false)),
                icon: const Icon(Icons.arrow_back_rounded, size: 13),
                label: Text(
                  AppLocalizations.of(context)!.aiStudioEditSource,
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return _studioCard(
      header: header,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(
            'result-${_tool.name}-$hasText-${job?.status ?? 'none'}',
          ),
          child: body,
        ),
      ),
      footer: footer,
      isDark: isDark,
      flex: flex,
      isMobile: isMobile,
    );
  }

  Widget _buildResultEditor(
    _Draft draft,
    AppLocalizations l10n,
    bool isDark,
    bool isMobile,
  ) {
    return TextField(
      key: ValueKey('studio-result-${_tool.name}'),
      controller: draft.result,
      minLines: isMobile ? 5 : 6,
      maxLines: null,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontFamily: 'OlChiki',
        fontSize: isMobile ? 14 : 15,
        height: 1.5,
      ),
      onChanged: (_) => setState(() => draft.edited = true),
      decoration: InputDecoration(
        hintText: l10n.aiStudioResultPlaceholder,
        filled: true,
        fillColor: (isDark ? Colors.black : Colors.white).withValues(
          alpha: 0.25,
        ),
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
