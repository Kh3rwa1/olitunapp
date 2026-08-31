import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/utils/media_type_resolver.dart';
import '../../content/presentation/providers/audio_playback_providers.dart';
import '../../practice/data/typing_practice_settings.dart';
import '../../practice/presentation/providers/typing_practice_controller.dart';
import '../../quiz/domain/listening_quiz_generator.dart';
import '../domain/entities/lesson_entity.dart';
import 'widgets/lesson_block_detail/lesson_block_item_view.dart';
import 'widgets/lesson_block_detail/lesson_block_top_nav_bar.dart';
import 'widgets/lesson_block_widgets.dart';

/// Orchestrator screen for presenting lesson blocks in a fluid, swipeable flow.
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

    await ref
        .read(playbackControllerProvider)
        .playSingle(
          id: url,
          contentKind: 'lesson',
          contentId: id,
          trackType: 'targetNormal',
          languageCode: 'sat',
        );

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
        final injectListeningQuiz =
            !hasAuthoredQuiz &&
            ref.watch(featureFlagsProvider).audioQuizzesEnabled &&
            ListeningQuizGenerator.canGenerate(lesson);
        final contentBlocks = hasAuthoredQuiz
            ? rawBlocks
            : [
                ...rawBlocks,
                if (injectListeningQuiz)
                  LessonBlockEntity(
                    type: 'quiz',
                    textOlChiki: '',
                    textLatin: '',
                    data: {'quizId': 'listening_quiz_${lesson.id}'},
                  ),
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

        final safeIndex = _currentIndex.clamp(0, contentBlocks.length - 1);
        final currentBlock = contentBlocks[safeIndex];
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
                    physics: _resolveScrollPhysics(currentBlock, safeIndex),
                    itemBuilder: (context, index) {
                      final block = contentBlocks[index];
                      final pageRawColor = block.data?['themeColor'] as String?;
                      final pageThemeColor = _parseThemeColor(
                        pageRawColor,
                        AppColors.primary,
                      );
                      return LessonBlockItemView(
                        block: block,
                        index: index,
                        accentColor: pageThemeColor,
                        isDark: isDark,
                        lesson: lesson,
                        isDismissedQuiz: _dismissedQuizBlockIndices.contains(
                          index,
                        ),
                        isAudioPlaying: _isAudioPlaying,
                        playingId: _playingId,
                        onPlayAudio: _playAudio,
                        onDismissQuiz: () => setState(
                          () => _dismissedQuizBlockIndices.add(index),
                        ),
                        visualMediaUrl: _blockVisualMediaUrl(block),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: _buildTopNav(
                    currentBlock,
                    safeIndex,
                    contentBlocks.length,
                    blockThemeColor,
                    isDark,
                    lesson,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ScrollPhysics _resolveScrollPhysics(
    LessonBlockEntity currentBlock,
    int safeIndex,
  ) {
    final settings = ref.watch(typingPracticeSettingsProvider);
    final isCurrentEligible =
        settings.enabled &&
        (currentBlock.type == 'word' || currentBlock.type == 'sentence') &&
        currentBlock.type != 'rhyme' &&
        currentBlock.type != 'rhymes' &&
        currentBlock.textOlChiki != null &&
        currentBlock.textOlChiki!.isNotEmpty &&
        currentBlock.textOlChiki!.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F);

    if (isCurrentEligible) {
      final typingPracticeArgs = TypingPracticeArgs(
        itemKey:
            '${widget.lessonId}_${currentBlock.textOlChiki ?? currentBlock.textLatin ?? currentBlock.type}_$safeIndex',
        target: currentBlock.textOlChiki!,
        latin: currentBlock.textLatin ?? '',
        meaning: (currentBlock.data?['pronunciation'] as String?) ?? '',
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
  }

  Widget _buildTopNav(
    LessonBlockEntity currentBlock,
    int safeIndex,
    int totalSteps,
    Color blockThemeColor,
    bool isDark,
    LessonEntity lesson,
  ) {
    final settings = ref.watch(typingPracticeSettingsProvider);
    final isCurrentEligible =
        settings.enabled &&
        (currentBlock.type == 'word' || currentBlock.type == 'sentence') &&
        currentBlock.type != 'rhyme' &&
        currentBlock.type != 'rhymes' &&
        currentBlock.textOlChiki != null &&
        currentBlock.textOlChiki!.isNotEmpty &&
        currentBlock.textOlChiki!.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F);

    final typingPracticeArgs = isCurrentEligible
        ? TypingPracticeArgs(
            itemKey:
                '${widget.lessonId}_${currentBlock.textOlChiki ?? currentBlock.textLatin ?? currentBlock.type}_$safeIndex',
            target: currentBlock.textOlChiki!,
            latin: currentBlock.textLatin ?? '',
            meaning: (currentBlock.data?['pronunciation'] as String?) ?? '',
            contentType: currentBlock.type,
          )
        : null;

    final typingState = isCurrentEligible && typingPracticeArgs != null
        ? ref.watch(typingPracticeControllerProvider(typingPracticeArgs))
        : null;

    final isTypingActive =
        typingState != null && typingState.phase != TypingPhase.idle;

    return LessonBlockTopNavBar(
      totalSteps: totalSteps,
      currentStep: safeIndex,
      accentColor: blockThemeColor,
      isDark: isDark,
      hasAudio:
          currentBlock.audioUrl != null &&
          currentBlock.audioUrl!.isNotEmpty &&
          !isTypingActive,
      onAudioPressed: () => _playAudio(
        currentBlock.audioUrl!,
        '${currentBlock.textOlChiki ?? currentBlock.textLatin ?? currentBlock.type}_$safeIndex',
      ),
      audioKey: ValueKey<String>('audio_${lesson.id}_$safeIndex'),
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
  }
}
