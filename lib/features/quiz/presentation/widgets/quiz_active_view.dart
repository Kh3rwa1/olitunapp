import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/languages/providers/target_language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/widgets/state_widgets.dart';
import '../../../content/presentation/providers/audio_playback_providers.dart';
import '../providers/quiz_session_notifier.dart';
import 'fill_blank_question_card.dart';
import 'listening_question_card.dart';
import 'quiz_feedback_panel.dart';
import 'quiz_fill_blank_options.dart';
import 'quiz_option_tile.dart';
import 'quiz_progress_bar.dart';
import 'quiz_question_card.dart';
import 'quiz_session_hud.dart';

class QuizActiveView extends ConsumerWidget {
  final String quizId;
  final QuizModel quiz;
  final QuizSessionState state;
  final QuizQuestion question;
  final ValueChanged<int> onSelectAnswer;
  final VoidCallback onContinue;

  const QuizActiveView({
    super.key,
    required this.quizId,
    required this.quiz,
    required this.state,
    required this.question,
    required this.onSelectAnswer,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalQuestions = quiz.questions.length;
    final audioQuizzesEnabled = ref
        .watch(featureFlagsProvider)
        .audioQuizzesEnabled;
    final isListeningQuestion =
        audioQuizzesEnabled &&
        question.type == 'listen_meaning' &&
        question.audioUrl != null;
    final isFillBlank =
        !isListeningQuestion && question.type == 'fill_blank';
    final correctOptionOlChiki =
        question.correctIndex >= 0 &&
            question.correctIndex < question.optionsOlChiki.length
        ? question.optionsOlChiki[question.correctIndex]
        : '';
    final correctOptionLatin =
        question.correctIndex >= 0 &&
            question.correctIndex < question.optionsLatin.length
        ? question.optionsLatin[question.correctIndex]
        : correctOptionOlChiki;

    Widget buildQuestionArea() {
      if (isListeningQuestion) {
        final playback = ref.watch(playbackStateProvider);
        final playbackState = playback.valueOrNull;
        final isPlayingThisAudio =
            playbackState?.isPlaying == true &&
            playbackState?.current?.id == question.audioUrl;
        final isLoadingThisAudio =
            playbackState?.isLoading == true &&
            playbackState?.current?.id == question.audioUrl;
        return ListeningQuestionCard(
          question: question,
          isPlaying: isPlayingThisAudio,
          isLoading: isLoadingThisAudio,
          playbackError: playbackState?.error,
          onPlayTap: () {
            unawaited(
              ref
                  .read(playbackControllerProvider)
                  .playSingle(
                    id: question.audioUrl!,
                    contentKind: 'lesson',
                    contentId: quizId,
                    trackType: 'targetNormal',
                    languageCode: 'sat',
                  ),
            );
          },
          onStopTap: () {
            unawaited(ref.read(playbackControllerProvider).stop());
          },
        );
      }

      if (!isFillBlank) {
        final playback = ref.watch(playbackStateProvider);
        final playbackState = playback.valueOrNull;
        final hasAudio =
            question.audioUrl != null && question.audioUrl!.trim().isNotEmpty;
        final isPlayingThisAudio =
            hasAudio &&
            playbackState?.isPlaying == true &&
            playbackState?.current?.id == question.audioUrl;
        final isLoadingThisAudio =
            hasAudio &&
            playbackState?.isLoading == true &&
            playbackState?.current?.id == question.audioUrl;
        final manifest = ref.watch(activeLanguageManifestProvider);

        return QuizQuestionCard(
          question: question,
          fontFamily: manifest.primaryFontFamily,
          isPlaying: isPlayingThisAudio,
          isLoading: isLoadingThisAudio,
          onPlayAudio: hasAudio
              ? () {
                  if (isPlayingThisAudio) {
                    unawaited(ref.read(playbackControllerProvider).stop());
                  } else {
                    unawaited(
                      ref
                          .read(playbackControllerProvider)
                          .playSingle(
                            id: question.audioUrl!,
                            contentKind: 'quiz_question',
                            contentId: quizId,
                            trackType: 'targetNormal',
                            languageCode: 'sat',
                          ),
                    );
                  }
                }
              : null,
        );
      }

      return FillBlankQuestionCard(
        question: question,
        selectedAnswer: state.selectedAnswer,
        isAnswered: state.isAnswered,
      );
    }

    Widget buildOptionsArea() {
      if (!isFillBlank) {
        return Column(
          children: List.generate(
            question.optionsLatin.length,
            (index) => QuizOptionTile(
              index: index,
              currentQuestion: state.currentQuestion,
              question: question,
              isSelected: state.selectedAnswer == index,
              isAnswered: state.isAnswered,
              onTap: () => onSelectAnswer(index),
            ),
          ),
        );
      }

      return QuizFillBlankOptions(
        question: question,
        state: state,
        isDark: isDark,
        onSelect: onSelectAnswer,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close quiz',
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          quiz.title ?? AppLocalizations.of(context)!.quiz,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          QuizCountPill(current: state.currentQuestion + 1, total: totalQuestions),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                QuizProgressBar(
                  current: state.currentQuestion + 1,
                  total: totalQuestions,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                QuizSessionHud(state: state, isDark: isDark),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        buildQuestionArea(),
                        const SizedBox(height: 32),
                        buildOptionsArea(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineStatusBanner(),
          ),
        ],
      ),
      bottomNavigationBar: state.isAnswered
          ? QuizFeedbackPanel(
              isCorrect: state.selectedAnswer == question.correctIndex,
              correctOptionOlChiki: correctOptionOlChiki,
              correctOptionLatin: correctOptionLatin,
              explanation: question.explanation,
              onContinue: onContinue,
            )
          : null,
    );
  }
}
