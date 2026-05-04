import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/parallax_hero_sliver_app_bar.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/widgets/lottie_display.dart';

class WordDetailScreen extends ConsumerStatefulWidget {
  final String wordId;
  final String lessonId;

  const WordDetailScreen({
    super.key,
    required this.wordId,
    required this.lessonId,
  });

  @override
  ConsumerState<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends ConsumerState<WordDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  static const _emojiBaseUrl =
      'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72';

  // Fallback emoji mapping for words
  static const Map<String, String> _wordEmojis = {
    'ᱡᱚᱦᱟᱨ': '👋',
    'ᱥᱮᱨᱢᱟ': '🌅',
    'ᱵᱳᱭᱤᱱ': '👋',
    'ᱫᱷᱟᱱᱭᱟᱵᱟᱫ': '🙏',
    'ᱟᱯᱟ': '👨',
    'ᱟᱭᱳ': '👩',
    'ᱵᱳᱭᱦᱟ': '👦',
    'ᱢᱤᱥᱨᱟ': '👧',
    'ᱟᱢ ᱪᱮᱫᱟᱜ ᱢᱮᱱᱟᱜ ᱟ?': '🤔',
    'ᱤᱧ ᱵᱷᱟᱞᱮ ᱢᱮᱱᱟᱜ ᱟ': '😊',
    'ᱟᱢ ᱧᱩᱛᱩᱢ ᱪᱮᱫᱟᱜ?': '❓',
    'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ...': '🙋',
  };

  static const List<Color> _accentColors = [
    Color(0xFFFF9800),
    Color(0xFFFF5722),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    AppColors.duoBlue,
    Color(0xFF673AB7),
    Color(0xFF009688),
  ];

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
    setState(() => _currentIndex = index);
  }

  String _emojiToPngUrl(String emoji) {
    final runes = emoji.runes
        .where((rune) => rune != 0xFE0F)
        .map((rune) => rune.toRadixString(16))
        .join('-');
    return '$_emojiBaseUrl/$runes.png';
  }

  Color _getAccentColor(int index) {
    return _accentColors[index % _accentColors.length];
  }

  Color _getBackgroundColor(int index, bool isDark) {
    if (isDark) return const Color(0xFF0A0E14);
    final colors = [
      const Color(0xFFFFF8E1),
      const Color(0xFFFFF3E0),
      const Color(0xFFE3F2FD),
      const Color(0xFFE8F5E9),
      const Color(0xFFFCE4EC),
      const Color(0xFFF3E5F5),
      const Color(0xFFEDE7F6),
      const Color(0xFFE0F7FA),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return wordsAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: Center(child: Text('Error: $error')),
      ),
      data: (words) {
        if (words.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text('No words available')),
          );
        }

        // Find initial index
        if (_currentIndex == 0 && widget.wordId.isNotEmpty) {
          final index = words.indexWhere(
            (w) => w.id == widget.wordId || w.wordOlChiki == widget.wordId,
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
                itemCount: words.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final word = words[index];
                  return _buildWordPage(word, index, isDark);
                },
              ),

              // Page indicator
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: _buildPageIndicator(
                    words.length,
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
              final word = words[_currentIndex];
              context.push('/practice/${word.wordOlChiki}/${word.wordLatin}');
            },
            backgroundColor: accentColor,
            elevation: 4,
            child: const Icon(Icons.edit_note_rounded, color: Colors.white),
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

  Widget _buildWordPage(WordModel word, int index, bool isDark) {
    final accentColor = _getAccentColor(index);
    final emoji = _wordEmojis[word.wordOlChiki] ?? '📖';

    final heroIllustration = Hero(
      tag: MotionTokens.heroTag('word', word.id),
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
            child: word.animationUrl != null && word.animationUrl!.isNotEmpty
                ? LottieDisplay(
                    url: word.animationUrl!,
                    width: 150,
                    height: 150,
                  )
                : word.imageUrl != null && word.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      word.imageUrl!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, __) => Image.network(
                        _emojiToPngUrl(emoji),
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : Image.network(
                    _emojiToPngUrl(emoji),
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, _, __) => Text(
                      emoji,
                      style: const TextStyle(fontSize: 100),
                    ),
                  ),
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
          glyph: word.wordOlChiki.characters.isNotEmpty
              ? word.wordOlChiki.characters.first
              : null,
          title: Text(word.meaning),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (word.audioUrl != null)
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(audioServiceProvider).playUrl(word.audioUrl!);
                },
              ),
          ],
          expandedHeight: 300,
          heroChild: heroIllustration,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              if (word.category != null && word.category!.isNotEmpty)
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
                      word.category!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Ol Chiki word card with inline audio
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
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  word.wordOlChiki,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        word.wordLatin,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                    if (word.audioUrl != null) ...[
                      const SizedBox(width: 12),
                      PressableScale(
                        onTap: () {
                          ref
                              .read(audioServiceProvider)
                              .playUrl(word.audioUrl!);
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

          // Pronunciation hint
          if (word.pronunciation != null && word.pronunciation!.isNotEmpty)
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
                      word.pronunciation!,
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

          // Usage hint card
          if (word.usage != null && word.usage!.isNotEmpty)
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
                    word.usage!,
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
