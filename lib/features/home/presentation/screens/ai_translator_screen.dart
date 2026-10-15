import 'dart:async';
import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/ai_service.dart';
import '../../../../core/motion/motion.dart';
import '../../../../shared/widgets/ai_spark_assistant.dart';
import '../../../../shared/widgets/animated_buttons.dart';
import '../../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../../../../core/ads/widgets/native_ad_widget.dart';
import '../../../../l10n/generated/app_localizations.dart';

class AiTranslatorScreen extends ConsumerStatefulWidget {
  const AiTranslatorScreen({super.key});

  @override
  ConsumerState<AiTranslatorScreen> createState() => _AiTranslatorScreenState();
}

class _AiTranslatorScreenState extends ConsumerState<AiTranslatorScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FocusGlowFieldState> _glowKey =
      GlobalKey<FocusGlowFieldState>();
  String _result = '';
  bool _isLoading = false;
  bool _isError = false;
  bool _showTranslateButton = true;
  bool _isCopied = false;
  Timer? _copiedTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _onInputTouched();
      }
    });
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputTouched() {
    if (!_showTranslateButton) {
      setState(() => _showTranslateButton = true);
    }
  }

  void _copyResult() {
    if (_result.isEmpty || _isError) return;
    Clipboard.setData(ClipboardData(text: _result));
    HapticFeedback.lightImpact();
    setState(() => _isCopied = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final copiedLabel = AppLocalizations.of(context)!.copiedToClipboard;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(copiedLabel),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );

    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _translate() async {
    if (_controller.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      _glowKey.currentState?.shake();
      return;
    }

    // Dismiss keyboard
    _focusNode.unfocus();

    setState(() => _isLoading = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.translate(_controller.text.trim());

      if (mounted) {
        setState(() {
          _result = result?.translation ?? 'Translation failed.';
          _isError = result?.isError ?? true;
          _isLoading = false;
          if (!_isError && _result.isNotEmpty) {
            _showTranslateButton = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = 'Error occurred. Please try again.';
          _isError = true;
          _isLoading = false;
          _showTranslateButton = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.translatorDarkBg
          : AppColors.translatorLightBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              ),
              tooltip: 'Close translator',
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.aiTranslatorTitle,
          style: AppTypography.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Global Premium Background
          _buildPremiumBackground(isDark),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.voiceSpeakWithConfidence,
                    style: AppTypography.inter(
                      fontSize: _result.isNotEmpty ? 26 : 34,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.05),

                  const SizedBox(height: 16),

                  // Input Field with Glassmorphism
                  FocusGlowField(
                    key: _glowKey,
                    focusNode: _focusNode,
                    borderRadius: 24,
                    glowColor: AppColors.primary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onTap: _onInputTouched,
                        onChanged: (_) => _onInputTouched(),
                        maxLength: AiConfig.maxTranslationChars,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        maxLines: null,
                        style: AppTypography.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'Type anything in English...',
                          hintStyle: AppTypography.inter(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.3),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                  const SizedBox(height: 16),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: const CircularProgressIndicator(
                          color: AppColors.primary,
                        ).animate().scale(duration: 400.ms),
                      ),
                    )
                  else if (_result.isNotEmpty)
                    GestureDetector(
                      onTap: _copyResult,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isError
                                ? [
                                    Colors.red.withValues(alpha: 0.1),
                                    Colors.red.withValues(alpha: 0.05),
                                  ]
                                : [
                                    AppColors.primary.withValues(alpha: 0.15),
                                    AppColors.primaryDark.withValues(
                                      alpha: 0.05,
                                    ),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isError
                                ? Colors.red.withValues(alpha: 0.3)
                                : (_isCopied
                                      ? Colors.greenAccent.withValues(
                                          alpha: 0.7,
                                        )
                                      : AppColors.primary.withValues(
                                          alpha: 0.3,
                                        )),
                            width: _isCopied ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isError
                                      ? 'TRANSLATION ERROR'
                                      : 'SANTALI (OL CHIKI)',
                                  style: AppTypography.inter(
                                    color: _isError
                                        ? Colors.redAccent
                                        : AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                if (!_isError)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isCopied
                                          ? Colors.greenAccent.withValues(
                                              alpha: 0.2,
                                            )
                                          : (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                                .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isCopied
                                            ? Colors.greenAccent
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isCopied
                                              ? Icons.check_rounded
                                              : Icons.copy_rounded,
                                          size: 13,
                                          color: _isCopied
                                              ? Colors.greenAccent
                                              : (isDark
                                                    ? Colors.white70
                                                    : Colors.black54),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isCopied ? 'COPIED!' : 'TAP TO COPY',
                                          style: AppTypography.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: _isCopied
                                                ? Colors.greenAccent
                                                : (isDark
                                                      ? Colors.white70
                                                      : Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _result,
                              style: _isError
                                  ? AppTypography.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    )
                                  : TextStyle(
                                      fontFamily: 'OlChiki',
                                      fontSize: 38,
                                      height: 1.15,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w900,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().scale(
                      begin: const Offset(0.97, 0.97),
                      curve: Curves.easeOutBack,
                    ),

                  if (_result.isEmpty && !_isLoading) ...[
                    const SizedBox(height: 16),
                    const RepaintBoundary(
                      child: NativeAdWidget(placement: 'translator_native'),
                    ),
                  ],
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),

          // Bottom Button - Animated visibility
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: AnimatedSlide(
              offset: _showTranslateButton ? Offset.zero : const Offset(0, 1.8),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: AnimatedOpacity(
                opacity: _showTranslateButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showTranslateButton,
                  child: DuoButton(
                    text: _isLoading
                        ? 'MAGIC IN PROGRESS...'
                        : 'TRANSLATE MAGIC',
                    onPressed: _translate,
                    height: 60,
                    borderRadius: 20,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isLoading,
              child: AnimatedOpacity(
                opacity: _isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                child: _isLoading
                    ? AiSparkAssistant(
                        key: const ValueKey('translator-fullscreen-spark'),
                        statusText: 'Translating into Santali…',
                        subheadText:
                            'Translating text into Ol Chiki… Tap spark ✨',
                        fullscreen: true,
                        light: isDark,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
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
