import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/audio/audio_service.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/widgets/lottie_display.dart';

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

  // Accent colors for letters
  static const List<Color> _accentColors = [
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFF673AB7),
    Color(0xFF009688),
    Color(0xFFFF5722),
  ];

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
      const Color(0xFFFFF0F5),
      const Color(0xFFF0F4FF),
      const Color(0xFFF5FFF0),
      const Color(0xFFFFFBE5),
      const Color(0xFFE3F2FD),
      const Color(0xFFEDE7F6),
      const Color(0xFFE0F7FA),
      const Color(0xFFFFF3E0),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final lettersAsync = ref.watch(lettersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return lettersAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: Center(child: Text('Error: $error')),
      ),
      data: (letters) {
        if (letters.isEmpty) {
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

        // Find initial index by letterId
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
        final accentColor = _getAccentColor(_currentIndex);
        final bgColor = _getBackgroundColor(_currentIndex, isDark);

        return Scaffold(
          backgroundColor: bgColor,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Stack(
            children: [
              // Full-screen PageView with swipe navigation
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: letters.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final letter = letters[index];
                  return _buildLetterPage(
                    letter,
                    index,
                    isDark,
                    statusBarHeight,
                  );
                },
              ),

              // Floating back button
              Positioned(
                top: statusBarHeight + 8,
                left: 16,
                child: _buildFloatingButton(
                  icon: Icons.arrow_back_rounded,
                  color: accentColor,
                  onTap: () => context.pop(),
                ),
              ),

              // Floating audio button
              if (currentLetter.audioUrl != null)
                Positioned(
                  top: statusBarHeight + 8,
                  right: 16,
                  child: _buildFloatingButton(
                    icon: Icons.volume_up_rounded,
                    color: accentColor,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref
                          .read(audioServiceProvider)
                          .playUrl(currentLetter.audioUrl!);
                    },
                  ),
                ),

              // Bottom page indicator
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: _buildPageIndicator(letters.length, accentColor, isDark),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              context.push(
                '/practice/${currentLetter.charOlChiki}/${currentLetter.transliterationLatin}',
              );
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

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8));
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

  Widget _buildLetterPage(
    LetterModel letter,
    int index,
    bool isDark,
    double statusBarHeight,
  ) {
    final accentColor = _getAccentColor(index);
    final emoji = _letterEmojis[letter.charOlChiki] ?? '📖';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, statusBarHeight + 70, 24, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Hero image/emoji
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
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
                    // Use animationUrl first, then imageUrl, otherwise fallback to emoji
                    child:
                        letter.animationUrl != null &&
                            letter.animationUrl!.isNotEmpty
                        ? LottieDisplay(
                            url: letter.animationUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          )
                        : letter.imageUrl != null && letter.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              letter.imageUrl!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, _, __) => Image.network(
                                _emojiToPngUrl(emoji),
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : Image.network(
                            _emojiToPngUrl(emoji),
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, _, __) => Text(
                              emoji,
                              style: const TextStyle(fontSize: 100),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Letter name/example
                Animate(
                  child: Text(
                    letter.exampleWordLatin ?? letter.transliterationLatin,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ).fadeIn(delay: 300.ms).scale(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Large Ol Chiki character
          Container(
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
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Romanization badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            child: Text(
              letter.transliterationLatin.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pronunciation hint
          if (letter.pronunciation != null && letter.pronunciation!.isNotEmpty)
            Container(
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
                    letter.pronunciation!,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          // Example word
          if (letter.exampleWordOlChiki != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.1),
                      accentColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Example',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      letter.exampleWordOlChiki!,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                    if (letter.exampleWordLatin != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        letter.exampleWordLatin!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
