import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/languages/providers/target_language_provider.dart';
import '../../../../core/presentation/layout/responsive_layout.dart';
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

class QuizActiveView extends ConsumerStatefulWidget {
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
  ConsumerState<QuizActiveView> createState() => _QuizActiveViewState();
}

class _QuizActiveViewState extends ConsumerState<QuizActiveView> {
  int _focusedIndex = -1;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant QuizActiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentQuestion != widget.state.currentQuestion) {
      setState(() {
        _focusedIndex = -1;
      });
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  int get _numOptions {
    final isFillBlank = widget.question.type == 'fill_blank';
    return isFillBlank
        ? widget.question.optionsOlChiki.length
        : widget.question.optionsLatin.length;
  }

  void _focusNext() {
    final count = _numOptions;
    if (count <= 0) return;
    setState(() {
      _focusedIndex = (_focusedIndex + 1) % count;
    });
  }

  void _focusPrevious() {
    final count = _numOptions;
    if (count <= 0) return;
    setState(() {
      _focusedIndex = (_focusedIndex - 1 + count) % count;
    });
  }

  void _selectIndex(int index) {
    if (widget.state.isAnswered) return;
    if (index >= 0 && index < _numOptions) {
      setState(() => _focusedIndex = index);
      widget.onSelectAnswer(index);
    }
  }

  void _handleSubmitOrContinue() {
    if (widget.state.isAnswered) {
      widget.onContinue();
    } else if (_focusedIndex >= 0 && _focusedIndex < _numOptions) {
      widget.onSelectAnswer(_focusedIndex);
    }
  }

  void _toggleAudioPlayback() {
    final audioUrl = widget.question.audioUrl;
    if (audioUrl == null || audioUrl.trim().isEmpty) return;
    final playbackState = ref.read(playbackStateProvider).valueOrNull;
    final isPlaying =
        playbackState?.isPlaying == true &&
        playbackState?.current?.id == audioUrl;
    if (isPlaying) {
      unawaited(ref.read(playbackControllerProvider).stop());
    } else {
      final isListening = widget.question.type == 'listen_meaning';
      unawaited(
        ref
            .read(playbackControllerProvider)
            .playSingle(
              id: audioUrl,
              contentKind: isListening ? 'lesson' : 'quiz_question',
              contentId: widget.quizId,
              trackType: 'targetNormal',
              languageCode: 'sat',
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalQuestions = widget.quiz.questions.length;
    final audioQuizzesEnabled = ref
        .watch(featureFlagsProvider)
        .audioQuizzesEnabled;
    final isListeningQuestion =
        audioQuizzesEnabled &&
        widget.question.type == 'listen_meaning' &&
        widget.question.audioUrl != null;
    final isFillBlank =
        !isListeningQuestion && widget.question.type == 'fill_blank';
    final correctOptionOlChiki =
        widget.question.correctIndex >= 0 &&
            widget.question.correctIndex < widget.question.optionsOlChiki.length
        ? widget.question.optionsOlChiki[widget.question.correctIndex]
        : '';
    final correctOptionLatin =
        widget.question.correctIndex >= 0 &&
            widget.question.correctIndex < widget.question.optionsLatin.length
        ? widget.question.optionsLatin[widget.question.correctIndex]
        : correctOptionOlChiki;

    Widget buildQuestionArea() {
      if (isListeningQuestion) {
        final playback = ref.watch(playbackStateProvider);
        final playbackState = playback.valueOrNull;
        final isPlayingThisAudio =
            playbackState?.isPlaying == true &&
            playbackState?.current?.id == widget.question.audioUrl;
        final isLoadingThisAudio =
            playbackState?.isLoading == true &&
            playbackState?.current?.id == widget.question.audioUrl;
        return ListeningQuestionCard(
          question: widget.question,
          isPlaying: isPlayingThisAudio,
          isLoading: isLoadingThisAudio,
          playbackError: playbackState?.error,
          onPlayTap: () {
            unawaited(
              ref
                  .read(playbackControllerProvider)
                  .playSingle(
                    id: widget.question.audioUrl!,
                    contentKind: 'lesson',
                    contentId: widget.quizId,
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
            widget.question.audioUrl != null &&
            widget.question.audioUrl!.trim().isNotEmpty;
        final isPlayingThisAudio =
            hasAudio &&
            playbackState?.isPlaying == true &&
            playbackState?.current?.id == widget.question.audioUrl;
        final isLoadingThisAudio =
            hasAudio &&
            playbackState?.isLoading == true &&
            playbackState?.current?.id == widget.question.audioUrl;
        final manifest = ref.watch(activeLanguageManifestProvider);

        return QuizQuestionCard(
          question: widget.question,
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
                            id: widget.question.audioUrl!,
                            contentKind: 'quiz_question',
                            contentId: widget.quizId,
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
        question: widget.question,
        selectedAnswer: widget.state.selectedAnswer,
        isAnswered: widget.state.isAnswered,
      );
    }

    Widget buildOptionsArea() {
      if (!isFillBlank) {
        return Column(
          children: List.generate(
            widget.question.optionsLatin.length,
            (index) => QuizOptionTile(
              index: index,
              currentQuestion: widget.state.currentQuestion,
              question: widget.question,
              isSelected: widget.state.selectedAnswer == index,
              isAnswered: widget.state.isAnswered,
              isFocused: _focusedIndex == index,
              onTap: () => widget.onSelectAnswer(index),
            ),
          ),
        );
      }

      return QuizFillBlankOptions(
        question: widget.question,
        state: widget.state,
        isDark: isDark,
        focusedIndex: _focusedIndex,
        onSelect: widget.onSelectAnswer,
      );
    }

    final isDesktopWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.arrowDown): _focusNext,
      const SingleActivator(LogicalKeyboardKey.arrowRight): _focusNext,
      const SingleActivator(LogicalKeyboardKey.arrowUp): _focusPrevious,
      const SingleActivator(LogicalKeyboardKey.arrowLeft): _focusPrevious,
      const SingleActivator(LogicalKeyboardKey.digit1): () => _selectIndex(0),
      const SingleActivator(LogicalKeyboardKey.numpad1): () => _selectIndex(0),
      const SingleActivator(LogicalKeyboardKey.digit2): () => _selectIndex(1),
      const SingleActivator(LogicalKeyboardKey.numpad2): () => _selectIndex(1),
      const SingleActivator(LogicalKeyboardKey.digit3): () => _selectIndex(2),
      const SingleActivator(LogicalKeyboardKey.numpad3): () => _selectIndex(2),
      const SingleActivator(LogicalKeyboardKey.digit4): () => _selectIndex(3),
      const SingleActivator(LogicalKeyboardKey.numpad4): () => _selectIndex(3),
      const SingleActivator(LogicalKeyboardKey.enter): _handleSubmitOrContinue,
      const SingleActivator(LogicalKeyboardKey.numpadEnter):
          _handleSubmitOrContinue,
      const SingleActivator(LogicalKeyboardKey.space): () {
        if (widget.state.isAnswered) {
          widget.onContinue();
        } else {
          _toggleAudioPlayback();
        }
      },
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
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
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
            title: Text(
              widget.quiz.title ?? AppLocalizations.of(context)!.quiz,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              QuizCountPill(
                current: widget.state.currentQuestion + 1,
                total: totalQuestions,
              ),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayout.maxNarrowWidth(context),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        QuizProgressBar(
                          current: widget.state.currentQuestion + 1,
                          total: totalQuestions,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        QuizSessionHud(state: widget.state, isDark: isDark),
                        const SizedBox(height: 28),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                buildQuestionArea(),
                                const SizedBox(height: 32),
                                buildOptionsArea(),
                                if (isDesktopWeb &&
                                    !widget.state.isAnswered) ...[
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.quizKeyboardHintAlt,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
          bottomNavigationBar: widget.state.isAnswered
              ? QuizFeedbackPanel(
                  isCorrect:
                      widget.state.selectedAnswer ==
                      widget.question.correctIndex,
                  correctOptionOlChiki: correctOptionOlChiki,
                  correctOptionLatin: correctOptionLatin,
                  explanation: widget.question.explanation,
                  onContinue: widget.onContinue,
                )
              : null,
        ),
      ),
    );
  }
}
