import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/parallax_hero_sliver_app_bar.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/widgets/lottie_display.dart';

class SentenceDetailScreen extends ConsumerStatefulWidget {
  final String sentenceId;
  final String lessonId;

  const SentenceDetailScreen({
    super.key,
    required this.sentenceId,
    required this.lessonId,
  });

  @override
  ConsumerState<SentenceDetailScreen> createState() =>
      _SentenceDetailScreenState();
}

class _SentenceDetailScreenState extends ConsumerState<SentenceDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  static const List<Color> _accentColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF00C9A7),
    Color(0xFFFFB347),
    Color(0xFF4FC3F7),
    Color(0xFFE040FB),
    Color(0xFF69F0AE),
    Color(0xFFFF8A80),
  ];

  static const List<String> _sentenceEmojis = [
    '💬',
    '🗣️',
    '📝',
    '✨',
    '🌟',
    '💭',
    '📢',
    '🎯',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.selectionClick();
  }

  Color _getAccentColor(int index) =>
      _accentColors[index % _accentColors.length];

  Color _getBackgroundColor(int index, bool isDark) {
    final accent = _getAccentColor(index);
    return isDark
        ? Color.lerp(Colors.black, accent, 0.06) ?? Colors.black
        : Color.lerp(Colors.white, accent, 0.04) ?? Colors.white;
  }

  String _getEmoji(int index) =>
      _sentenceEmojis[index % _sentenceEmojis.length];

  @override
  Widget build(BuildContext context) {
    final sentencesAsync = ref.watch(sentencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return sentencesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (allSentences) {
        final sentences = allSentences.where((s) => s.isActive).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (sentences.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sentences')),
            body: const Center(child: Text('No sentences found')),
          );
        }

        // Find initial index
        final startIndex = sentences.indexWhere(
          (s) => s.id == widget.sentenceId,
        );
        if (startIndex >= 0 && _pageController.hasClients == false) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients && _currentIndex != startIndex) {
              _pageController.jumpToPage(startIndex);
              setState(() => _currentIndex = startIndex);
            }
          });
        }

        final accentColor = _getAccentColor(_currentIndex);
        final bgColor = _getBackgroundColor(_currentIndex, isDark);

        return Scaffold(
          backgroundColor: bgColor,
          extendBody: true,
          body: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: sentences.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final sentence = sentences[index];
                  return _buildSentencePage(sentence, index, isDark);
                },
              ),

              // Page indicator
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: _buildPageIndicator(
                    sentences.length,
                    accentColor,
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

  Widget _buildPageIndicator(int count, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildSentencePage(SentenceModel sentence, int index, bool isDark) {
    final accentColor = _getAccentColor(index);
    final emoji = _getEmoji(index);

    final heroIllustration = Hero(
      tag: MotionTokens.heroTag('sentence', sentence.id),
      child: Material(
        type: MaterialType.transparency,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -0.06, end: 0.06),
            duration: const Duration(milliseconds: 1700),
            curve: Curves.easeInOut,
            builder: (context, turn, child) {
              return Transform.rotate(angle: turn, child: child);
            },
            onEnd: () {
              if (mounted) setState(() {});
            },
            child:
                sentence.animationUrl != null &&
                    sentence.animationUrl!.isNotEmpty
                ? LottieDisplay(
                    url: sentence.animationUrl!,
                    width: 130,
                    height: 130,
                  )
                : sentence.imageUrl != null && sentence.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      sentence.imageUrl!,
                      width: 130,
                      height: 130,
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, __) =>
                          Text(emoji, style: const TextStyle(fontSize: 90)),
                    ),
                  )
                : Text(emoji, style: const TextStyle(fontSize: 90)),
          ),
        ),
      ),
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        ParallaxHeroSliverAppBar(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withValues(alpha: 0.78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          glyph: emoji,
          title: Text(sentence.meaning),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (sentence.audioUrl != null)
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(audioServiceProvider).playUrl(sentence.audioUrl!);
                },
              ),
          ],
          heroChild: heroIllustration,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              if (sentence.category != null && sentence.category!.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sentence.category!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Ol Chiki sentence card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.1),
                      accentColor.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          color: accentColor.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ol Chiki',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sentence.sentenceOlChiki,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 1,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            sentence.sentenceLatin,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (sentence.audioUrl != null) ...[
                          const SizedBox(width: 12),
                          PressableScale(
                            onTap: () {
                              ref
                                  .read(audioServiceProvider)
                                  .playUrl(sentence.audioUrl!);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pronunciation section
              if (sentence.pronunciation != null &&
                  sentence.pronunciation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.record_voice_over_rounded,
                              color: accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pronunciation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          sentence.pronunciation!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Usage / context card
              if (sentence.usage != null && sentence.usage!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.08),
                        accentColor.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: accentColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'When to use',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        sentence.usage!,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}
