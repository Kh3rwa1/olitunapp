import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/parallax_hero_sliver_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../core/utils/text_match.dart';
import '../../domain/entities/lesson_entity.dart';
import '../widgets/full_bleed_hero_media.dart';

class NumberDetailScreen extends ConsumerStatefulWidget {
  final String numberId;
  final String lessonId;

  const NumberDetailScreen({
    super.key,
    required this.numberId,
    required this.lessonId,
  });

  @override
  ConsumerState<NumberDetailScreen> createState() => _NumberDetailScreenState();
}

class _NumberDetailScreenState extends ConsumerState<NumberDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  // Sound play state
  bool _isAudioPlaying = false;
  String? _playingId;

  static const _emojiBaseUrl =
      'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72';

  // Fallback emoji mapping for numbers
  static const Map<String, String> _numberEmojis = {
    '᱑': '☝️',
    '᱒': '✌️',
    '': '🤟',
    '᱔': '🍀',
    '᱕': '🖐️',
    '᱖': '🎲',
    '᱗': '🌈',
    '᱘': '🎱',
    '᱙': '🕘',
    '᱑᱐': '🔟',
  };

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

  /// Scope numbers to only those referenced by the lesson's content blocks.
  List<NumberModel> _scopeNumbersToLesson(
    List<NumberModel> allNumbers,
    LessonEntity? lesson,
  ) {
    if (lesson == null || lesson.blocks.isEmpty) {
      return allNumbers.where((n) => n.isActive).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    final blockTexts = lesson.blocks
        .where((b) => b.type == 'text' && b.textOlChiki != null)
        .map((b) => b.textOlChiki!.trim())
        .toSet();

    if (blockTexts.isEmpty) {
      return const [];
    }

    final matched =
        allNumbers
            .where(
              (n) =>
                  n.isActive &&
                  blockTexts.any(
                    (t) =>
                        isTextMatch(t, n.numeral) ||
                        isTextMatch(t, n.value.toString()) ||
                        isTextMatch(t, n.nameOlChiki) ||
                        isTextMatch(t, n.nameLatin),
                  ),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return matched;
  }

  @override
  Widget build(BuildContext context) {
    final numbersAsync = ref.watch(numbersProvider);
    final lessonsAsync = ref.watch(lessonNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return numbersAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: _DetailLoadError(
          title: 'Could not load numbers',
          isDark: isDark,
          onBack: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      data: (allNumbers) {
        final lessons = lessonsAsync.value ?? [];
        final lesson = lessons
            .where((l) => l.id == widget.lessonId)
            .firstOrNull;
        final numbers = _scopeNumbersToLesson(allNumbers, lesson);

        if (numbers.isEmpty) {
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
                  Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No numbers in this lesson.\nAdd content blocks in admin.',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (_currentIndex == 0 && widget.numberId.isNotEmpty) {
          final index = numbers.indexWhere(
            (n) =>
                n.id == widget.numberId ||
                n.numeral == widget.numberId ||
                n.value.toString() == widget.numberId,
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

        final currentNumber = numbers[_currentIndex];
        final accentColor = _parseThemeColor(
          currentNumber.themeColor,
          AppColors.duoBlue,
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
                itemCount: numbers.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final number = numbers[index];
                  return _buildNumberPage(number, index, isDark);
                },
              ),

              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: _buildPageIndicator(
                    numbers.length,
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
              final number = numbers[_currentIndex];
              final practiceChar = Uri.encodeComponent(number.numeral);
              final practiceName = Uri.encodeComponent(number.nameLatin);
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

  Widget _buildNumberPage(NumberModel number, int index, bool isDark) {
    final accentColor = _parseThemeColor(number.themeColor, AppColors.duoBlue);
    const textContrastColor = Colors.white;
    final contentTextColor = isDark ? Colors.white70 : const Color(0xFF2D3748);

    final emoji = _numberEmojis[number.numeral] ?? '🔢';
    final isThisPlaying = _isAudioPlaying && _playingId == number.id;

    final heroIllustration = Hero(
      tag: MotionTokens.heroTag('number', number.id),
      child: Material(
        type: MaterialType.transparency,
        child: FullBleedHeroMedia(
          animationUrl: number.animationUrl,
          imageUrl: number.imageUrl,
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
              gradient: AppColors.skyBlueGradient,
              glyph: number.numeral,
              title: Text(number.nameLatin),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
              actions: [
                if (number.audioUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.volume_up_rounded),
                      onPressed: () => _playAudio(number.audioUrl!, number.id),
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
                  Center(
                    child: Text(
                      'Number ${number.value}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Large Ol Chiki number
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
                      child:
                          Animate(
                                child: Center(
                                  child: Text(
                                    number.numeral,
                                    style: TextStyle(
                                      fontSize: 80,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : accentColor,
                                    ),
                                  ),
                                ),
                              )
                              .scale(delay: 600.ms, curve: Curves.easeOutBack)
                              .fadeIn(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ol Chiki name badge
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
                            number.nameOlChiki,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textContrastColor,
                              letterSpacing: 1,
                            ),
                          ),
                          if (number.audioUrl != null) ...[
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
                  if (number.pronunciation != null &&
                      number.pronunciation!.isNotEmpty) ...[
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
                            number.pronunciation!,
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

                  // Value representation (animated dots)
                  _buildGlassCard(
                    themeColor: accentColor,
                    isDark: isDark,
                    child: Column(
                      children: [
                        Text(
                          'Count',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: (isDark ? Colors.white : accentColor)
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                            number.value,
                            (i) =>
                                Animate(
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              accentColor,
                                              accentColor.withValues(
                                                alpha: 0.7,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: accentColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .fadeIn(
                                      delay: Duration(
                                        milliseconds: 800 + (i * 80),
                                      ),
                                    )
                                    .scale(
                                      begin: const Offset(0, 0),
                                      curve: Curves.easeOutBack,
                                      delay: Duration(
                                        milliseconds: 800 + (i * 80),
                                      ),
                                    ),
                          ),
                        ),
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
