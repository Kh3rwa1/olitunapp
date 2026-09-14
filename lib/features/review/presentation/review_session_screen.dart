// Today's Review session: retrieval practice across lessons.
//
// NOT "redo the last lesson" — the queue is scheduler-selected due items
// from the whole corpus, ordered by need (overdue → most-failed → hardest).
// Exercise mix comes from [ReviewExerciseBuilder] (recognition, listening,
// typing). Typing is the production mechanism; there is no speech
// recognition and no Bodhan credit consumption.
//
// Error recovery (supportive, never punitive):
// 1. clearly show the correct answer, 2. replay audio when relevant,
// 3. brief explanation, 4. one-tap continue (no hearts blocking practice),
// 5. the scheduler brings the item back sooner.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/text_match.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/providers/content_providers.dart';
import '../../../shared/providers/learner_content_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../quiz/presentation/providers/mistake_provider.dart';
import '../data/review_store.dart';
import '../domain/review_item.dart';
import 'review_exercise.dart';
import 'review_queue_provider.dart';
import 'widgets/review_session_states.dart';
import 'widgets/review_session_widgets.dart';

/// Retention reward: mastering an item through repeated retrieval earns
/// more than tapping through a screen. (Completion stars were cut to 5 in
/// ContentDetailScreen; the real reward moved here.)
const int starsPerItemMastered = 10;

