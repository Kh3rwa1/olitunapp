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
import '../../../shared/models/content_models.dart';
import '../../../core/utils/text_match.dart';
import '../domain/entities/lesson_entity.dart';
import 'widgets/full_bleed_hero_media.dart';

class LetterDetailScreen extends ConsumerStatefulWidget {
  final String letterId;
  final String lessonId;

  const LetterDetailScreen({
    super.key,
    required this.letterId,
    required this.lessonId,
  });

  @override
  ConsumerState<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends ConsumerState<LetterDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  // Sound play state
  bool _isAudioPlaying = false;
  String? _playingId;

  // Fallback emoji mapping for letters that don't have imageUrl
  static const Map<String, String> _letterEmojis = {
    'ᱚ': '🌅',
    'ᱟ': '👨',
    'ᱤ': '🙋',
    'ᱩ': '🥭',
    'ᱮ': '🚶',
    'ᱳ': '✍️',
    'ᱠ': '👧',
    'ᱜ': '🏞️',
    'ᱝ': '☀️',
    'ᱪ': '🌙',
    'ᱡ': '🍇',
    'ᱛ': '⭐',
    'ᱞ': '📖',
  };

  static const _emojiBaseUrl =
      'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72';

  @override
  void initState() {
    super.initState();
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
  }

  String _emojiToPngUrl(String emoji) {
    final runes = emoji.runes
        .where((rune) => rune != 0xFE0F)
        .map((rune) => rune.toRadixString(16))
        .join('-');
    return '$_emojiBaseUrl/$runes.png';
  }

  Color _parseThemeColor(String? colorStr, Color fallback) {
    if (colorStr == null || colorStr.isEmpty) return fallback;
    try {
      var hex = colorStr.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    } catch (_) {}
    return fallback;
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

  List<LetterModel> _scopeLettersToLesson(
    List<LetterModel> allLetters,
    LessonEntity? lesson,
  ) {
    if (lesson == null || lesson.blocks.isEmpty) {
      return allLetters.where((l) => l.isActive).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    final blockTexts = lesson.blocks
        .where((b) => b.type == 'text' && b.textOlChiki != null)
        .map((b) => b.textOlChiki!.trim())
        .toSet();

    if (blockTexts.isEmpty) return const [];

    return allLetters
        .where(
          (l) =>
              l.isActive &&
              blockTexts.any(
                (t) => isTextMatch(t, l.charOlChiki, isLetter: true),
              ),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    final lettersAsync = ref.watch(lettersProvider);
    final lessonsAsync = ref.watch(lessonNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return lettersAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: _DetailLoadError(
          title: 'Could not load letters',
          isDark: isDark,
          onBack: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      data: (allLetters) {
        final lessons = lessonsAsync.value ?? [];
        final lesson = lessons
            .where((l) => l.id == widget.lessonId)
            .firstOrNull;
        final letters = _scopeLettersToLesson(allLetters, lesson);

        if (letters.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No letters available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add letters from the admin panel',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (_currentIndex == 0 && widget.letterId.isNotEmpty) {
          final index = letters.indexWhere(
            (l) => l.id == widget.letterId || l.charOlChiki == widget.letterId,
          );
          if (index >= 0 && _currentIndex != index) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _currentIndex = index);
                _pageController.jumpToPage(index);
              }
            });
          }
        }

        final currentLetter = letters[_currentIndex];
        final accentColor = _parseThemeColor(
          currentLetter.themeColor,
          AppColors.primary,
        );
        const textContrastColor = Colors.white;

        final bgColor = isDark
            ? const Color(0xFF0A0E14)
            : const Color(0xFFF8FAFC);

        return Scaffold(
          backgroundColor: bgColor,
          extendBody: true,
          body: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: letters.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final letter = letters[index];
                  return _buildLetterPage(letter, index, isDark);
                },
              ),

              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: _buildPageIndicator(
                    letters.length,
                    accentColor,
                    isDark,
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              final practiceChar = Uri.encodeComponent(
                currentLetter.charOlChiki,
              );
              final practiceName = Uri.encodeComponent(
                currentLetter.transliterationLatin,
              );
              context.push('/practice/$practiceChar/$practiceName');
            },
            backgroundColor: accentColor,
            elevation: 4,
            child: const Icon(Icons.edit_note_rounded, color: textContrastColor),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
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

  Widget _buildLetterPage(LetterModel letter, int index, bool isDark) {
    final accentColor = _parseThemeColor(letter.themeColor, AppColors.primary);
    const textContrastColor = Colors.white;
    final contentTextColor = isDark ? Colors.white70 : const Color(0xFF2D3748);

    final emoji = _letterEmojis[letter.charOlChiki] ?? '📖';
    final isThisPlaying = _isAudioPlaying && _playingId == letter.id;

    final heroIllustration = Hero(
      tag: MotionTokens.heroTag('letter', letter.id),
      child: Material(
        type: MaterialType.transparency,
        child: FullBleedHeroMedia(
          animationUrl: letter.animationUrl,
          imageUrl: letter.imageUrl,
          fallback: Image.network(
            _emojiToPngUrl(emoji),
            width: 168,
            height: 168,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, _, _) =>
                Text(emoji, style: const TextStyle(fontSize: 120)),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            ParallaxHeroSliverAppBar(
              gradient: AppColors.heroGradient,
              glyph: letter.charOlChiki,
              title: Text(
                letter.exampleWordLatin ?? letter.transliterationLatin,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
              actions: [
                if (letter.audioUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.volume_up_rounded),
                      onPressed: () => _playAudio(letter.audioUrl!, letter.id),
                    ),
                  ),
              ],
              expandedHeight: 300,
              heroChild: heroIllustration,
              heroChildFullBleed: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  // Large Ol Chiki character
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.15),
                            accentColor.withValues(alpha: 0.25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(36),
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
                          letter.charOlChiki,
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Romanization badge
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
                          Text(
                            letter.transliterationLatin.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textContrastColor,
                              letterSpacing: 2,
                            ),
                          ),
                          if (letter.audioUrl != null) ...[
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

                  // Pronunciation hint
                  if (letter.pronunciation != null &&
                      letter.pronunciation!.isNotEmpty) ...[
                    _buildGlassCard(
                      themeColor: accentColor,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.record_voice_over_rounded,
                                color: isDark ? Colors.white : accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pronunciation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            letter.pronunciation!,
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

                  // Example word
                  if (letter.exampleWordOlChiki != null)
                    _buildGlassCard(
                      themeColor: accentColor,
                      isDark: isDark,
                      child: Column(
                        children: [
                          Text(
                            'Example Word',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (isDark ? Colors.white : accentColor)
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            letter.exampleWordOlChiki!,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : accentColor,
                            ),
                          ),
                          if (letter.exampleWordLatin != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              letter.exampleWordLatin!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: contentTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ],
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
              color: widget.color.withValues(alpha: 0.5),
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
            final val = (index * 0.25 + _controller.value) % 1.0;
            final double height = 6.0 + 16.0 * (0.5 - (0.5 - val).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: height,
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
