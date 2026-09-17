import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../providers/santali_voice_providers.dart';
import 'widgets/studio_background.dart';
import 'widgets/studio_hero.dart';
import 'widgets/studio_status_dock.dart';
import 'widgets/voice_flip_faces.dart';
import 'widgets/voice_pickers.dart';

/// Santali AI Voice studio — compact single-screen layout.
///
/// The text box and the player share one flip card (package
/// `flutter_flip_card`): front = small input, back = player. Tapping
/// CREATE VOICE flips immediately; the back face shows progress while
/// Bodhan renders, then the clip.
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

class _SantaliVoiceScreenState extends ConsumerState<SantaliVoiceScreen> {
  static const _speedCycle = [1.0, 0.75, 1.25, 1.5];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FocusGlowFieldState> _glowKey =
      GlobalKey<FocusGlowFieldState>();
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

  PlaybackController get _player =>
      _playback ?? ref.read(playbackControllerProvider);

  /// Identity of the current clip inside the shared controller.
  String get _clipId =>
      _clip == null ? '' : (_clip!.storageFileId ?? _clip!.audioUrl);

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

  /// Play tap on the back face: toggle when the shared player carries our
  /// clip, otherwise (re)play it — so the button replays instead of
  /// being a dead control after dismiss.
  Future<void> _onPlayTap() async {
    if (_isMine) {
      await _player.togglePlayPause();
      return;
    }
    await _playCurrentClip();
  }

  /// Plays the current clip through the central player.
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

  String _statusText(bool playing, bool mine) {
    if (_isLoading) return 'Giving your words a Santali voice…';
    if (_clip == null) return 'Type it. Hear it. Share it.';
    if (playing) return 'Playing • ${_clip!.voice}';
    if (mine) return 'Ready • tap play';
    return 'Voice ready • open player below';
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
        ? StudioPhase.working
        : _clip != null
        ? StudioPhase.ready
        : StudioPhase.idle;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.translatorDarkBg
          : AppColors.translatorLightBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 52,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.1,
            ),
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
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
          StudioBackground(isDark: isDark),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Wide screens get a real two-column studio, not a
                // stretched phone column.
                if (ResponsiveLayout.isDesktop(context)) {
                  return _buildDesktopBody(
                    isDark,
                    phase,
                    playing,
                    voice,
                    style,
                    mine,
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMobileBody(
                        isDark,
                        phase,
                        playing,
                        voice,
                        style,
                        mine,
                      ),
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
    StudioPhase phase,
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
              StudioHeroStrip(
                isDark: isDark,
                phase: phase,
                playing: playing,
                statusText: _statusText(playing, mine),
                big: true,
              ),
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
                        SampleChips(
                          isDark: isDark,
                          samples: _samples,
                          onPick: _pickSample,
                        ),
                        const SizedBox(height: 16),
                        DuoButton(
                          text: _isLoading
                              ? 'CREATING YOUR VOICE...'
                              : 'CREATE VOICE',
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
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.09),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VoicePillSelector(
                            isDark: isDark,
                            selected: voice,
                            stacked: true,
                          ),
                          const SizedBox(height: 18),
                          StyleRailSelector(
                            isDark: isDark,
                            selected: style,
                            grid: true,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Tip: repeat clips are instant and free — they replay from cache.',
                            style: AppTypography.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.5),
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
    StudioPhase phase,
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
            StudioHeroStrip(
              isDark: isDark,
              phase: phase,
              playing: playing,
              statusText: _statusText(playing, mine),
            ),
            const SizedBox(height: 10),
            // Flip card: small text box ⇄ player.
            _buildFlipCard(176),
            const SizedBox(height: 8),
            SampleChips(isDark: isDark, samples: _samples, onPick: _pickSample),
            const SizedBox(height: 10),
            VoicePillSelector(isDark: isDark, selected: voice),
            const SizedBox(height: 8),
            StyleRailSelector(isDark: isDark, selected: style),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      child: FlipCard(
        controller: _flipController,
        rotateSide: RotateSide.right,
        animationDuration: const Duration(milliseconds: 550),
        frontWidget: VoiceInputFace(
          isDark: isDark,
          controller: _controller,
          focusNode: _focusNode,
          glowKey: _glowKey,
          maxChars: SantaliVoiceConfig.maxChars,
          hasClip: _clip != null,
          onFlipToBack: _flipToBack,
          onClear: () {
            _controller.clear();
            setState(() {});
          },
          onTextChanged: () {
            if (_error != null) {
              setState(() {
                _error = null;
                _loginRequired = false;
              });
            }
          },
        ),
        backWidget: VoicePlayerFace(
          isDark: isDark,
          clip: _clip,
          player: _player,
          isLoading: _isLoading,
          isDownloading: _isDownloading,
          onPlayTap: _onPlayTap,
          onSeek: (position) => _player.seek(position),
          onSpeedTap: _onSpeedTap,
          onDownload: _download,
          onRegenerate: _generate,
          onEdit: _flipToFront,
          onDismiss: _dismissClip,
        ),
      ),
    );
  }

  void _pickSample(String text) {
    _controller.text = text;
    setState(() {
      _error = null;
      _loginRequired = false;
    });
  }

  Widget _buildStatusDock(bool isDark) {
    return StudioStatusDock(
      isDark: isDark,
      isLoading: _isLoading,
      error: _error,
      loginRequired: _loginRequired,
      onLogin: () => context.push('/login'),
      onRetry: _generate,
    );
  }
}
