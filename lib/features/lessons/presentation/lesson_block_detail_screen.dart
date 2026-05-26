import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/parallax_hero_sliver_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/utils/media_type_resolver.dart';
import '../domain/entities/lesson_entity.dart';
import 'widgets/full_bleed_hero_media.dart';

class LessonBlockDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final int initialBlockIndex;

  const LessonBlockDetailScreen({
    super.key,
    required this.lessonId,
    required this.initialBlockIndex,
  });

  @override
  ConsumerState<LessonBlockDetailScreen> createState() =>
      _LessonBlockDetailScreenState();
}

class _LessonBlockDetailScreenState
    extends ConsumerState<LessonBlockDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isAudioPlaying = false;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialBlockIndex;
    _pageController = PageController(initialPage: _currentIndex);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // for iOS
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
      _isAudioPlaying = false;
      _playingId = null;
    });

    // Auto-play audio for the new block if available.
    final lessons = ref.read(learnerLessonsProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == widget.lessonId).firstOrNull;
    if (lesson != null && index >= 0 && index < lesson.blocks.length) {
      final block = lesson.blocks[index];
      final audioUrl = block.audioUrl;
      if (audioUrl != null && audioUrl.isNotEmpty) {
        _playAudio(
          audioUrl,
          '${block.textOlChiki ?? block.textLatin ?? block.type}_$index',
        );
      }
    }
  }

  void _playAudio(String url, String id) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAudioPlaying = true;
      _playingId = id;
    });

    await ref.read(audioServiceProvider).playUrl(url);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted && _playingId == id) {
      setState(() {
        _isAudioPlaying = false;
      });
    }
  }

  Color _parseThemeColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      final cleanHex = hexString.replaceFirst('#', '').trim();
      if (cleanHex.length == 6) {
        return Color(int.parse('0xFF$cleanHex'));
      } else if (cleanHex.length == 8) {
        return Color(int.parse('0x$cleanHex'));
      }
    } catch (_) {}
    return defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(learnerLessonsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return lessonsAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: _DetailLoadError(
          title: 'Could not load lesson details',
          isDark: isDark,
          onBack: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      data: (lessons) {
        final lesson = lessons
            .where((l) => l.id == widget.lessonId)
            .firstOrNull;
        if (lesson == null) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
            body: _DetailLoadError(
              title: 'Lesson not found',
              isDark: isDark,
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
          );
        }

        final contentBlocks = lesson.blocks;

        if (contentBlocks.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
            body: _DetailLoadError(
              title: 'No content blocks in this lesson',
              isDark: isDark,
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
          );
        }

        // Safe indexing
        final safeIndex = _currentIndex.clamp(0, contentBlocks.length - 1);
        final currentBlock = contentBlocks[safeIndex];

        // Parse custom color or fallback to brand neon green
        final rawThemeColor = currentBlock.data?['themeColor'] as String?;
        final blockThemeColor = _parseThemeColor(
          rawThemeColor,
          AppColors.primary,
        );

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
          body: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: contentBlocks.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final block = contentBlocks[index];
                    return _buildBlockContent(
                      block,
                      index,
                      blockThemeColor,
                      isDark,
                    );
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child:
                      currentBlock.audioUrl != null &&
                          currentBlock.audioUrl!.isNotEmpty
                      ? IconButton(
                          key: ValueKey<String>(
                            'audio_${lesson.id}_$safeIndex',
                          ),
                          icon: const Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => _playAudio(
                            currentBlock.audioUrl!,
                            '${currentBlock.textOlChiki ?? currentBlock.textLatin ?? currentBlock.type}_$safeIndex',
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: _buildPageIndicator(
                    contentBlocks.length,
                    blockThemeColor,
                    isDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _blockVisualMediaUrl(LessonBlockEntity block) {
    final data = block.data;
    final isVideo =
        block.type == 'video' || (data?['mediaType'] as String?) == 'video';
    final candidates = [
      if (isVideo) block.audioUrl,
      data?['heroMediaUrl'],
      data?['mediaUrl'],
      data?['videoUrl'],
      data?['animationUrl'],
      data?['htmlUrl'],
      data?['imageUrl'],
      block.imageUrl,
      if (!isVideo) block.audioUrl,
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        final value = candidate.trim();
        if (MediaTypeResolver.isRenderableHero(value)) return value;
      }
    }
    return null;
  }

  bool _isLottieMedia(String url) {
    return MediaTypeResolver.resolve(url) == MediaKind.lottie;
  }

  Widget _buildPageIndicator(int count, Color accentColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive
                ? accentColor
                : (isDark ? Colors.white30 : Colors.black26),
            borderRadius: BorderRadius.circular(5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    required Color themeColor,
    required bool isDark,
    double radius = 24,
    double padding = 20,
  }) {
    final isLight = themeColor.computeLuminance() > 0.55;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : (isLight
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.85));

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : (isLight
                        ? themeColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.5)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInlineMedia(String url, Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: FullBleedHeroMedia(
          animationUrl: _isLottieMedia(url) ? url : null,
          imageUrl: url,
          fallback: Icon(
            Icons.perm_media_rounded,
            size: 56,
            color: accentColor.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioCard(
    LessonBlockEntity block,
    int index,
    Color accentColor,
    bool isDark,
  ) {
    final label = block.textLatin?.trim().isNotEmpty == true
        ? block.textLatin!.trim()
        : 'Play audio';
    final isThisPlaying =
        _isAudioPlaying &&
        _playingId ==
            '${block.textOlChiki ?? block.textLatin ?? block.type}_$index';
    return _buildGlassCard(
      themeColor: accentColor,
      isDark: isDark,
      child: Row(
        children: [
          IconButton.filled(
            onPressed: () => _playAudio(
              block.audioUrl!,
              '${block.textOlChiki ?? block.textLatin ?? block.type}_$index',
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            style: IconButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          SoundWaveIndicator(
            color: isDark ? Colors.white : accentColor,
            isPlaying: isThisPlaying,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockContent(
    LessonBlockEntity block,
    int index,
    Color accentColor,
    bool isDark,
  ) {
    final textOlChiki = block.textOlChiki ?? '';
    final textLatin = block.textLatin ?? '';
    final pron = block.data?['pronunciation'] as String?;
    final displayText = pron != null && pron.isNotEmpty
        ? '$textLatin ($pron)'
        : textLatin;

    final glyph = textOlChiki.trim().isNotEmpty
        ? textOlChiki.trim().characters.first
        : (textLatin.trim().isNotEmpty
              ? textLatin.trim().characters.first
              : '');

    final animationUrl = _blockVisualMediaUrl(block);
    final isThisPlaying =
        _isAudioPlaying && _playingId == '${block.textOlChiki}_$index';

    return Builder(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final topHeight = constraints.maxHeight * 0.40;
            final bottomHeight = constraints.maxHeight * 0.60;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // Top Section: Green gradient
                    Container(
                      height: topHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.9),
                            accentColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (glyph.isNotEmpty)
                            Positioned(
                              right: -30,
                              bottom: -40,
                              child: Opacity(
                                opacity: 0.15,
                                child: Text(
                                  glyph,
                                  style: const TextStyle(
                                    fontSize: 260,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          if (animationUrl != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                48,
                                24,
                                60,
                              ),
                              child: FullBleedHeroMedia(
                                mediaKind: MediaTypeResolver.resolveFromType(
                                  block.data?['mediaType'] as String? ??
                                      block.type,
                                ),
                                animationUrl:
                                    (block.type == 'lottie' ||
                                        (block.data?['mediaType'] as String?) ==
                                            'lottie' ||
                                        _isLottieMedia(animationUrl))
                                    ? animationUrl
                                    : null,
                                imageUrl: animationUrl,
                                isSvg:
                                    block.type == 'svg' ||
                                    (block.data?['mediaType'] as String?) ==
                                        'svg',
                                fallback: Center(
                                  child: Icon(
                                    block.type == 'video' ||
                                            (block.data?['mediaType']
                                                    as String?) ==
                                                'video'
                                        ? Icons.videocam_rounded
                                        : (block.type == 'lottie' ||
                                                  (block.data?['mediaType']
                                                          as String?) ==
                                                      'lottie'
                                              ? Icons.animation_rounded
                                              : Icons.image_rounded),
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            left: 24,
                            bottom: 16,
                            child: Text(
                              displayText,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom Section: White or Dark surface
                    Container(
                      height: bottomHeight,
                      width: double.infinity,
                      color: isDark ? const Color(0xFF0A0E14) : Colors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 36),
                            // Large character card
                            Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          Colors.white.withValues(alpha: 0.04),
                                          Colors.white.withValues(alpha: 0.08),
                                        ]
                                      : [
                                          accentColor.withValues(alpha: 0.08),
                                          accentColor.withValues(alpha: 0.18),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : accentColor.withValues(alpha: 0.25),
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.25)
                                        : accentColor.withValues(alpha: 0.12),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  textOlChiki.isNotEmpty
                                      ? textOlChiki
                                      : textLatin,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize:
                                        (textOlChiki.isNotEmpty
                                                    ? textOlChiki
                                                    : textLatin)
                                                .length <
                                            3
                                        ? 72
                                        : 40,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : accentColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Pill button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 36,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayText.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (block.audioUrl != null &&
                                      block.audioUrl!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    SoundWaveIndicator(
                                      color: Colors.white,
                                      isPlaying: isThisPlaying,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (pron != null && pron.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _buildGlassCard(
                                  themeColor: accentColor,
                                  isDark: isDark,
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.record_voice_over_rounded,
                                            color: isDark
                                                ? Colors.white
                                                : accentColor,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Pronunciation',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        pron,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF2D3748),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DetailLoadError extends StatelessWidget {
  const _DetailLoadError({
    required this.title,
    required this.isDark,
    required this.onBack,
  });

  final String title;
  final bool isDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 22),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class SoundWaveIndicator extends ConsumerStatefulWidget {
  final Color color;
  final bool isPlaying;

  const SoundWaveIndicator({
    super.key,
    required this.color,
    required this.isPlaying,
  });

  @override
  ConsumerState<SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends ConsumerState<SoundWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(SoundWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    final reduceMotion = ref.read(reduceVisualEffectsProvider);
    if (widget.isPlaying && !reduceMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
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
    final reduceMotion = ref.watch(reduceVisualEffectsProvider);
    if (widget.isPlaying && !reduceMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }

    if (!widget.isPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 3,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final val = (index == 0 || index == 4)
                ? 0.3
                : (index == 1 || index == 3)
                ? 0.6
                : 0.9;
            final animatedValue = 6 + (20 * val * _controller.value);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: animatedValue.clamp(6.0, 24.0),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
