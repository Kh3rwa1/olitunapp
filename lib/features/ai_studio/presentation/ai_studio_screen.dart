import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

enum _MobileTab { input, result }

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

/// Private, review-first AAA+ AI workspace.
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
  _MobileTab _mobileTab = _MobileTab.input;
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
    _mobileTab = _MobileTab.input;
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
      _mobileTab = _MobileTab.input;
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
          if (!draft.edited) draft.result.text = job.text;
          _mobileTab = _MobileTab.result;
        });
      } else {
        final text = tool == _Tool.translate
            ? await service.translate(_source.text.trim(), draft.language)
            : await service.transcribe(draft.input!, draft.language);
        if (!mounted || generation != _generation) return;
        setState(() {
          draft.result.text = text;
          draft.edited = false;
          _mobileTab = _MobileTab.result;
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
        _mobileTab = _MobileTab.input;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'READY',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
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

  // ── Mobile Mode Switcher ─────────────────────────────────────────────
  Widget _buildMobileTabSwitcher(AppLocalizations l10n, bool isDark) {
    final hasResult = _draft.result.text.trim().isNotEmpty || _draft.edited;
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _mobileTabButton(
              tab: _MobileTab.input,
              label: '1. Input',
              icon: Icons.edit_note_rounded,
              selected: _mobileTab == _MobileTab.input,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _mobileTabButton(
              tab: _MobileTab.result,
              label: '2. Result',
              icon: Icons.auto_awesome_rounded,
              selected: _mobileTab == _MobileTab.result,
              hasBadge: hasResult,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileTabButton({
    required _MobileTab tab,
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    bool hasBadge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => setState(() => _mobileTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.studioActiveTabDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white54 : Colors.black45),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (hasBadge) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              ],
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

  // ── Mobile Single Screen Viewport (Non-Scrollable, Instant Deck) ─────
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
          _buildMobileTabSwitcher(l10n, isDark),
          const SizedBox(height: 8),
          if (!configured) ...[
            _notice(l10n.aiStudioNotConfigured, icon: Icons.cloud_off_outlined),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: IndexedStack(
              index: _mobileTab.index,
              children: [
                _inputPanel(
                  configured,
                  l10n,
                  isDark,
                  flex: true,
                  isMobile: true,
                ),
                _resultPanel(l10n, isDark, flex: true, isMobile: true),
              ],
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
                      setState(() {
                        draft.language = value;
                        draft.consent = false;
                      });
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
            child: Text(
              l10n.aiStudioProcessing,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Sleek Consent Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.03,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: draft.consent
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.06,
                    ),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              key: const Key('studio-consent'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              checkColor: AppColors.elevatedButtonFg,
              value: draft.consent,
              onChanged: locked || scanPending
                  ? null
                  : (value) => setState(() => draft.consent = value ?? false),
              title: Text(
                l10n.aiStudioConsentTitle,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              subtitle: Text(
                l10n.aiStudioConsentSubtitle,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 10,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (!scanPending) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: isMobile ? 42 : 46,
            child: FilledButton.icon(
              key: const Key('studio-process'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.elevatedButtonFg,
                disabledBackgroundColor: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
                disabledForegroundColor: isDark
                    ? Colors.white24
                    : Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: configured && !locked && draft.consent && _validInput
                  ? _process
                  : null,
              icon: Icon(_tool.icon, size: 16),
              label: Text(
                draft.busy
                    ? l10n.aiStudioProcessing
                    : l10n.aiStudioProcessWithAi(_tool.localizedLabel(l10n)),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 13 : 13.5,
                ),
              ),
            ),
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
                const SizedBox(height: 6),
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
          if (configured && !locked && draft.consent && _validInput) {
            _process();
          }
        },
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (configured && !locked && draft.consent && _validInput) {
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
        onChanged: (_) => setState(() => draft.consent = false),
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
                'Upload document or capture page',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'PDF, PNG or JPG · up to 10 MB',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: hasText
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.06,
                  ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hasText
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasText
                      ? AppColors.primary
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                hasText ? 'READY' : 'IDLE',
                style: TextStyle(
                  color: hasText
                      ? AppColors.primary
                      : (isDark ? Colors.white54 : Colors.black45),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    Widget body;
    if (_tool == _Tool.scan && job != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _notice(
            'Scan status: ${job.status}. '
            '${job.isTerminal ? 'Review any available text below.' : 'Use Check status for updates. Keep this screen open to retain this job.'}',
            icon: job.isTerminal
                ? Icons.description_outlined
                : Icons.hourglass_top_rounded,
          ),
          const SizedBox(height: 6),
          SelectableText(
            'Job: ${job.id}',
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
              label: const Text(
                'Check status',
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
              child: const Text(
                'Replace my edits with latest scan text',
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
                icon: const Icon(Icons.record_voice_over_outlined, size: 14),
                label: Text(
                  l10n.aiStudioSendToBodhan,
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
                onPressed: () => setState(() => _mobileTab = _MobileTab.input),
                icon: const Icon(Icons.arrow_back_rounded, size: 13),
                label: const Text(
                  'Edit source input',
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
      body: body,
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
        labelText: l10n.aiStudioEditableResult,
        alignLabelWithHint: true,
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
