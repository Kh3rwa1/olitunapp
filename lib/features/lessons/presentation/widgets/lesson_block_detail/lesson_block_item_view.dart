import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/practice/data/typing_practice_settings.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import 'package:itun/features/practice/presentation/widgets/typing_practice_panel.dart';
import 'package:itun/features/quiz/data/quiz_repository.dart';
import 'package:itun/shared/providers/providers.dart';
import 'lesson_block_card_content.dart';
import 'lesson_block_hero_header.dart';
import 'lesson_block_quiz_cta.dart';

/// Single item view within the lesson block PageView.
class LessonBlockItemView extends ConsumerWidget {
  const LessonBlockItemView({
    super.key,
    required this.block,
    required this.index,
    required this.accentColor,
    required this.isDark,
    required this.lesson,
    required this.isDismissedQuiz,
    required this.isAudioPlaying,
    required this.playingId,
    required this.onPlayAudio,
    required this.onDismissQuiz,
    required this.visualMediaUrl,
  });

  final LessonBlockEntity block;
  final int index;
  final Color accentColor;
  final bool isDark;
  final LessonEntity lesson;
  final bool isDismissedQuiz;
  final bool isAudioPlaying;
  final String? playingId;
  final void Function(String url, String id) onPlayAudio;
  final VoidCallback onDismissQuiz;
  final String? visualMediaUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (block.type == 'quiz') {
      final quizId =
          block.data?['quizId'] as String? ??
          block.data?['quizRefId'] as String? ??
          '';
      if (quizId.isEmpty || isDismissedQuiz) {
        return const SizedBox.shrink();
      }

      if (quizId.startsWith('listening_quiz_')) {
        final quiz = ref.watch(listeningLessonQuizProvider(lesson));
        if (quiz.questions.isEmpty) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) => LessonBlockQuizCTA(
            quizId: quizId,
            quiz: quiz,
            accentColor: accentColor,
            isDark: isDark,
            maxHeight: constraints.maxHeight,
            onDismiss: onDismissQuiz,
          ),
        );
      }

      if (quizId.startsWith('dynamic_quiz_')) {
        final quiz = ref.watch(dynamicLessonQuizProvider(lesson));
        return LayoutBuilder(
          builder: (context, constraints) => LessonBlockQuizCTA(
            quizId: quizId,
            quiz: quiz,
            accentColor: accentColor,
            isDark: isDark,
            maxHeight: constraints.maxHeight,
            onDismiss: onDismissQuiz,
          ),
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
              if (!quizzesMap.containsKey(quizId))
                return const SizedBox.shrink();
              final quiz = quizzesMap[quizId]!;
              return LayoutBuilder(
                builder: (context, constraints) => LessonBlockQuizCTA(
                  quizId: quizId,
                  quiz: quiz,
                  accentColor: accentColor,
                  isDark: isDark,
                  maxHeight: constraints.maxHeight,
                  onDismiss: onDismissQuiz,
                ),
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
                '${lesson.id}_${block.textOlChiki ?? block.textLatin ?? block.type}_$index',
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

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                LessonBlockHeroHeader(
                  block: block,
                  accentColor: accentColor,
                  isDark: isDark,
                  topHeight: topHeight,
                  blendColor: blendColor,
                  displayText: displayText,
                  glyph: glyph,
                  isLongText: isLongText,
                  animationUrl: visualMediaUrl,
                ),
                LessonBlockCardContent(
                  block: block,
                  index: index,
                  accentColor: accentColor,
                  isDark: isDark,
                  lesson: lesson,
                  displayText: displayText,
                  isAudioPlaying: isAudioPlaying,
                  playingId: playingId,
                  onPlayAudio: onPlayAudio,
                  typingPracticeArgs: typingPracticeArgs,
                  isEligibleForTyping: isEligible,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
