import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/playback_controller.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/presentation/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animated_buttons.dart';
import '../../../content/presentation/providers/audio_playback_providers.dart';
import '../../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../providers/santali_voice_providers.dart';

/// Santali AI Voice studio — compact single-screen layout.
///
/// The text box and the player share one flip card (package
/// `flutter_flip_card`): front = small input, back = player. Generating
/// audio flips the card to the player; the edit button flips back.
///
/// Playback runs through the existing central [PlaybackController] — the
/// same engine behind every lesson surface (one global player, speed,
/// seek, loading/error states) — instead of bespoke player plumbing.
///
/// Bodhan API keys never touch this screen: they live in the Appwrite
/// `bodhan_api_keys` collection and the `santaliVoice` function rotates
/// through them server-side when a key runs out of credit.
class SantaliVoiceScreen extends ConsumerStatefulWidget {
  const SantaliVoiceScreen({super.key});

  @override
  ConsumerState<SantaliVoiceScreen> createState() => _SantaliVoiceScreenState();
}

enum _StudioPhase { idle, working, ready }

class _SantaliVoiceScreenState extends ConsumerState<SantaliVoiceScreen> {
  static const _speedCycle = [1.0, 0.75, 1.25, 1.5];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FocusGlowFieldState> _glowKey = GlobalKey<FocusGlowFieldState>();
  final FlipCardController _flipController = FlipCardController();

  VoiceClip? _clip;
  bool _isLoading = false;
  String? _error;
  bool _loginRequired = false;
  bool _isDownloading = false;
  bool _showingBack = false;
  PlaybackController? _playback;