class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  List<ReviewCard> _cards = [];
  bool _loaded = false;
  bool _started = false;
  bool _loadError = false;
  int _dueTotal = 0;
  int _index = 0;

  int? _selectedOption;
  String _typed = '';
  bool _answered = false;
  bool _wasCorrect = false;
  DateTime _cardStartedAt = DateTime.now();

  int _correctCount = 0;
  int _masteredCount = 0;
  DateTime? _sessionStartedAt;
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStart());
  }

  /// Starts the session once the corpus is available. On offline cold start
  /// the word/sentence providers may still be loading — snapshotting then
  /// would resolve zero cards and show a FAKE "caught up". So: wait for
  /// load, and surface an honest error (with retry) when content fails.
  void _tryStart() {
    if (_started || !mounted) return;
    final words = ref.read(learnerWordsProvider);
    final sentences = ref.read(learnerSentencesProvider);
    if (words.isLoading || sentences.isLoading) return;
    _started = true;
    // ignore: discarded_futures
    _startSession();
  }

  void _retryLoad() {
    ref.invalidate(contentListProvider((ContentKind.word, null)));
    ref.invalidate(contentListProvider((ContentKind.sentence, null)));
    setState(() {
      _started = false;
      _loaded = false;
      _loadError = false;
    });
    _tryStart();
  }

  Future<void> _startSession() async {
    // Personalized: scheduler urgency re-ranked by onboarding profile.
    final due = ref.read(personalizedDueItemsProvider);
    final wordsAsync = ref.read(learnerWordsProvider);
    final sentencesAsync = ref.read(learnerSentencesProvider);
    final words = wordsAsync.valueOrNull ?? [];
    final sentences = sentencesAsync.valueOrNull ?? [];
    final cards = ReviewExerciseBuilder.buildCards(
      due: due,
      words: words,
      sentences: sentences,
    );
    if (!mounted) return;
    // Corpus failed AND items are due: honest error, never fake caught-up.
    // (Due empty + corpus empty = genuinely nothing to do.)
    final corpusFailed = wordsAsync.hasError || sentencesAsync.hasError;
    if (cards.isEmpty && due.isNotEmpty && corpusFailed) {
      setState(() {
        _loaded = true;
        _loadError = true;
        _dueTotal = due.length;
      });
      return;
    }
    setState(() {
      _cards = cards;
      _loaded = true;
      _dueTotal = due.length;
      _cardStartedAt = DateTime.now();
    });
    _sessionStartedAt = DateTime.now();
    _sessionId = '${DateTime.now().millisecondsSinceEpoch}';
    if (cards.isNotEmpty) {
      await _track(LearningAnalyticsEvents.reviewStarted, {
        'dueTotal': due.length,
        'cardCount': cards.length,
      });
      await _presentCurrent();
    }
  }

  ReviewCard? get _current =>
      (_index >= 0 && _index < _cards.length) ? _cards[_index] : null;

  Future<void> _track(
    String event, [
    Map<String, dynamic> metadata = const {},
  ]) {
    return ref
        .read(learningAnalyticsServiceProvider)
        .track(
          event,
          source: 'today_review',
          sourceId: _sessionId,
          metadata: metadata,
        );
  }

  Future<void> _presentCurrent() {
    final card = _current;
    if (card == null) return Future.value();
    if (card.kind.isTyping) {
      return _track(LearningAnalyticsEvents.typingStarted, {
        'itemId': card.itemId,
        'itemType': card.itemType.name,
      });
    }
    return _track(LearningAnalyticsEvents.reviewItemPresented, {
      'itemId': card.itemId,
      'itemType': card.itemType.name,
      'exercise': card.kind.name,
      'position': _index + 1,
      'total': _cards.length,
    });
  }

  Future<void> _playAudio(String url) async {
    if (url.trim().isEmpty) return;
    try {
      await ref.read(audioServiceProvider).playUrl(url.trim());
    } catch (_) {
      // Audio must never break review.
    }
  }

  Future<void> _submitMcq(int selected) async {
    if (_answered) return;
    final card = _current;
    if (card == null) return;
    final correct = selected == card.correctOptionIndex;
    setState(() {
      _selectedOption = selected;
      _answered = true;
      _wasCorrect = correct;
    });
    await _recordResult(card: card, correct: correct);
  }

  Future<void> _submitTyping() async {
    if (_answered) return;
    final card = _current;
    if (card == null || _typed.trim().isEmpty) return;
    final correct = isTextMatch(_typed.trim(), card.expectedTyping.trim());
    setState(() {
      _answered = true;
      _wasCorrect = correct;
    });
    await _track(
      correct
          ? LearningAnalyticsEvents.typingCorrect
          : LearningAnalyticsEvents.typingWrong,
      {'itemId': card.itemId, 'attempts': 1},
    );
    await _recordResult(card: card, correct: correct);
  }

  Future<void> _recordResult({
    required ReviewCard card,
    required bool correct,
  }) async {
    final responseMs = DateTime.now().difference(_cardStartedAt).inMilliseconds;
    final result = await ref
        .read(reviewStoreProvider.notifier)
        .recordRecall(
          itemId: card.itemId,
          itemType: card.itemType,
          correct: correct,
          exerciseType: card.exerciseType,
          responseTimeMs: responseMs,
        );
    if (correct) {
      _correctCount++;
      unawaited(
        ref.read(mistakeProvider.notifier).reconcileRecoveredItem(card.itemId),
      );
      await _track(LearningAnalyticsEvents.reviewCorrect, {
        'itemId': card.itemId,
        'exercise': card.kind.name,
        'responseTimeMs': responseMs,
      });
    } else {
      await _track(LearningAnalyticsEvents.reviewWrong, {
        'itemId': card.itemId,
        'exercise': card.kind.name,
        'responseTimeMs': responseMs,
      });
    }
    await _track(LearningAnalyticsEvents.itemRescheduled, {
      'itemId': card.itemId,
      'correct': correct,
      'nextReviewAt': result.state.nextReviewAt.toIso8601String(),
      'intervalDays': result.state.intervalDays,
      'mastery': result.state.masteryState.json,
      // Cohort fields for retention analysis (D1/D7/D30 joins, lapsed
      // mastered items, per-item accuracy).
      'successfulRecalls': result.state.successfulRecalls,
      'failedRecalls': result.state.failedRecalls,
      'lapseCount': result.state.lapseCount,
      if (result.state.firstRecallAt != null)
        'firstRecallAt': result.state.firstRecallAt!.toIso8601String(),
    });
    if (result.becameReview) {
      await _track(LearningAnalyticsEvents.itemPromoted, {
        'itemId': card.itemId,
        'toMastery': result.state.masteryState.json,
        'successfulRecalls': result.state.successfulRecalls,
      });
    }
    if (result.becameMastered) {
      _masteredCount++;
      unawaited(
        ref.read(mistakeProvider.notifier).reconcileRecoveredItem(card.itemId),
      );
      await ref.read(userStatsProvider.notifier).addStars(starsPerItemMastered);
      await _track(LearningAnalyticsEvents.itemMastered, {
        'itemId': card.itemId,
        'itemType': card.itemType.name,
        'successfulRecalls': result.state.successfulRecalls,
        'starsAwarded': starsPerItemMastered,
      });
    }
  }

  Future<void> _next() async {
    if (_index + 1 >= _cards.length) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
      _typed = '';
      _answered = false;
      _wasCorrect = false;
      _cardStartedAt = DateTime.now();
    });
    final card = _current;
    if (card != null &&
        (card.kind == ReviewPromptKind.audioToMeaning ||
            card.kind == ReviewPromptKind.audioToTyping)) {
      await _playAudio(card.audioUrl);
    }
    await _presentCurrent();
  }

  Future<void> _finish() async {
    final minutes = _sessionStartedAt == null
        ? 0
        : DateTime.now().difference(_sessionStartedAt!).inMinutes;
    await _track(LearningAnalyticsEvents.reviewCompleted, {
      'cardCount': _cards.length,
      'correct': _correctCount,
      'mastered': _masteredCount,
      'minutes': minutes,
    });
    if (!mounted) return;
    setState(() => _index = _cards.length);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    // Corpus may land after first frame (offline cold start): start then.
    ref.listen(learnerWordsProvider, (_, _) => _tryStart());
    ref.listen(learnerSentencesProvider, (_, _) => _tryStart());
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.reviewExit,
          onPressed: () => context.pop(),
        ),
        title: Text(
          _finished
              ? l10n.reviewComplete
              : _cards.isEmpty
              ? l10n.reviewSessionTitleBare
              : l10n.reviewSessionTitle(_index + 1, _cards.length),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody(isDark)),
    );
  }

  bool get _finished => _loaded && _index >= _cards.length;

  Widget _buildBody(bool isDark) {
    if (!_loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_loadError) {
      return ReviewLoadErrorView(
        dueTotal: _dueTotal,
        isDark: isDark,
        onRetry: _retryLoad,
        onBackHome: () => context.pop(),
      );
    }
    if (_cards.isEmpty) {
      return ReviewCaughtUpView(
        isDark: isDark,
        onBackHome: () => context.pop(),
      );
    }
    if (_finished) {
      return ReviewSummaryView(
        correctCount: _correctCount,
        totalCount: _cards.length,
        masteredCount: _masteredCount,
        starsAwarded: _masteredCount * starsPerItemMastered,
        isDark: isDark,
        onDone: () => context.pop(),
      );
    }
    final card = _current!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReviewProgressBar(value: (_index + 1) / _cards.length),
          const SizedBox(height: 20),
          ReviewPromptCard(card: card, isDark: isDark, onPlay: _playAudio),
          const SizedBox(height: 20),
          if (card.kind.isTyping)
            ReviewTypingArea(
              card: card,
              typed: _typed,
              answered: _answered,
              wasCorrect: _wasCorrect,
              isDark: isDark,
              onKey: (c) => setState(() => _typed += c),
              onDelete: () => setState(() {
                if (_typed.isNotEmpty) {
                  _typed = _typed.substring(0, _typed.length - 1);
                }
              }),
              onSubmit: _submitTyping,
            )
          else
            ReviewOptionsArea(
              card: card,
              selected: _selectedOption,
              answered: _answered,
              isDark: isDark,
              onSelect: _submitMcq,
            ),
          if (_answered) ...[
            const SizedBox(height: 16),
            ReviewFeedbackCard(
              card: card,
              wasCorrect: _wasCorrect,
              isDark: isDark,
              onReplay: () =>
                  _playAudio(card.audioUrl.isNotEmpty ? card.audioUrl : ''),
              showReplay: card.audioUrl.isNotEmpty,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _index + 1 >= _cards.length
                      ? AppLocalizations.of(context)!.reviewFinish
                      : AppLocalizations.of(context)!.continueButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
