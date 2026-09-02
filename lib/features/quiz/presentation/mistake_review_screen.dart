import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/copy/kudos_messages.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../presentation/providers/mistake_provider.dart';
import '../presentation/widgets/quiz_option_tile.dart';
import '../presentation/widgets/quiz_feedback_panel.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import '../../../features/profile/presentation/providers/user_stats_provider.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';

class MistakeReviewScreen extends ConsumerStatefulWidget {
  const MistakeReviewScreen({super.key});

  @override
  ConsumerState<MistakeReviewScreen> createState() =>
      _MistakeReviewScreenState();
}

class _MistakeReviewScreenState extends ConsumerState<MistakeReviewScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  int _masteredThisSession = 0;
  bool _isComplete = false;
  final List<MistakeItem> _sessionMistakes = [];
  final List<MistakeItem> _masteredMistakes = [];

  @override
  Widget build(BuildContext context) {
    final mistakes = ref.watch(mistakeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_sessionMistakes.isEmpty && mistakes.isNotEmpty && !_isComplete) {
      _sessionMistakes.addAll(mistakes);
    }
    final reviewMistakes = _sessionMistakes.isNotEmpty
        ? _sessionMistakes
        : mistakes;

    if (reviewMistakes.isEmpty && !_isComplete) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
            tooltip: 'Go back',
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Mistake Review',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        bottomNavigationBar: const BannerAdWidget(
          placement: 'mistake_review_bottom',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 48)),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  'All caught up!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No mistakes need review. Your Santali roots are strong!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                const RepaintBoundary(
                  child: NativeAdWidget(
                    placement: 'mistake_review_empty_native',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isComplete) {
      final l10n = AppLocalizations.of(context)!;
      final kudos = KudosMessages.getRandomKudos([
        l10n.kudosMistake1,
        l10n.kudosMistake2,
        l10n.kudosMistake3,
        l10n.kudosMistake4,
      ]);
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        bottomNavigationBar: const BannerAdWidget(
          placement: 'mistake_review_bottom',
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.success,
                      size: 64,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 32),
                  Text(
                    'Mistakes Mastered!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      kudos,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Mastered', '$_masteredThisSession'),
                        _buildStat(
                          'Bonus Stars',
                          '+${_masteredThisSession * 3}',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),
                  const RepaintBoundary(
                    child: NativeAdWidget(
                      placement: 'mistake_review_complete_native',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentMistake =
        reviewMistakes[_currentIndex.clamp(0, reviewMistakes.length - 1)];
    final question = currentMistake.question;

    return Scaffold(
      backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          tooltip: 'Close review',
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Mistake Review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${reviewMistakes.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / reviewMistakes.length,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Question Card
                    Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.quizDarkCard
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.05,
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                question.promptOlChiki,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'OlChiki',
                                ),
                              ),
                              if (question.promptLatin != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  question.promptLatin!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.96, 0.96)),
                    const SizedBox(height: 32),
                    // Options list
                    Column(
                      children: List.generate(
                        question.optionsLatin.length,
                        (index) => QuizOptionTile(
                          index: index,
                          currentQuestion: _currentIndex,
                          question: question,
                          isSelected: _selectedAnswer == index,
                          isAnswered: _isAnswered,
                          onTap: () {
                            if (_isAnswered) return;
                            setState(() {
                              _selectedAnswer = index;
                              _isAnswered = true;
                              final isCorrect = index == question.correctIndex;
                              if (isCorrect) {
                                _masteredThisSession++;
                                if (!_masteredMistakes.any(
                                  (item) =>
                                      item.quizId == currentMistake.quizId &&
                                      item.questionId ==
                                          currentMistake.questionId,
                                )) {
                                  _masteredMistakes.add(currentMistake);
                                }
                                HapticFeedback.lightImpact();
                                ref
                                    .read(mistakeProvider.notifier)
                                    .masterMistake(
                                      quizId: currentMistake.quizId,
                                      questionIndex:
                                          currentMistake.questionIndex,
                                    );
                              } else {
                                HapticFeedback.mediumImpact();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isAnswered
          ? QuizFeedbackPanel(
              isCorrect: _selectedAnswer == question.correctIndex,
              correctOptionOlChiki:
                  question.optionsOlChiki[question.correctIndex],
              correctOptionLatin: question.optionsLatin[question.correctIndex],
              explanation: question.explanation,
              onContinue: () {
                if (_currentIndex < reviewMistakes.length - 1) {
                  setState(() {
                    _currentIndex++;
                    _selectedAnswer = null;
                    _isAnswered = false;
                  });
                } else {
                  HapticFeedback.mediumImpact();
                  // Grant the advertised mistake-review bonus: the summary
                  // card promises +3 stars per mastered question — this is
                  // the single grant site so it can never double-pay.
                  unawaited(
                    ref
                        .read(userStatsProvider.notifier)
                        .addStars(_masteredThisSession * 3),
                  );
                  unawaited(
                    ref
                        .read(mistakeProvider.notifier)
                        .completeReviewSession(
                          score: _masteredThisSession,
                          total: _sessionMistakes.length,
                          reviewedMistakes: List<MistakeItem>.from(
                            _sessionMistakes,
                          ),
                          masteredMistakes: List<MistakeItem>.from(
                            _masteredMistakes,
                          ),
                        ),
                  );
                  setState(() {
                    _isComplete = true;
                  });
                }
              },
            )
          : null,
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
