import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/audio/audio_service.dart';
import '../providers/typing_practice_controller.dart';
import 'ol_chiki_keyboard.dart';
import 'typing_complete_celebration.dart';

class TypingPracticePanel extends ConsumerStatefulWidget {
  final TypingPracticeArgs args;
  final String? audioUrl;
  final VoidCallback? onPlayAudio;

  const TypingPracticePanel({
    super.key,
    required this.args,
    this.audioUrl,
    this.onPlayAudio,
  });

  @override
  ConsumerState<TypingPracticePanel> createState() => _TypingPracticePanelState();
}

class _TypingPracticePanelState extends ConsumerState<TypingPracticePanel>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  int _lastAttempts = 0;
  bool _audioPlayedOnComplete = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode()..canRequestFocus = false;

    // Shake animation setup: 300ms total, 4 oscillations, 8px magnitude
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 8.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    HapticFeedback.lightImpact();
    _shakeController.forward(from: 0.0);
  }

  void _playAudio() {
    if (widget.onPlayAudio != null) {
      widget.onPlayAudio!();
    } else if (widget.audioUrl != null) {
      ref.read(audioServiceProvider).playUrl(widget.audioUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(typingPracticeControllerProvider(widget.args));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger shake when mistake count increases
    if (state.attemptsTotal > _lastAttempts) {
      _lastAttempts = state.attemptsTotal;
      if (state.wrongAtPosition > 0) {
        _triggerShake();
      }
    }

    // Auto-play audio once on completion
    if (state.phase == TypingPhase.complete && !_audioPlayedOnComplete) {
      _audioPlayedOnComplete = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playAudio();
      });
    }

    // Sync input controller value and cursor position
    if (_textController.text != state.typedSoFar) {
      _textController.text = state.typedSoFar;
      _textController.selection = TextSelection.collapsed(offset: state.typedSoFar.length);
    }

    // Done State Layout
    if (state.phase == TypingPhase.done) {
      return _buildDoneLayout(context, isDark);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0.0),
              child: child,
            );
          },
          child: _buildInputCard(context, state, isDark),
        ),
        // Reveal Button Row (100% static footprint to avoid keyboard layout shift)
        Container(
          height: 64,
          alignment: Alignment.center,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: state.attemptsTotal >= 6 && state.phase == TypingPhase.typing ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: state.attemptsTotal < 6 || state.phase != TypingPhase.typing,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: () {
                    ref
                        .read(typingPracticeControllerProvider(widget.args).notifier)
                        .revealAndContinue();
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 16, color: AppColors.primary),
                  label: const Text(
                    'REVEAL & CONTINUE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: AppColors.primary, width: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // On-screen custom keyboard
        OlChikiKeyboard(args: widget.args),
      ],
    );
  }

  Widget _buildInputCard(BuildContext context, TypingPracticeState state, bool isDark) {
    final cardBg = isDark
        ? AppColors.charcoal.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);
    final cardBorder = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    final showCelebration = state.phase == TypingPhase.complete;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PRACTICE TYPING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (widget.audioUrl != null || widget.onPlayAudio != null)
                          Material(
                            color: Colors.transparent,
                            child: IconButton(
                              icon: const Icon(Icons.volume_up_rounded, size: 20),
                              color: AppColors.primary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _playAudio,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Latin & Meaning scaffolds
                    Center(
                      child: Column(
                        children: [
                          Text(
                            widget.args.latin,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.args.meaning,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    const SizedBox(height: 12),
                    // Target Field input area
                    _buildInputFieldArea(context, state, isDark),
                  ],
                ),
              ),
              // Complete Celebration overlay
              if (showCelebration)
                Positioned.fill(
                  child: TypingCompleteCelebration(
                    targetText: widget.args.target,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputFieldArea(BuildContext context, TypingPracticeState state, bool isDark) {
    final borderCol = state.wrongAtPosition > 0
        ? Colors.redAccent.withValues(alpha: 0.6)
        : (isDark ? Colors.white24 : Colors.black12);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderCol,
          width: state.wrongAtPosition > 0 ? 1.5 : 1,
        ),
        color: isDark ? Colors.black12 : Colors.grey.shade50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // 1. RichText overlay for styled typed characters, ghost hints, and dashes
          IgnorePointer(
            child: RichText(
              text: TextSpan(
                children: _buildRichTextSpans(
                  state.typedSoFar,
                  widget.args.target,
                  state.withHint,
                  isDark,
                ),
              ),
            ),
          ),
          // 2. Transparent TextField for native cursor support, auto-scrolling, and system keyboard suppression
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            readOnly: true,
            showCursor: true,
            enableInteractiveSelection: false,
            cursorColor: AppColors.primary,
            cursorWidth: 2.5,
            style: const TextStyle(
              fontFamily: 'OlChiki',
              fontSize: 26,
              letterSpacing: 4.0,
              fontWeight: FontWeight.bold,
              color: Colors.transparent, // Fully transparent so RichText shows through
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildRichTextSpans(
    String typed,
    String target,
    bool withHint,
    bool isDark,
  ) {
    final spans = <TextSpan>[];
    final normalStyle = TextStyle(
      fontFamily: 'OlChiki',
      fontSize: 26,
      letterSpacing: 4.0,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black87,
    );
    final hintStyle = TextStyle(
      fontFamily: 'OlChiki',
      fontSize: 26,
      letterSpacing: 4.0,
      fontWeight: FontWeight.bold,
      color: AppColors.primary.withValues(alpha: 0.45),
    );
    final dashStyle = TextStyle(
      fontFamily: 'OlChiki',
      fontSize: 26,
      letterSpacing: 4.0,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white24 : Colors.black26,
    );

    // Render successfully typed characters
    if (typed.isNotEmpty) {
      spans.add(TextSpan(text: typed, style: normalStyle));
    }

    if (typed.length < target.length) {
      final nextChar = target[typed.length];
      // Render ghost character hint if active, otherwise render next character dash
      if (withHint) {
        spans.add(TextSpan(text: nextChar, style: hintStyle));
      } else {
        spans.add(TextSpan(text: nextChar == ' ' ? ' ' : '_', style: dashStyle));
      }

      // Render remaining character dashes
      if (typed.length + 1 < target.length) {
        final remaining = target.substring(typed.length + 1);
        final dashes = remaining.split('').map((c) => c == ' ' ? ' ' : '_').join('');
        spans.add(TextSpan(text: dashes, style: dashStyle));
      }
    }

    return spans;
  }

  Widget _buildDoneLayout(BuildContext context, bool isDark) {
    final cardBg = isDark
        ? AppColors.charcoal.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);
    final cardBorder = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Celebratory check icon and title
            const Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Practiced Successfully',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Ol Chiki resolved word
            Text(
              widget.args.target,
              style: const TextStyle(
                fontFamily: 'OlChiki',
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            // Latin
            Text(
              widget.args.latin,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            // Meaning
            Text(
              widget.args.meaning,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            const SizedBox(height: 12),
            // Try again link
            TextButton(
              onPressed: () {
                _audioPlayedOnComplete = false;
                _lastAttempts = 0;
                ref
                    .read(typingPracticeControllerProvider(widget.args).notifier)
                    .tryAgain();
              },
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
