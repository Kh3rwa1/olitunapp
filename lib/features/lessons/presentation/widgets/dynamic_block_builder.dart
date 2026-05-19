import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../core/presentation/animations/scale_button.dart';
import '../../domain/entities/lesson_entity.dart';

/// Robust fuzzy matching for Ol Chiki text against entity labels.
bool _isFuzzyMatch(String target, String entityText) {
  if (entityText.isEmpty) return false;
  final t = target.trim().toLowerCase();
  final e = entityText.trim().toLowerCase();

  if (t == e) return true;

  final separators = [' ', '-', '–', '—', '−', '.', '!', '?', ':', ';'];
  for (final s in separators) {
    if (t.startsWith('$e$s')) return true;
  }

  final tokens = t.split(RegExp(r'[\s\-\–\—\−\.\!\?\:\;]'));
  if (tokens.isNotEmpty && tokens.first == e) return true;

  final tClean = t.replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '').trim();
  final eClean = e.replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '').trim();
  if (tClean == eClean && tClean.isNotEmpty) return true;

  return false;
}

/// Renders a single dynamic content block (text, image, quiz, lottie).
class DynamicBlockBuilder extends ConsumerWidget {
  final String lessonId;
  final LessonBlockEntity block;

  const DynamicBlockBuilder({
    super.key,
    required this.lessonId,
    required this.block,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (block.type) {
      case 'text':
        return _TextBlock(lessonId: lessonId, block: block, isDark: isDark);
      case 'image':
      case 'svg':
        return _ImageBlock(block: block, isDark: isDark);
      case 'quiz':
        return _QuizBlock(block: block);
      case 'lottie':
        return _LottieBlock(block: block, isDark: isDark);
      case 'video':
      case 'webm':
        return _VideoBlock(block: block, isDark: isDark);
      case 'html':
        return _HtmlBlock(block: block, isDark: isDark);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Text block with fuzzy-match navigation to letters/numbers/words/sentences.
class _TextBlock extends ConsumerWidget {
  final String lessonId;
  final LessonBlockEntity block;
  final bool isDark;

  const _TextBlock({
    required this.lessonId,
    required this.block,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textOlChiki = block.textOlChiki?.trim();
    if (textOlChiki == null || textOlChiki.isEmpty) {
      return const SizedBox.shrink();
    }

    final navRoute = _resolveNavRoute(ref, lessonId, textOlChiki);

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: navRoute != null
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.1),
          width: navRoute != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.textOlChiki!,
                  style: TextStyle(
                    fontSize: (block.textOlChiki!.length < 5) ? 36 : 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
                if (block.textLatin != null && block.textLatin!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    block.textLatin!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (navRoute != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );

    if (navRoute != null) {
      final route = navRoute;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ScaleButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(route);
          },
          child: content,
        ),
      );
    }
    return content;
  }

  String? _resolveNavRoute(WidgetRef ref, String lessonId, String text) {
    // Check Letters
    final letters = ref.read(lettersProvider).value ?? [];
    final matchedLetter = letters
        .where((l) => _isFuzzyMatch(text, l.charOlChiki))
        .firstOrNull;
    if (matchedLetter != null) {
      return '/letter/$lessonId/${matchedLetter.charOlChiki}';
    }

    // Check Numbers
    final numbers = ref.read(numbersProvider).value ?? [];
    final matchedNumber = numbers.where((n) {
      return _isFuzzyMatch(text, n.numeral) ||
          _isFuzzyMatch(text, n.value.toString());
    }).firstOrNull;
    if (matchedNumber != null) {
      return '/number/$lessonId/${matchedNumber.id}';
    }

    // Check Words
    final words = ref.read(wordsProvider).value ?? [];
    final matchedWord = words
        .where((w) => _isFuzzyMatch(text, w.wordOlChiki))
        .firstOrNull;
    if (matchedWord != null) {
      return '/word/$lessonId/${matchedWord.id}';
    }

    // Check Sentences
    final sentences = ref.read(sentencesProvider).value ?? [];
    final matchedSentence = sentences
        .where((s) => _isFuzzyMatch(text, s.sentenceOlChiki))
        .firstOrNull;
    if (matchedSentence != null) {
      return '/sentence/$lessonId/${matchedSentence.id}';
    }

    return null;
  }
}

/// Image content block with caption, supporting standard images (WebP/PNG/JPG) and SVGs dynamically.
class _ImageBlock extends StatelessWidget {
  final LessonBlockEntity block;
  final bool isDark;

  const _ImageBlock({required this.block, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final url = block.imageUrl ?? '';
    final isSvg = url.toLowerCase().endsWith('.svg') || block.type == 'svg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          isSvg
              ? SvgPicture.network(
                  url,
                  width: double.infinity,
                  placeholderBuilder: (BuildContext context) => Container(
                    height: 200,
                    color: Colors.grey.withValues(alpha: 0.05),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: const Center(child: Icon(Icons.broken_image_rounded)),
                    );
                  },
                ),
          if (block.textLatin != null && block.textLatin!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              block.textLatin!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quiz CTA block that navigates to the quiz screen.
class _QuizBlock extends StatelessWidget {
  final LessonBlockEntity block;

  const _QuizBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final quizRefId = block.data?['quizRefId'] as String?;
    return ScaleButton(
      onPressed: () {
        if (quizRefId != null) {
          context.push('/quiz/$quizRefId');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.premiumPurple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.quiz_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Take a Quiz',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Test your knowledge now!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Interactive Lottie animation block supporting play/pause on tap,
/// double-tap reset and replay, speed multiplier selection, and loop toggling.
class _LottieBlock extends StatefulWidget {
  final LessonBlockEntity block;
  final bool isDark;

  const _LottieBlock({required this.block, required this.isDark});

  @override
  State<_LottieBlock> createState() => _LottieBlockState();
}

class _LottieBlockState extends State<_LottieBlock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true;
  bool _isLooping = true;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isLooping) {
          _controller.repeat();
        } else {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.forward();
      } else {
        _controller.stop();
      }
    });
  }

  void _resetAndPlay() {
    HapticFeedback.mediumImpact();
    _controller.reset();
    _controller.forward();
    setState(() {
      _isPlaying = true;
    });
  }

  void _setSpeed(double speed) {
    HapticFeedback.selectionClick();
    setState(() {
      _speed = speed;
      _controller.duration = Duration(milliseconds: (2000 / _speed).round());
      if (_isPlaying) {
        _controller.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final animationUrl = widget.block.data?['animationUrl'] as String? ?? widget.block.imageUrl;
    if (animationUrl == null || animationUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            onDoubleTap: _resetAndPlay,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.network(
                    animationUrl,
                    width: double.infinity,
                    height: 200,
                    controller: _controller,
                    onLoaded: (composition) {
                      _controller.duration = composition.duration;
                      _controller.repeat();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.withValues(alpha: 0.1),
                        child: const Center(child: Icon(Icons.broken_image_rounded)),
                      );
                    },
                  ),
                ),
                
                // Play/Pause subtle floating state indicator overlay
                AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Interactive controls bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speed selector
              Row(
                children: [0.5, 1.0, 1.5, 2.0].map((s) {
                  final isSelected = _speed == s;
                  return GestureDetector(
                    onTap: () => _setSpeed(s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${s}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (widget.isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Action buttons (Reset, Loop)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_rounded, size: 20),
                    onPressed: _resetAndPlay,
                    tooltip: 'Reset animation',
                  ),
                  IconButton(
                    icon: Icon(
                      _isLooping ? Icons.loop_rounded : Icons.play_disabled_rounded,
                      size: 20,
                      color: _isLooping ? AppColors.primary : Colors.grey,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isLooping = !_isLooping;
                      });
                    },
                    tooltip: 'Toggle loop',
                  ),
                ],
              ),
            ],
          ),

          if (widget.block.textLatin != null && widget.block.textLatin!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.block.textLatin!,
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark ? Colors.white54 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Video and WebM player block with elegant progress bar and volume toggles.
class _VideoBlock extends StatefulWidget {
  final LessonBlockEntity block;
  final bool isDark;

  const _VideoBlock({required this.block, required this.isDark});

  @override
  State<_VideoBlock> createState() => _VideoBlockState();
}

class _VideoBlockState extends State<_VideoBlock> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.block.imageUrl ?? widget.block.data?['videoUrl'] as String?;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: AspectRatio(
              aspectRatio: _isInitialized ? _controller!.value.aspectRatio : 16 / 9,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  _isInitialized
                      ? VideoPlayer(_controller!)
                      : Container(
                          color: Colors.black.withValues(alpha: 0.05),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                  
                  if (_isInitialized)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showControls = !_showControls;
                        });
                      },
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Stack(
                            children: [
                              Center(
                                child: ScaleButton(
                                  onPressed: _togglePlay,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _controller!.value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: IconButton(
                                  icon: Icon(
                                    _isMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: _toggleMute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isInitialized)
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppColors.primary,
                      bufferedColor: AppColors.primary.withValues(alpha: 0.25),
                      backgroundColor: widget.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                if (widget.block.textLatin != null && widget.block.textLatin!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.block.textLatin!,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic HTML rendering block. Parses standard block and inline HTML tags natively in pure Flutter.
class _HtmlBlock extends StatelessWidget {
  final LessonBlockEntity block;
  final bool isDark;

  const _HtmlBlock({required this.block, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final htmlContent = block.data?['htmlContent'] as String? ?? block.textLatin ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parseHtmlToWidgets(htmlContent, isDark),
      ),
    );
  }

  List<Widget> _parseHtmlToWidgets(String htmlText, bool isDark) {
    final List<Widget> widgets = [];
    final String cleanText = htmlText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final RegExp blockRegExp = RegExp(
      r'(<(h[1-6]|p|ul|li|br|pre|div|a)[^>]*>[\s\S]*?<\/\2>|<br\s*\/?>)',
      caseSensitive: false,
    );

    if (!cleanText.contains('<')) {
      widgets.add(Text(
        cleanText,
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ));
      return widgets;
    }

    int lastIndex = 0;
    for (final Match match in blockRegExp.allMatches(cleanText)) {
      if (match.start > lastIndex) {
        final plainText = cleanText.substring(lastIndex, match.start).trim();
        if (plainText.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _renderInlineHtml(plainText, isDark, 15, FontWeight.normal, null),
          ));
        }
      }

      final blockText = match.group(0)!;
      final tagName = match.group(2)?.toLowerCase();

      if (tagName == 'br') {
        widgets.add(const SizedBox(height: 8));
      } else {
        final contentStartIndex = blockText.indexOf('>') + 1;
        final contentEndIndex = blockText.lastIndexOf('</');
        final content = contentStartIndex < contentEndIndex
            ? blockText.substring(contentStartIndex, contentEndIndex)
            : '';

        if (tagName == 'h1') {
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: _renderInlineHtml(content, isDark, 24, FontWeight.w800, AppColors.primary),
          ));
        } else if (tagName == 'h2') {
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: _renderInlineHtml(content, isDark, 20, FontWeight.w700, isDark ? Colors.white : Colors.black),
          ));
        } else if (tagName == 'h3') {
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: _renderInlineHtml(content, isDark, 18, FontWeight.w600, isDark ? Colors.white : Colors.black),
          ));
        } else if (tagName == 'p') {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _renderInlineHtml(content, isDark, 15, FontWeight.normal, isDark ? Colors.white70 : Colors.black87),
          ));
        } else if (tagName == 'li') {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold)),
                Expanded(child: _renderInlineHtml(content, isDark, 15, FontWeight.normal, isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
          ));
        } else if (tagName == 'pre') {
          widgets.add(Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _renderInlineHtml(content, isDark, 14, FontWeight.normal, isDark ? Colors.white70 : Colors.black87, isMonospace: true),
          ));
        } else if (tagName == 'div') {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _renderInlineHtml(content, isDark, 15, FontWeight.normal, isDark ? Colors.white70 : Colors.black87),
          ));
        }
      }

      lastIndex = match.end;
    }

    if (lastIndex < cleanText.length) {
      final remainingText = cleanText.substring(lastIndex).trim();
      if (remainingText.isNotEmpty) {
        widgets.add(_renderInlineHtml(remainingText, isDark, 15, FontWeight.normal, null));
      }
    }

    return widgets;
  }

  Widget _renderInlineHtml(
    String text,
    bool isDark,
    double baseFontSize,
    FontWeight baseFontWeight,
    Color? baseColor, {
    bool isMonospace = false,
  }) {
    final List<TextSpan> spans = [];

    final RegExp inlineRegExp = RegExp(
      r'(<(b|strong|i|em|u|span)[^>]*>([\s\S]*?)<\/\2>|([^<]+))',
      caseSensitive: false,
    );

    for (final Match match in inlineRegExp.allMatches(text)) {
      final tagMatch = match.group(2);
      final tagContent = match.group(3);
      final plainText = match.group(4);

      if (plainText != null && plainText.isNotEmpty) {
        spans.add(TextSpan(
          text: plainText,
          style: TextStyle(
            fontSize: baseFontSize,
            fontWeight: baseFontWeight,
            color: baseColor ?? (isDark ? Colors.white70 : Colors.black87),
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ));
      } else if (tagContent != null) {
        final String tag = tagMatch!.toLowerCase();
        FontWeight fw = baseFontWeight;
        FontStyle fs = FontStyle.normal;
        TextDecoration dec = TextDecoration.none;
        Color? col = baseColor;

        if (tag == 'b' || tag == 'strong') {
          fw = FontWeight.bold;
        } else if (tag == 'i' || tag == 'em') {
          fs = FontStyle.italic;
        } else if (tag == 'u') {
          dec = TextDecoration.underline;
        } else if (tag == 'span') {
          final fullTag = match.group(1) ?? '';
          final colorMatch = RegExp(r'color\s*:\s*([^;"]+)', caseSensitive: false).firstMatch(fullTag);
          if (colorMatch != null) {
            final colorStr = colorMatch.group(1)!.trim().toLowerCase();
            if (colorStr.startsWith('#')) {
              try {
                final hex = colorStr.replaceAll('#', '');
                col = Color(int.parse('FF$hex', radix: 16));
              } catch (_) {}
            } else if (colorStr == 'primary') {
              col = AppColors.primary;
            } else if (colorStr == 'red') {
              col = Colors.red;
            } else if (colorStr == 'green') {
              col = Colors.green;
            } else if (colorStr == 'blue') {
              col = Colors.blue;
            }
          }
        }

        spans.add(TextSpan(
          text: tagContent,
          style: TextStyle(
            fontSize: baseFontSize,
            fontWeight: fw,
            fontStyle: fs,
            decoration: dec,
            color: col ?? (isDark ? Colors.white70 : Colors.black87),
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
