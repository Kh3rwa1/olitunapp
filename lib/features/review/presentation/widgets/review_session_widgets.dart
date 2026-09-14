import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../review_exercise.dart';
import '../review_keyboard.dart';

class ReviewProgressBar extends StatelessWidget {
  final double value;
  const ReviewProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

class ReviewPromptCard extends StatelessWidget {
  final ReviewCard card;
  final bool isDark;
  final Future<void> Function(String url) onPlay;

  const ReviewPromptCard({
    super.key,
    required this.card,
    required this.isDark,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = card.kind == ReviewPromptKind.audioToMeaning;
    final isTyping = card.kind.isTyping;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.quizDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Text(
            isListening
                ? l10n.reviewRepromptListen
                : isTyping
                ? l10n.reviewRepromptWrite
                : l10n.reviewRepromptMeaning,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (isListening)
            IconButton.filled(
              onPressed: () => onPlay(card.audioUrl),
              icon: const Icon(Icons.volume_up_rounded, size: 36),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
            )
          else if (isTyping)
            Text(
              card.promptMeaning,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.webInk,
              ),
            )
          else
            Text(
              card.promptOlChiki,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'OlChiki',
                fontSize: 44,
                height: 1.2,
                color: isDark ? Colors.white : AppColors.webInk,
              ),
            ),
          if (!isListening && card.promptLatin.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              card.promptLatin,
              style: TextStyle(
                fontSize: 14,
                fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                color: isDark ? Colors.white54 : AppColors.webSlate,
              ),
            ),
          ],
          // One play control per card: the big button for listening cards,
          // a compact replay for audio-typing cards (replay after answering
          // lives in the feedback card).
          if (isTyping && card.audioUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => onPlay(card.audioUrl),
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: Text(l10n.reviewPlayAudio),
            ),
          ],
        ],
      ),
    );
  }
}

class ReviewOptionsArea extends StatelessWidget {
  final ReviewCard card;
  final int? selected;
  final bool answered;
  final bool isDark;
  final void Function(int index) onSelect;

  const ReviewOptionsArea({
    super.key,
    required this.card,
    required this.selected,
    required this.answered,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < card.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ReviewOptionButton(
              text: card.options[i],
              state: !answered
                  ? ReviewOptionState.idle
                  : i == card.correctOptionIndex
                  ? ReviewOptionState.correct
                  : i == selected
                  ? ReviewOptionState.wrong
                  : ReviewOptionState.dimmed,
              isDark: isDark,
              onTap: () => onSelect(i),
            ),
          ),
      ],
    );
  }
}

enum ReviewOptionState { idle, correct, wrong, dimmed }

class ReviewOptionButton extends StatelessWidget {
  final String text;
  final ReviewOptionState state;
  final bool isDark;
  final VoidCallback onTap;

  const ReviewOptionButton({
    super.key,
    required this.text,
    required this.state,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      ReviewOptionState.correct => AppColors.primary.withValues(alpha: 0.14),
      ReviewOptionState.wrong => Colors.red.withValues(alpha: 0.10),
      ReviewOptionState.dimmed => Colors.transparent,
      ReviewOptionState.idle =>
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
    };
    final border = switch (state) {
      ReviewOptionState.correct => AppColors.primary,
      ReviewOptionState.wrong => Colors.red,
      _ => AppColors.primary.withValues(alpha: 0.18),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: state == ReviewOptionState.idle ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.webInk,
                  ),
                ),
              ),
              if (state == ReviewOptionState.correct)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
              if (state == ReviewOptionState.wrong)
                const Icon(Icons.cancel_rounded, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewTypingArea extends StatelessWidget {
  final ReviewCard card;
  final String typed;
  final bool answered;
  final bool wasCorrect;
  final bool isDark;
  final void Function(String char) onKey;
  final VoidCallback onDelete;
  final Future<void> Function() onSubmit;

  const ReviewTypingArea({
    super.key,
    required this.card,
    required this.typed,
    required this.answered,
    required this.wasCorrect,
    required this.isDark,
    required this.onKey,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final needsDigits = card.expectedTyping.runes.any(
      (r) => (r >= 0x1C50 && r <= 0x1C59) || (r >= 0x30 && r <= 0x39),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.quizDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: answered
                  ? (wasCorrect ? AppColors.primary : Colors.red)
                  : AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Text(
            typed.isEmpty ? 'ᱚᱞ ᱛᱚᱵᱚᱱ ᱢᱮ …' : typed,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OlChiki',
              fontSize: 30,
              color: typed.isEmpty
                  ? (isDark ? Colors.white30 : Colors.black26)
                  : (isDark ? Colors.white : AppColors.webInk),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!answered) ...[
          ReviewKeyboard(
            onKey: onKey,
            onDelete: onDelete,
            showDigits: needsDigits,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: typed.trim().isEmpty ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.reviewCheck,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ReviewFeedbackCard extends StatelessWidget {
  final ReviewCard card;
  final bool wasCorrect;
  final bool isDark;
  final VoidCallback onReplay;
  final bool showReplay;

  const ReviewFeedbackCard({
    super.key,
    required this.card,
    required this.wasCorrect,
    required this.isDark,
    required this.onReplay,
    required this.showReplay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final correctAnswer = card.kind.isTyping
        ? card.expectedTyping
        : card.options[card.correctOptionIndex];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: wasCorrect
            ? AppColors.primary.withValues(alpha: 0.10)
            : Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: wasCorrect
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.amber.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wasCorrect
                    ? Icons.check_circle_rounded
                    : Icons.lightbulb_rounded,
                color: wasCorrect ? AppColors.primary : Colors.amber.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wasCorrect
                      ? l10n.reviewCorrectFeedback
                      : l10n.reviewWrongFeedback,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (showReplay)
                IconButton(
                  onPressed: onReplay,
                  icon: const Icon(Icons.volume_up_rounded),
                  tooltip: l10n.reviewReplayAudio,
                ),
            ],
          ),
          if (!wasCorrect) ...[
            const SizedBox(height: 8),
            Text(
              l10n.reviewCorrectAnswer(correctAnswer),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: card.kind.isTyping ? 'OlChiki' : null,
                color: isDark ? Colors.white : AppColors.webInk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _hintFor(context, card),
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? Colors.white70 : AppColors.webSlate,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Brief, content-grounded explanation — one short line, never praise.
  String _hintFor(BuildContext context, ReviewCard card) {
    final l10n = AppLocalizations.of(context)!;
    if (card.kind.isTyping) {
      return l10n.reviewHintTyping;
    }
    if (card.kind == ReviewPromptKind.audioToMeaning) {
      return l10n.reviewHintListening;
    }
    return l10n.reviewHintRecognition;
  }
}
