import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/animations/scale_button.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/utils/media_type_resolver.dart';
import '../../../shared/models/content/quiz_model.dart';
import '../../quiz/data/quiz_repository.dart';
import '../domain/entities/lesson_entity.dart';
import 'widgets/full_bleed_hero_media.dart';
import '../../practice/presentation/widgets/typing_practice_panel.dart';
import '../../practice/presentation/providers/typing_practice_controller.dart';
import '../../practice/data/typing_practice_settings.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';

import 'widgets/lesson_block_widgets.dart';

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
  final Set<int> _dismissedQuizBlockIndices = {};

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
        body: DetailLoadErrorBlock(
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
            body: DetailLoadErrorBlock(
              title: 'Lesson not found',
              isDark: isDark,
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
          );
        }

        final rawBlocks = lesson.blocks;
        final hasAuthoredQuiz = rawBlocks.any((b) => b.type == 'quiz');
        final contentBlocks = hasAuthoredQuiz
            ? rawBlocks
            : [
                ...rawBlocks,
                LessonBlockEntity(
                  type: 'quiz',
                  textOlChiki: '',
                  textLatin: '',
                  data: {'quizId': 'dynamic_quiz_${lesson.id}'},
                ),
              ];

        if (contentBlocks.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
            body: DetailLoadErrorBlock(
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
                  const Color(0xFF080B12),
                  blockThemeColor.withValues(alpha: 0.08),
                  const Color(0xFF0D121F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  blockThemeColor.withValues(alpha: 0.05),
                  const Color(0xFFF3F5F9),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

        return Scaffold(
          bottomNavigationBar: const BannerAdWidget(
            placement: 'lesson_block_bottom',
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(gradient: bgGradient),
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: contentBlocks.length,
                    physics: (() {
                      final settings = ref.watch(
                        typingPracticeSettingsProvider,
                      );
                      final isCurrentEligible =
                          settings.enabled &&
                          (currentBlock.type == 'word' ||
                              currentBlock.type == 'sentence') &&
                          currentBlock.type != 'rhyme' &&
                          currentBlock.type != 'rhymes' &&
                          currentBlock.textOlChiki != null &&
                          currentBlock.textOlChiki!.isNotEmpty &&
                          currentBlock.textOlChiki!.runes.any(
                            (r) => r >= 0x1C50 && r <= 0x1C7F,
                          );

                      if (isCurrentEligible) {
                        final typingPracticeArgs = TypingPracticeArgs(
                          itemKey:
                              '${widget.lessonId}_${currentBlock.textOlChiki ?? currentBlock.textLatin ?? currentBlock.type}_$safeIndex',
                          target: currentBlock.textOlChiki!,
                          latin: currentBlock.textLatin ?? '',
                          meaning:
                              (currentBlock.data?['pronunciation']
                                  as String?) ??
                              '',
                          contentType: currentBlock.type,
                        );
                        final typingState = ref.watch(
                          typingPracticeControllerProvider(typingPracticeArgs),
                        );
                        if (typingState.phase != TypingPhase.idle) {
                          return const NeverScrollableScrollPhysics();
                        }
                      }
                      return const BouncingScrollPhysics();
                    })(),
                    itemBuilder: (context, index) {
                      final block = contentBlocks[index];
                      final pageRawColor = block.data?['themeColor'] as String?;
                      final pageThemeColor = _parseThemeColor(
                        pageRawColor,
                        AppColors.primary,
                      );
                      return _buildBlockContent(
                        block,
                        index,
                        pageThemeColor,
                        isDark,
                        lesson,
                      );
                    },
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: () {
                    final settings = ref.watch(typingPracticeSettingsProvider);
                    final isCurrentEligible =
                        settings.enabled &&
                        (currentBlock.type == 'word' ||
                            currentBlock.type == 'sentence') &&
                        currentBlock.type != 'rhyme' &&
                        currentBlock.type != 'rhymes' &&
                        currentBlock.textOlChiki != null &&
                        currentBlock.textOlChiki!.isNotEmpty &&
                        currentBlock.textOlChiki!.runes.any(
                          (r) => r >= 0x1C50 && r <= 0x1C7F,
                        );

                    final typingPracticeArgs = isCurrentEligible
                        ? TypingPracticeArgs(
                            itemKey:
                                '${widget.lessonId}_${currentBlock.textOlChiki ?? currentBlock.textLatin ?? currentBlock.type}_$safeIndex',
                            target: currentBlock.textOlChiki!,
                            latin: currentBlock.textLatin ?? '',
                            meaning:
                                (currentBlock.data?['pronunciation']
                                    as String?) ??
                                '',
                            contentType: currentBlock.type,
                          )
                        : null;

                    final typingState =
                        isCurrentEligible && typingPracticeArgs != null
                        ? ref.watch(
                            typingPracticeControllerProvider(
                              typingPracticeArgs,
                            ),
                          )
                        : null;

                    final isTypingActive =
                        typingState != null &&
                        typingState.phase != TypingPhase.idle;

                    return _buildTopNavBar(
                      context,
                      contentBlocks.length,
                      safeIndex,
                      blockThemeColor,
                      isDark,
                      currentBlock.audioUrl != null &&
                          currentBlock.audioUrl!.isNotEmpty &&
                          !isTypingActive,
                      () => _playAudio(
                        currentBlock.audioUrl!,
                        '${currentBlock.textOlChiki ?? currentBlock.textLatin ?? currentBlock.type}_$safeIndex',
                      ),
                      ValueKey<String>('audio_${lesson.id}_$safeIndex'),
                      backIcon: isTypingActive ? Icons.close_rounded : null,
                      onBackPressed: isTypingActive
                          ? () {
                              ref
                                  .read(
                                    typingPracticeControllerProvider(
                                      typingPracticeArgs!,
                                    ).notifier,
                                  )
                                  .tryAgain();
                            }
                          : null,
                    );
                  }(),
                ),
              ],
            ),
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

  Widget _buildFloatingButton({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBar(
    BuildContext context,
    int totalSteps,
    int currentStep,
    Color accentColor,
    bool isDark,
    bool hasAudio,
    VoidCallback? onAudioPressed,
    ValueKey<String>? audioKey, {
    VoidCallback? onBackPressed,
    IconData? backIcon,
  }) {
    final progress = (totalSteps > 0) ? (currentStep + 1) / totalSteps : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFloatingButton(
            icon: backIcon ?? Icons.arrow_back_rounded,
            onPressed:
                onBackPressed ??
                () async {
                  await ref
                      .read(interstitialAdManagerProvider)
                      .showIfAllowed(context, 'lesson_complete');
                  if (context.mounted) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  }
                },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * progress,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.7),
                            accentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 44,
            height: 44,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasAudio && onAudioPressed != null
                  ? _buildFloatingButton(
                      key: audioKey,
                      icon: Icons.volume_up_rounded,
                      onPressed: onAudioPressed,
                    )
                  : const SizedBox.shrink(),
            ),
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
    LessonEntity lesson,
  ) {
    if (block.type == 'quiz') {
      final quizId =
          block.data?['quizId'] as String? ??
          block.data?['quizRefId'] as String? ??
          '';
      if (quizId.isEmpty || _dismissedQuizBlockIndices.contains(index)) {
        return const SizedBox.shrink();
      }

      if (quizId.startsWith('dynamic_quiz_')) {
        final quiz = ref.watch(dynamicLessonQuizProvider(lesson));
        return LayoutBuilder(
          builder: (context, constraints) {
            return _buildQuizBlockCTA(
              context,
              quizId,
              quiz,
              accentColor,
              isDark,
              constraints.maxHeight,
              index,
            );
          },
        );
      }

      return ref
          .watch(quizzesByIdProvider)
          .when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            error: (err, _) => const SizedBox.shrink(),
            data: (quizzesMap) {
              if (!quizzesMap.containsKey(quizId)) {
                return const SizedBox.shrink();
              }
              final quiz = quizzesMap[quizId]!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  return _buildQuizBlockCTA(
                    context,
                    quizId,
                    quiz,
                    accentColor,
                    isDark,
                    constraints.maxHeight,
                    index,
                  );
                },
              );
            },
          );
    }

    final settings = ref.watch(typingPracticeSettingsProvider);
    final bool isEligible =
        settings.enabled &&
        (block.type == 'word' || block.type == 'sentence') &&
        block.type != 'rhyme' &&
        block.type != 'rhymes' &&
        block.textOlChiki != null &&
        block.textOlChiki!.isNotEmpty &&
        block.textOlChiki!.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F);

    final typingPracticeArgs = isEligible
        ? TypingPracticeArgs(
            itemKey:
                '${widget.lessonId}_${block.textOlChiki ?? block.textLatin ?? block.type}_$index',
            target: block.textOlChiki!,
            latin: block.textLatin ?? '',
            meaning: (block.data?['pronunciation'] as String?) ?? '',
            contentType: block.type,
          )
        : null;

    final typingState = isEligible && typingPracticeArgs != null
        ? ref.watch(typingPracticeControllerProvider(typingPracticeArgs))
        : null;

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

    final cardText = textOlChiki.isNotEmpty ? textOlChiki : textLatin;
    final isLongText = cardText.length > 6 || cardText.contains(' ');
    final isButtonLong = displayText.length > 15;
    final buttonText = isButtonLong ? 'LISTEN' : displayText.toUpperCase();

    final animationUrl = _blockVisualMediaUrl(block);
    final isThisPlaying =
        _isAudioPlaying &&
        _playingId ==
            '${block.textOlChiki ?? block.textLatin ?? block.type}_$index';

    return Builder(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (isEligible &&
                typingState != null &&
                typingState.phase != TypingPhase.idle) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 80,
                      left: 20,
                      right: 20,
                      bottom: 40,
                    ),
                    child: TypingPracticePanel(
                      args: typingPracticeArgs!,
                      audioUrl: block.audioUrl,
                    ),
                  ),
                ),
              );
            }

            final topHeight = constraints.maxHeight * 0.44;
            final blendColor = isDark
                ? const Color(0xFF0F1422)
                : const Color(0xFFF5F7FB);

            final titleTextColor = (animationUrl != null)
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF1E293B));

            final badgeBgColor = (animationUrl != null)
                ? Colors.white.withValues(alpha: 0.15)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : accentColor.withValues(alpha: 0.08));

            final badgeTextColor = (animationUrl != null)
                ? Colors.white
                : (isDark ? Colors.white70 : accentColor);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // Top Section: Cinematic Green/Theme Gradient
                    Container(
                      height: topHeight,
                      width: double.infinity,
                      decoration: animationUrl == null
                          ? null
                          : BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withValues(alpha: 0.85),
                                  accentColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (glyph.isNotEmpty)
                            Positioned(
                              right: -20,
                              top: -20,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: animationUrl != null ? 0.06 : 0.14,
                                  child: Text(
                                    glyph,
                                    style: TextStyle(
                                      fontSize: 240,
                                      fontWeight: FontWeight.w900,
                                      color: animationUrl != null
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white
                                                : accentColor),
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (animationUrl != null) ...[
                            // Edge-to-Edge Hero Media
                            Positioned.fill(
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
                            // Dark elegant gradient overlay for text readability + blending bottom edge
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.45),
                                        Colors.transparent,
                                        Colors.transparent,
                                        blendColor,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.25, 0.75, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          // Title Overlay Text
                          Positioned(
                            left: 24,
                            bottom: 12,
                            right: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: animationUrl != null
                                        ? null
                                        : Border.all(
                                            color: badgeTextColor.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                  ),
                                  child: Text(
                                    (block.data?['mediaType'] as String? ??
                                            block.type)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: badgeTextColor,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  displayText,
                                  style: TextStyle(
                                    fontSize: isLongText ? 20 : 32,
                                    fontWeight: FontWeight.w900,
                                    color: titleTextColor,
                                    shadows: animationUrl != null
                                        ? [
                                            const Shadow(
                                              color: Colors.black38,
                                              offset: Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom Section: Translucent surface (Fluid layout, no nested scroll)
                    Container(
                      width: double.infinity,
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          // Large character card with entrance & optional loop breathing animation
                          ScaleButton(
                            onPressed:
                                block.audioUrl != null &&
                                    block.audioUrl!.isNotEmpty
                                ? () => _playAudio(
                                    block.audioUrl!,
                                    '${block.textOlChiki ?? block.textLatin ?? block.type}_$index',
                                  )
                                : null,
                            child: () {
                              final isTest =
                                  !kIsWeb &&
                                  Platform.environment.containsKey(
                                    'FLUTTER_TEST',
                                  );
                              Widget content;
                              if (isLongText || (textOlChiki.isNotEmpty && textLatin.isNotEmpty) || cardText.contains('\n')) {
                                final isMultiLine = cardText.contains('\n') || cardText.length > 60;
                                content = Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (textOlChiki.isNotEmpty)
                                        Text(
                                          textOlChiki,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: isMultiLine ? 24 : 32,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : accentColor,
                                            fontFamily: 'OlChiki',
                                            height: 1.35,
                                            shadows: [
                                              Shadow(
                                                color: isDark
                                                    ? Colors.black.withValues(
                                                        alpha: 0.3,
                                                      )
                                                    : accentColor.withValues(
                                                        alpha: 0.15,
                                                      ),
                                                offset: const Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (textOlChiki.isNotEmpty &&
                                          textLatin.isNotEmpty &&
                                          textLatin != textOlChiki) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          textLatin,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: isMultiLine ? 16 : 18,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF475569),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                      if (textOlChiki.isEmpty && textLatin.isNotEmpty)
                                        Text(
                                          textLatin,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: isMultiLine ? 17 : 26,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : accentColor,
                                            height: 1.35,
                                          ),
                                        ),
                                      if (textOlChiki.isEmpty && textLatin.isEmpty)
                                        Text(
                                          lesson.titleLatin,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : accentColor,
                                          ),
                                        ),
                                      if (block.audioUrl != null &&
                                          block.audioUrl!.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.06,
                                                  )
                                                : accentColor.withValues(
                                                    alpha: 0.06,
                                                  )),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : accentColor.withValues(
                                                      alpha: 0.1,
                                                    )),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.volume_up_rounded,
                                                color: isDark
                                                    ? Colors.white70
                                                    : accentColor,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'TAP TO HEAR',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : accentColor,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              } else {
                                content = Container(
                                  width: 210,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(36),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer Glow Ring
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              36,
                                            ),
                                            border: Border.all(
                                              color: (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.05,
                                                    )
                                                  : accentColor.withValues(
                                                      alpha: 0.15,
                                                    )),
                                              width: 2.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: accentColor.withValues(
                                                  alpha: isDark ? 0.15 : 0.2,
                                                ),
                                                blurRadius: 28,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Glass body
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            36,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 16,
                                              sigmaY: 16,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isDark
                                                      ? [
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.06,
                                                              ),
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.02,
                                                              ),
                                                        ]
                                                      : [
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.45,
                                                              ),
                                                        ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(36),
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.1,
                                                        )
                                                      : Colors.white.withValues(
                                                          alpha: 0.6,
                                                        ),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  // Subtle Watermark
                                                  CustomPaint(
                                                    size: const Size(210, 210),
                                                    painter: LessonBlockWatermarkPainter(
                                                      text:
                                                          textOlChiki.isNotEmpty
                                                          ? textOlChiki
                                                          : textLatin,
                                                      style: TextStyle(
                                                        fontSize: 160,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            (isDark
                                                                    ? Colors
                                                                          .white
                                                                    : accentColor)
                                                                .withValues(
                                                                  alpha: 0.04,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Main Character Text
                                                  Text(
                                                    textOlChiki.isNotEmpty
                                                        ? textOlChiki
                                                        : textLatin,
                                                    style: TextStyle(
                                                      fontSize:
                                                          (textOlChiki.isNotEmpty
                                                                      ? textOlChiki
                                                                      : textLatin)
                                                                  .length <
                                                              3
                                                          ? 84
                                                          : 44,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: isDark
                                                          ? Colors.white
                                                          : accentColor,
                                                      shadows: [
                                                        Shadow(
                                                          color: isDark
                                                              ? Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    )
                                                              : accentColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.15,
                                                                    ),
                                                          offset: const Offset(
                                                            0,
                                                            3,
                                                          ),
                                                          blurRadius: 6,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Pulsing speaker icon
                                                  Positioned(
                                                    top: 16,
                                                    right: 16,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: (isDark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  )
                                                            : accentColor
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  )),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: (isDark
                                                              ? Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    )
                                                              : accentColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    )),
                                                        ),
                                                      ),
                                                      child: Icon(
                                                        Icons.volume_up_rounded,
                                                        color: isDark
                                                            ? Colors.white70
                                                            : accentColor,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  // Tap to Hear Badge
                                                  Positioned(
                                                    bottom: 16,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: (isDark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.06,
                                                                  )
                                                            : accentColor
                                                                  .withValues(
                                                                    alpha: 0.06,
                                                                  )),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                        border: Border.all(
                                                          color: (isDark
                                                              ? Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    )
                                                              : accentColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    )),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'TAP TO HEAR',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: isDark
                                                              ? Colors.white70
                                                              : accentColor,
                                                          letterSpacing: 1.2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              content = content
                                  .animate()
                                  .fade(
                                    duration: const Duration(milliseconds: 500),
                                  )
                                  .slide(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutCubic,
                                  );

                              if (!isTest) {
                                content = content
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(reverse: true),
                                    )
                                    .scale(
                                      begin: const Offset(1.0, 1.0),
                                      end: const Offset(1.04, 1.04),
                                      duration: const Duration(
                                        milliseconds: 2400,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                              }
                              return content;
                            }(),
                          ),
                          const SizedBox(height: 32),
                          // Tactile 3D Action Button
                          Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: isEligible
                                ? Tactile3DButton(
                                    color: AppColors.primary,
                                    onPressed: () {
                                      ref
                                          .read(
                                            typingPracticeControllerProvider(
                                              typingPracticeArgs!,
                                            ).notifier,
                                          )
                                          .startPractice();
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.keyboard_outlined,
                                          color: Colors.black,
                                        ),
                                        SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            'PRACTICE TYPING',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Tactile3DButton(
                                    color: accentColor,
                                    onPressed:
                                        block.audioUrl != null &&
                                            block.audioUrl!.isNotEmpty
                                        ? () => _playAudio(
                                            block.audioUrl!,
                                            '${block.textOlChiki ?? block.textLatin ?? block.type}_$index',
                                          )
                                        : null,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            buttonText.length > 15
                                                ? 'LISTEN'
                                                : buttonText.toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 1.5,
                                            ),
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
                          ),
                          if (pron != null && pron.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _buildGlassCard(
                                themeColor: accentColor,
                                isDark: isDark,
                                radius: 20,
                                padding: 18,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.hearing_rounded,
                                                color: isDark
                                                    ? Colors.white70
                                                    : accentColor,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Pronunciation',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : accentColor,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            pron,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              height: 1.4,
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.9,
                                                    )
                                                  : const Color(0xFF1A202C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: RepaintBoundary(
                              child: NativeAdWidget(
                                placement: 'lesson_block_native',
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 100,
                          ), // elegant bottom padding for unified scroll spacing
                        ],
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

  Widget _buildQuizBlockCTA(
    BuildContext context,
    String quizId,
    QuizModel quiz,
    Color accentColor,
    bool isDark,
    double maxHeight,
    int index,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: _buildGlassCard(
              themeColor: accentColor,
              isDark: isDark,
              radius: 28,
              padding: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration Icon Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: accentColor,
                      size: 38,
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 24),
                  // Title / Prompt
                  Text(
                    'Ready to test yourself?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Great job! Take "${quiz.title ?? 'the quiz'}" now to test your knowledge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action buttons
                  Tactile3DButton(
                    color: accentColor,
                    onPressed: () {
                      context.push('/quiz/$quizId');
                    },
                    child: Text(
                      'TAKE THE QUIZ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color:
                            ThemeData.estimateBrightnessForColor(accentColor) ==
                                Brightness.light
                            ? Colors.black
                            : Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _dismissedQuizBlockIndices.add(index);
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
