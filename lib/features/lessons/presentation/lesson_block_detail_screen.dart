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
        statusBarIconBrightness: Brightness.dark,
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
    final lessons = ref.read(lessonNotifierProvider).value ?? [];
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
    final lessonsAsync = ref.watch(lessonNotifierProvider);
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

        final bgGradient = isDark
            ? LinearGradient(
                colors: [
                  blockThemeColor.withValues(alpha: 0.18),
                  const Color(0xFF08120E),
                  const Color(0xFF0A0E14),
                ],
                stops: const [0.0, 0.45, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  blockThemeColor.withValues(alpha: 0.12),
                  blockThemeColor.withValues(alpha: 0.04),
                  Colors.white,
                ],
                stops: const [0.0, 0.35, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

        final animationUrl = _blockVisualMediaUrl(currentBlock);

        final heroIllustration = AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey<String>('illustration_${lesson.id}_$safeIndex'),
            child: Hero(
              tag: MotionTokens.heroTag(
                'lesson_block',
                '${lesson.id}_$safeIndex',
              ),
              child: Material(
                type: MaterialType.transparency,
                child: FullBleedHeroMedia(
                  animationUrl:
                      animationUrl != null && _isLottieMedia(animationUrl)
                      ? animationUrl
                      : null,
                  imageUrl: animationUrl,
                  fallback: Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 100,
                      color: blockThemeColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final appBarTitle = AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            currentBlock.textLatin ?? lesson.titleLatin,
            key: ValueKey<String>('title_${lesson.id}_$safeIndex'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
          extendBody: true,
          body: Container(
            decoration: BoxDecoration(gradient: bgGradient),
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  ParallaxHeroSliverAppBar(
                    gradient: AppColors.heroGradient,
                    glyph:
                        animationUrl == null &&
                            currentBlock.textOlChiki != null &&
                            currentBlock.textOlChiki!.isNotEmpty
                        ? currentBlock.textOlChiki!.characters.first
                        : null,
                    title: appBarTitle,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/'),
                    ),
                    actions: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child:
                            currentBlock.audioUrl != null &&
                                currentBlock.audioUrl!.isNotEmpty
                            ? Padding(
                                key: ValueKey<String>(
                                  'audio_${lesson.id}_$safeIndex',
                                ),
                                padding: const EdgeInsets.only(right: 8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.volume_up_rounded),
                                  onPressed: () => _playAudio(
                                    currentBlock.audioUrl!,
                                    '${currentBlock.textOlChiki}_$safeIndex',
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                    expandedHeight: 320,
                    heroChild: heroIllustration,
                    heroChildFullBleed: true,
                  ),
                ];
              },
              body: Stack(
                children: [
                  PageView.builder(
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
            ),
          ),
        );
      },
    );
  }

  String? _blockVisualMediaUrl(LessonBlockEntity block) {
    final data = block.data;
    final candidates = [
      data?['heroMediaUrl'],
      data?['mediaUrl'],
      data?['videoUrl'],
      data?['animationUrl'],
      data?['htmlUrl'],
      data?['imageUrl'],
      block.imageUrl,
      if (block.type == 'video') block.audioUrl,
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
    const textContrastColor = Colors.white;
    final contentTextColor = isDark ? Colors.white70 : const Color(0xFF2D3748);
    final isThisPlaying =
        _isAudioPlaying && _playingId == '${block.textOlChiki}_$index';

    final textOlChiki = block.textOlChiki ?? '';
    final textLatin = block.textLatin ?? '';
    final pronunciation = block.data?['pronunciation'] as String?;

    return Builder(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: PrimaryScrollController.of(context),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_blockVisualMediaUrl(block) != null) ...[
                          _buildInlineMedia(
                            _blockVisualMediaUrl(block)!,
                            accentColor,
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (block.type == 'audio' &&
                            block.audioUrl != null &&
                            block.audioUrl!.isNotEmpty) ...[
                          _buildAudioCard(block, index, accentColor, isDark),
                          const SizedBox(height: 20),
                        ],
                        if (textOlChiki.isNotEmpty || textLatin.isNotEmpty) ...[
                          // Large Ol Chiki character card
                          Center(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 36,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withValues(alpha: 0.15),
                                    accentColor.withValues(alpha: 0.25),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
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
                                    fontSize: textOlChiki.length < 5 ? 46 : 28,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : accentColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Translation badge
                        if (textOlChiki.isNotEmpty && textLatin.isNotEmpty) ...[
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      textLatin.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: textContrastColor,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  if (block.audioUrl != null &&
                                      block.audioUrl!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    SoundWaveIndicator(
                                      color: textContrastColor,
                                      isPlaying: isThisPlaying,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Pronunciation guide card
                        if (pronunciation != null &&
                            pronunciation.isNotEmpty) ...[
                          _buildGlassCard(
                            themeColor: accentColor,
                            isDark: isDark,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                  pronunciation,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: contentTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
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
