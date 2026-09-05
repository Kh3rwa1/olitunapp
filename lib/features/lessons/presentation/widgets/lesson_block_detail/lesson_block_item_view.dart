import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/languages/ol_chiki_multilingual_helper.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
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
      if (quizId.isEmpty) {
        // Authored block without a quiz reference: explain instead of a
        // blank page so the learner can keep moving through the lesson.
        return _InlineQuizUnavailable(
          isDark: isDark,
          accentColor: accentColor,
          isError: false,
          onSkip: onDismissQuiz,
        );
      }

      if (quizId.startsWith('listening_quiz_')) {
        final quiz = ref.watch(listeningLessonQuizProvider(lesson));
        if (quiz.questions.isEmpty) {
          return _InlineQuizUnavailable(
            isDark: isDark,
            accentColor: accentColor,
            isError: false,
            onSkip: onDismissQuiz,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) => LessonBlockQuizCTA(
            quizId: quizId,
            quiz: quiz,
            accentColor: accentColor,
            isDark: isDark,
            maxHeight: constraints.maxHeight,
            onDismiss: onDismissQuiz,
            isDismissed: isDismissedQuiz,
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
            isDismissed: isDismissedQuiz,
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
            error: (err, _) => _InlineQuizUnavailable(
              isDark: isDark,
              accentColor: accentColor,
              isError: true,
              onSkip: onDismissQuiz,
              onRetry: () => ref.invalidate(quizzesProvider),
            ),
            data: (quizzesMap) {
              if (!quizzesMap.containsKey(quizId)) {
                return _InlineQuizUnavailable(
                  isDark: isDark,
                  accentColor: accentColor,
                  isError: false,
                  onSkip: onDismissQuiz,
                );
              }
              final quiz = quizzesMap[quizId]!;
              return LayoutBuilder(
                builder: (context, constraints) => LessonBlockQuizCTA(
                  quizId: quizId,
                  quiz: quiz,
                  accentColor: accentColor,
                  isDark: isDark,
                  maxHeight: constraints.maxHeight,
                  onDismiss: onDismissQuiz,
                  isDismissed: isDismissedQuiz,
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

    final teachingLanguage = ref.watch(effectiveTeachingLanguageProvider);
    final scriptMode = ref.watch(effectiveScriptModeProvider);

    final display = OlChikiMultilingualHelper.resolveBlockDisplay(
      textOlChiki: block.textOlChiki,
      textLatin: block.textLatin,
      textBengali: block.textBengali,
      textHindi: block.textHindi,
      textOdia: block.textOdia,
      explicitMeaning:
          block.data?['meaning_$teachingLanguage'] as String? ??
          block.data?['meaning'] as String?,
      explicitPronunciation: block.data?['pronunciation'] as String?,
      teachingLanguage: teachingLanguage,
      scriptMode: scriptMode,
    );

    final cleanScript = display.scriptText.trim();
    final glyph = (cleanScript.isNotEmpty && cleanScript.length <= 4)
        ? cleanScript.characters.first
        : '';

    final displayText = display.title;
    final isLongText = displayText.length > 18 || displayText.contains('\n');

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

/// Inline replacement for [LessonBlockQuizCTA] shown when an embedded quiz
/// block cannot render: a missing quiz reference, an unknown quiz id, or a
/// failed quiz load. Never a blank page — the learner always sees an
/// explanation and a way forward (retry the load and/or skip back into the
/// lesson flow via [onSkip]).
class _InlineQuizUnavailable extends StatelessWidget {
  const _InlineQuizUnavailable({
    required this.isDark,
    required this.accentColor,
    required this.isError,
    required this.onSkip,
    this.onRetry,
  });

  final bool isDark;
  final Color accentColor;
  final bool isError;
  final VoidCallback onSkip;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = isError ? l10n.somethingWentWrong : l10n.noQuestionsYet;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.quiz_outlined,
              size: 56,
              semanticLabel: title,
              color: isError
                  ? AppColors.error.withValues(alpha: 0.8)
                  : accentColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.retry),
                ),
              ),
            if (onRetry != null) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.skip,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
