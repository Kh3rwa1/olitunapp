part of 'lesson_block_detail_screen.dart';

/// Extracted navigation and scrolling physics helpers for [_LessonBlockDetailScreenState].
extension _LessonBlockDetailNav on _LessonBlockDetailScreenState {
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
