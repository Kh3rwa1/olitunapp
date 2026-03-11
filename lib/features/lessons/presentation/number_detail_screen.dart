import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/audio/audio_service.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/widgets/lottie_display.dart';

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

  static const _emojiBaseUrl =
      'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72';

  // Fallback emoji mapping for numbers
  static const Map<String, String> _numberEmojis = {
    '᱑': '☝️',
    '᱒': '✌️',
    '᱓': '🤟',
    '᱔': '🍀',
    '᱕': '🖐️',
    '᱖': '🎲',
    '᱗': '🌈',
    '᱘': '🎱',
    '᱙': '🕘',
    '᱑᱐': '🔟',
  };

  static const List<Color> _accentColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    AppColors.duoBlue,
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF607D8B),
    Color(0xFF455A64),
    Color(0xFFFF5722),
    Color(0xFFF44336),
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
      const Color(0xFFE3F2FD),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF8E1),
      const Color(0xFFF3E5F5),
      const Color(0xFFFCE4EC),
      const Color(0xFFE0F7FA),
      const Color(0xFFFAFAFA),
      const Color(0xFFECEFF1),
      const Color(0xFFFFF3E0),
      const Color(0xFFFFEBEE),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final numbersAsync = ref.watch(numbersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return numbersAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: Center(child: Text('Error: $error')),
      ),
      data: (numbers) {
        if (numbers.isEmpty) {
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
            body: const Center(child: Text('No numbers available')),
          );
        }

        // Find initial index
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

        final accentColor = _getAccentColor(_currentIndex);
        final bgColor = _getBackgroundColor(_currentIndex, isDark);

        return Scaffold(
          backgroundColor: bgColor,
          extendBodyBehindAppBar: true,
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
                  return _buildNumberPage(
                    number,
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
              if (numbers[_currentIndex].audioUrl != null)
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
                          .playUrl(numbers[_currentIndex].audioUrl!);
                    },
                  ),
                ),

              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: _buildPageIndicator(numbers.length, accentColor, isDark),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              final number = numbers[_currentIndex];
              context.push('/practice/${number.numeral}/${number.nameLatin}');
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
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                      color: accentColor.withOpacity(0.4),
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

  Widget _buildNumberPage(
    NumberModel number,
    int index,
    bool isDark,
    double statusBarHeight,
  ) {
    final accentColor = _getAccentColor(index);
    final emoji = _numberEmojis[number.numeral] ?? '🔢';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, statusBarHeight + 70, 24, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Hero illustration
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
                    child:
                        number.animationUrl != null &&
                            number.animationUrl!.isNotEmpty
                        ? LottieDisplay(
                            url: number.animationUrl!,
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                          )
                        : number.imageUrl != null && number.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              number.imageUrl!,
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, _, __) => Image.network(
                                _emojiToPngUrl(emoji),
                                width: 180,
                                height: 180,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : Image.network(
                            _emojiToPngUrl(emoji),
                            width: 180,
                            height: 180,
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

                // Name with animation
                Animate(
                  child: Text(
                    number.nameLatin,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: -1.0,
                    ),
                  ),
                ).fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                Text(
                  'Number ${number.value}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Large Ol Chiki number
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.15),
                  accentColor.withOpacity(0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: accentColor.withOpacity(0.4), width: 4),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Animate(
              child: Center(
                child: Text(
                  number.numeral,
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ).scale(delay: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          ),
          const SizedBox(height: 20),

          // Ol Chiki name badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.4),
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
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                if (number.audioUrl != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(audioServiceProvider).playUrl(number.audioUrl!);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pronunciation hint
          if (number.pronunciation != null && number.pronunciation!.isNotEmpty)
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
                    number.pronunciation!,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Value representation (animated dots)
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
              children: [
                Text(
                  'Count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor.withValues(alpha: 0.8),
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
                                      accentColor.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .fadeIn(
                              delay: Duration(milliseconds: 800 + (i * 80)),
                            )
                            .scale(
                              begin: const Offset(0, 0),
                              curve: Curves.easeOutBack,
                              delay: Duration(milliseconds: 800 + (i * 80)),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