  static const _samples = [
    'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?',
    'ᱡᱚᱦᱟᱨ! ᱟᱞᱮ ᱚᱞ ᱪᱤᱠᱤ ᱛᱮ ᱨᱚᱲ ᱟᱹᱭᱠᱟᱹᱣ ᱢᱮ᱾',
    'ᱥᱟᱱᱛᱟᱲᱤ ᱯᱟᱹᱨᱥᱤ ᱫᱚ ᱟᱹᱰᱤ ᱢᱚᱡᱽ ᱜᱮᱭᱟ᱾',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(santaliVoiceNameProvider.notifier).load();
      ref.read(santaliVoiceStyleProvider.notifier).load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Central player binding (same manual-listener pattern as
    // AudioControlsBar): one global player, no local playback booleans.
    final controller = ref.read(playbackControllerProvider);
    if (!identical(_playback, controller)) {
      _playback?.removeListener(_onPlaybackChanged);
      _playback = controller;
      controller.addListener(_onPlaybackChanged);
    }
  }

  @override
  void dispose() {
    _playback?.removeListener(_onPlaybackChanged);
    _playback = null;
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPlaybackChanged(PlaybackState state) {
    if (mounted) setState(() {});
  }

  PlaybackController get _player => _playback ?? ref.read(playbackControllerProvider);

  /// Identity of the current clip inside the shared controller.
  String get _clipId => _clip == null ? '' : (_clip!.storageFileId ?? _clip!.audioUrl);

  bool get _isMine => _clip != null && _player.state.isFor('voice', _clipId);

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (_controller.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      _glowKey.currentState?.shake();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _error = null;
      _loginRequired = false;
    });
    // Flip to the player immediately — the back face shows progress
    // while Bodhan renders, then the clip.
    if (!_showingBack) {
      setState(() => _showingBack = true);
      unawaited(_flipController.flipcard());
    }
    final voice = ref.read(santaliVoiceNameProvider);
    final style = ref.read(santaliVoiceStyleProvider);
    final result = await ref
        .read(santaliTtsServiceProvider)
        .synthesize(text: _controller.text, voice: voice, style: style);
    if (!mounted) return;
    if (result.failure != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = result.failure!.message;
        _loginRequired = result.failure!.loginRequired;
        _isLoading = false;
      });
      // Back to the text so the learner can edit and retry.
      if (_showingBack) {
        setState(() => _showingBack = false);
        await _flipController.flipcard();
      }
      return;
    }
    setState(() {
      _clip = result.clip;
      _isLoading = false;
    });
    HapticFeedback.lightImpact();
    // Route through the central player, then flip the card to the player.
    await _player.playSingle(
      id: result.clip!.audioUrl,
      contentKind: 'voice',
      contentId: result.clip!.storageFileId ?? result.clip!.audioUrl,
      trackType: 'tts',
      languageCode: 'sat',
    );
    if (!mounted) return;
    if (_player.state.error != null) {
      setState(() {
        _error = _player.state.error;
      });
      return;
    }
    if (!_showingBack) {
      setState(() => _showingBack = true);
      await _flipController.flipcard();
    }
  }

  Future<void> _flipToFront() async {
    if (!_showingBack) return;
    HapticFeedback.lightImpact();
    setState(() => _showingBack = false);
    await _flipController.flipcard();
  }

  Future<void> _flipToBack() async {
    if (_showingBack) return;
    HapticFeedback.lightImpact();
    setState(() => _showingBack = true);
    await _flipController.flipcard();
  }

  /// X button: stop and return to the text box. The clip is kept so the
  /// learner can flip back to the player from the input face.
  Future<void> _dismissClip() async {
    HapticFeedback.lightImpact();
    await _player.stop();
    if (!_showingBack || !mounted) return;
    setState(() => _showingBack = false);
    await _flipController.flipcard();
  }

  /// Plays the current clip through the central player. Used when the
  /// back face is showing but the shared player carries nothing of ours
  /// (e.g. after dismiss) — the play button then replays instead of
  /// being a dead control.
  Future<void> _playCurrentClip() async {
    final clip = _clip;
    if (clip == null) return;
    HapticFeedback.lightImpact();
    await _player.playSingle(
      id: clip.audioUrl,
      contentKind: 'voice',
      contentId: clip.storageFileId ?? clip.audioUrl,
      trackType: 'tts',
      languageCode: 'sat',
    );
    if (mounted) setState(() {});
  }

  void _onSpeedTap() {
    final current = _player.state.speed;
    final index = _speedCycle.indexOf(current);
    final next = _speedCycle[(index + 1) % _speedCycle.length];
    HapticFeedback.lightImpact();
    _player.setSpeed(next);
  }

  Future<void> _download() async {
    final clip = _clip;
    if (clip == null || _isDownloading) return;
    HapticFeedback.mediumImpact();
    setState(() => _isDownloading = true);
    final message = await ref
        .read(voiceDownloadServiceProvider)
        .saveClip(audioUrl: clip.audioUrl, voice: clip.voice);
    if (!mounted) return;
    setState(() => _isDownloading = false);
    final failure = ref.read(voiceDownloadServiceProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? failure ?? 'Download failed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final voice = ref.watch(santaliVoiceNameProvider);
    final style = ref.watch(santaliVoiceStyleProvider);
    final state = _player.state;
    final playing = _isMine && state.isPlaying;
    final mine = _isMine;
    final phase = _isLoading
        ? _StudioPhase.working
        : _clip != null
        ? _StudioPhase.ready
        : _StudioPhase.idle;

    return Scaffold(
      backgroundColor: isDark ? AppColors.translatorDarkBg : AppColors.translatorLightBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 52,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
              tooltip: 'Close voice studio',
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'Santali AI Voice',
          style: AppTypography.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildPremiumBackground(isDark),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Wide screens get a real two-column studio, not a
                // stretched phone column.
                if (ResponsiveLayout.isDesktop(context)) {
                  return _buildDesktopBody(isDark, phase, playing, voice, style, mine);
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMobileBody(isDark, phase, playing, voice, style, mine),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Desktop: two-column studio ───────────────────────────────────────
  Widget _buildDesktopBody(
    bool isDark,
    _StudioPhase phase,
    bool playing,
    String voice,
    String style,
    bool mine,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroStrip(isDark, phase, playing, big: true, hasPlayableClip: mine),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: write + generate.
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFlipCard(248),
                        const SizedBox(height: 12),
                        _buildSamples(isDark),
                        const SizedBox(height: 16),
                        DuoButton(
                          text: _isLoading ? 'CREATING YOUR VOICE...' : 'CREATE VOICE',
                          icon: _isLoading ? null : Icons.mic_rounded,
                          isLoading: _isLoading,
                          onPressed: _generate,
                          height: 58,
                        ),
                        const SizedBox(height: 12),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: _buildStatusDock(isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right: voice console.
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.09),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVoicePills(isDark, voice, stacked: true),
                          const SizedBox(height: 18),
                          _buildStyleRail(isDark, style, grid: true),
                          const SizedBox(height: 18),
                          Text(
                            'Tip: repeat clips are instant and free — they replay from cache.',
                            style: AppTypography.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile: compact single screen ────────────────────────────────────
  Widget _buildMobileBody(
    bool isDark,
    _StudioPhase phase,
    bool playing,
    String voice,
    String style,
    bool mine,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight >= 540;
        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            _buildHeroStrip(isDark, phase, playing, hasPlayableClip: mine),
            const SizedBox(height: 10),
            // Flip card: small text box ⇄ player.
            _buildFlipCard(176),
            const SizedBox(height: 8),
            _buildSamples(isDark),
            const SizedBox(height: 10),
            _buildVoicePills(isDark, voice),
            const SizedBox(height: 8),
            _buildStyleRail(isDark, style),
            const Spacer(),
            DuoButton(
              text: _isLoading ? 'CREATING...' : 'CREATE VOICE',
              icon: _isLoading ? null : Icons.mic_rounded,
              isLoading: _isLoading,
              onPressed: _generate,
              height: 52,
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _buildStatusDock(isDark),
            ),
            const SizedBox(height: 4),
          ],
        );
        if (compact) return column;
        return SingleChildScrollView(child: column);
      },
    );
  }

  Widget _buildFlipCard(double height) {
    return SizedBox(
      height: height,
      child: FlipCard(
        controller: _flipController,
        rotateSide: RotateSide.right,
        animationDuration: const Duration(milliseconds: 550),
        frontWidget: _buildInputFace(
          Theme.of(context).brightness == Brightness.dark,
        ),
        backWidget: _buildPlayerFace(
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  // ── Hero: pulsing orb + title + live status ──────────────────────────
  Widget _buildHeroStrip(bool isDark, _StudioPhase phase, bool playing, {bool big = false, bool hasPlayableClip = false}) {
    final status = _isLoading
        ? 'Giving your words a Santali voice…'
        : _clip != null
        ? (playing
              ? 'Playing • ${_clip!.voice}'
              : (hasPlayableClip ? 'Ready • tap play' : 'Voice ready • open player below'))
        : 'Type it. Hear it. Share it.';
    return Row(
      children: [
        _StudioOrb(phase: phase, playing: playing),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ᱥᱟᱱᱛᱟᱲᱤ AI Voice',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: big ? 30 : 21,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentPurpleDark, AppColors.indigoVivid],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  status,
                  key: ValueKey(status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  // ── Flip FRONT: small text box ───────────────────────────────────────
  Widget _buildInputFace(bool isDark) {
    return FocusGlowField(
      key: _glowKey,
      focusNode: _focusNode,
      borderRadius: 20,
      glowColor: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: SantaliVoiceConfig.maxChars,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) {
                  if (_error != null) {
                    setState(() {
                      _error = null;
                      _loginRequired = false;
                    });
                  }
                },
                style: AppTypography.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ? — type in Ol Chiki...',
                  hintStyle: AppTypography.inter(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Row(
              children: [
                // Return path to the player after X/edit brought us back
                // to the text.
                if (_clip != null) ...[
                  GestureDetector(
                    onTap: _flipToBack,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PLAYER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() {});
                    },
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
                    ),
                  ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => Text(
                    '${value.text.trim().length} / ${SantaliVoiceConfig.maxChars}',
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Flip BACK: player (central PlaybackController state) ─────────────
  Widget _buildPlayerFace(bool isDark) {
    final clip = _clip;
    if (clip == null || _isLoading) {
      // Shown immediately after CREATE VOICE is tapped (the card flips
      // first, Bodhan renders second) and before the first generation.
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF0E7490)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _MiniBars(barCount: 12, height: 24, light: true),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                _isLoading ? 'Creating your voice…' : 'Your voice will appear here',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final state = _player.state;
    final mine = state.isFor('voice', _clipId);
    final playing = mine && state.isPlaying;
    final loading = mine && state.isLoading;
    final styleLabel = clip.style.isEmpty
        ? 'Neutral'
        : voiceStyles
            .firstWhere((s) => s.apiValue == clip.style, orElse: () => neutralStyle)
            .label;
    final total = mine ? state.duration : Duration.zero;
    final pos = mine ? state.position : Duration.zero;
    final value = total > Duration.zero ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(color: AppColors.violetGlow, blurRadius: 24, offset: Offset(0, 10), spreadRadius: -8),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${clip.voice} • $styleLabel${clip.cached ? ' • instant' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              _faceIcon(icon: Icons.edit_rounded, tooltip: 'Edit text', onTap: _flipToFront),
              _faceIcon(icon: Icons.close_rounded, tooltip: 'Dismiss', onTap: _dismissClip),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Semantics(
                  label: _player.playPauseSemanticsLabel,
                  button: true,
                  child: PressableScale(
                    onTap: loading
                        ? null
                        : (_isMine ? () => _player.togglePlayPause() : _playCurrentClip),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                color: AppColors.indigoVivid,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: AppColors.indigoVivid,
                              size: 28,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniBars(barCount: 14, height: 16, animate: playing, light: true),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDuration(pos),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: value,
                                onChanged: total > Duration.zero
                                    ? (v) => _player.seek(
                                          Duration(milliseconds: (v * total.inMilliseconds).round()),
                                        )
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(total),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _faceChip(
                label: '${state.speed.toStringAsFixed(state.speed == 0.75 || state.speed == 1.25 ? 2 : 1)}×',
                tooltip: 'Playback speed',
                onTap: _onSpeedTap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _faceChip(
                  label: _isDownloading ? 'SAVING…' : 'DOWNLOAD',
                  tooltip: 'Download',
                  icon: _isDownloading ? null : Icons.download_rounded,
                  onTap: _download,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _faceChip(
                  label: 'REGENERATE',
                  tooltip: 'Regenerate',
                  icon: Icons.refresh_rounded,
                  onTap: _generate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _faceIcon({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Semantics(
      label: tooltip,
      button: true,
      child: PressableScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        ),
      ),
    );
  }

  Widget _faceChip({required String label, required String tooltip, required VoidCallback onTap, IconData? icon}) {
    return PressableScale(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 15),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSamples(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _samples.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            PressableScale(
              onTap: () {
                HapticFeedback.lightImpact();
                _controller.text = _samples[i];
                setState(() {
                  _error = null;
                  _loginRequired = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _samples[i].length > 20 ? '${_samples[i].substring(0, 20)}…' : _samples[i],
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

  // ── Voice pills (Phulmani / Sibu only) ───────────────────────────────
  Widget _buildVoicePills(bool isDark, String selected, {bool stacked = false}) {
    final pills = [
      for (var i = 0; i < santaliVoices.length; i++)
        Expanded(child: _voicePill(isDark, santaliVoices[i], selected)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniLabel(isDark, 'VOICE  •  ᱟᱲᱟᱝ'),
        const SizedBox(height: 6),
        if (stacked)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < santaliVoices.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _voicePill(isDark, santaliVoices[i], selected),
              ],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < pills.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                pills[i],
              ],
            ],
          ),
      ],
    );
  }

  Widget _voicePill(bool isDark, BodhanVoice voice, String selected) {
    final isSelected = selected == voice.name;
    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(santaliVoiceNameProvider.notifier).select(voice.name);
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
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: AppColors.violetGlow, blurRadius: 16, offset: Offset(0, 6))]
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
                  color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Style rail ───────────────────────────────────────────────────────
  Widget _buildStyleRail(bool isDark, String selected, {bool grid = false}) {
    final chips = [
      for (var i = 0; i < voiceStyles.length; i++)
        _styleChip(isDark, voiceStyles[i], selected),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniLabel(isDark, 'STYLE  •  ᱨᱚᱲ'),
        const SizedBox(height: 6),
        if (grid)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          )
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

  Widget _styleChip(bool isDark, VoiceStyle style, String selected) {
    final isSelected = selected == style.apiValue;
    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(santaliVoiceStyleProvider.notifier).select(style.apiValue);
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
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          style.label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _miniLabel(bool isDark, String text) {
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

  // ── Status dock: loading / error only (player lives on the card back) ──
  Widget _buildStatusDock(bool isDark) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: const Row(
          children: [
            _MiniBars(barCount: 12, height: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Giving your words a Santali voice…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn();
    }
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _error ?? 'Something went wrong.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_loginRequired)
              _dockAction(label: 'SIGN IN', onTap: () => context.push('/login'))
            else
              _dockAction(label: 'RETRY', onTap: _generate),
          ],
        ),
      ).animate().fadeIn().shake();
    }
    return const SizedBox.shrink();
  }

  Widget _dockAction({required String label, required VoidCallback onTap}) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildPremiumBackground(bool isDark) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        AppColors.translatorDarkBg,
                        AppColors.translatorDarkMid,
                        AppColors.translatorDarkLight,
                      ]
                    : const [
                        AppColors.translatorLightCardA,
                        AppColors.translatorLightCardB,
                        AppColors.translatorLightCardC,
                      ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: EnchantedVisualizer(
            isPlaying: true,
            color: AppColors.primary,
            showWaves: false,
            height: 400,
          ),
        ),
      ],
    );
  }
}

/// Pulsing gradient orb with a mic at its core — the "Lottie-like" motion
/// of the screen, hand-built so it needs no binary assets.
class _StudioOrb extends StatefulWidget {
  const _StudioOrb({required this.phase, required this.playing});

  final _StudioPhase phase;
  final bool playing;

  @override
  State<_StudioOrb> createState() => _StudioOrbState();
}

class _StudioOrbState extends State<_StudioOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  }

  @override
  void didUpdateWidget(covariant _StudioOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final active = widget.phase == _StudioPhase.working || widget.playing;
    if (active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!active && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.phase == _StudioPhase.working || widget.playing;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < 2; i++)
                      Transform.scale(
                        scale: 0.75 + (((_controller.value + i * 0.5) % 1.0) * 0.55),
                        child: Opacity(
                          opacity: (1.0 - ((_controller.value + i * 0.5) % 1.0)) * 0.45,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.phase == _StudioPhase.ready
                  ? const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF0E7490)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [AppColors.accentPurpleDark, AppColors.indigoVivid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: const [
                BoxShadow(color: AppColors.violetGlow, blurRadius: 18, offset: Offset(0, 6)),
              ],
            ),
            child: Icon(
              widget.phase == _StudioPhase.working
                  ? Icons.graphic_eq_rounded
                  : widget.phase == _StudioPhase.ready && !widget.playing
                  ? Icons.check_rounded
                  : Icons.mic_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny animated equalizer bars — loading shimmer and now-playing pulse.
class _MiniBars extends StatefulWidget {
  const _MiniBars({required this.barCount, required this.height, this.animate = true, this.light = false});

  final int barCount;
  final double height;
  final bool animate;
  final bool light;

  @override
  State<_MiniBars> createState() => _MiniBarsState();
}

class _MiniBarsState extends State<_MiniBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _MiniBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (i) {
            final phase = (_controller.value * 2 + i / widget.barCount) % 1;
            final h = widget.height * 0.25 +
                widget.height * 0.75 * (0.5 + 0.5 * (0.5 - (phase - 0.5).abs()) * 2).clamp(0.0, 1.0);
            return Container(
              width: 3,
              height: widget.animate ? h : widget.height * 0.4,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.light ? Colors.white : AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        );
      },
    );
  }
}
