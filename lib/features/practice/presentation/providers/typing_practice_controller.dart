import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/typing_practice_settings.dart';
import '../../domain/practice_scoring_rules.dart';
import '../../domain/typing_comparison.dart';

class TypingPracticeArgs {
  final String itemKey;
  final String target;
  final String latin;
  final String meaning;
  final String contentType;

  const TypingPracticeArgs({
    required this.itemKey,
    required this.target,
    required this.latin,
    required this.meaning,
    this.contentType = 'word',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingPracticeArgs &&
          runtimeType == other.runtimeType &&
          itemKey == other.itemKey &&
          target == other.target &&
          latin == other.latin &&
          meaning == other.meaning &&
          contentType == other.contentType;

  @override
  int get hashCode =>
      itemKey.hashCode ^
      target.hashCode ^
      latin.hashCode ^
      meaning.hashCode ^
      contentType.hashCode;
}

enum TypingPhase { idle, typing, complete, done }

class TypingPracticeState {
  final TypingPhase phase;
  final String typedSoFar;
  final int attemptsTotal;
  final int wrongAtPosition;
  final bool withHint;
  final bool hasAwardedStars;
  final bool needsDigits;

  const TypingPracticeState({
    required this.phase,
    required this.typedSoFar,
    required this.attemptsTotal,
    required this.wrongAtPosition,
    required this.withHint,
    this.hasAwardedStars = false,
    this.needsDigits = false,
  });

  TypingPracticeState copyWith({
    TypingPhase? phase,
    String? typedSoFar,
    int? attemptsTotal,
    int? wrongAtPosition,
    bool? withHint,
    bool? hasAwardedStars,
    bool? needsDigits,
  }) {
    return TypingPracticeState(
      phase: phase ?? this.phase,
      typedSoFar: typedSoFar ?? this.typedSoFar,
      attemptsTotal: attemptsTotal ?? this.attemptsTotal,
      wrongAtPosition: wrongAtPosition ?? this.wrongAtPosition,
      withHint: withHint ?? this.withHint,
      hasAwardedStars: hasAwardedStars ?? this.hasAwardedStars,
      needsDigits: needsDigits ?? this.needsDigits,
    );
  }
}

class TypingPracticeController
    extends AutoDisposeFamilyNotifier<TypingPracticeState, TypingPracticeArgs> {
  @override
  TypingPracticeState build(TypingPracticeArgs arg) {
    final hasDigits = arg.target.runes.any((r) =>
        (r >= 0x1C50 && r <= 0x1C59) || (r >= 0x30 && r <= 0x39));
    return TypingPracticeState(
      phase: TypingPhase.idle,
      typedSoFar: '',
      attemptsTotal: 0,
      wrongAtPosition: 0,
      withHint: false,
      hasAwardedStars: false,
      needsDigits: hasDigits,
    );
  }

  void startPractice() {
    state = state.copyWith(phase: TypingPhase.typing);
  }

  void appendChar(String char) {
    if (state.phase != TypingPhase.typing) return;

    if (!TypingComparison.isValidInputChar(char)) {
      return;
    }

    final newTyped = state.typedSoFar + char;
    final settings = ref.read(typingPracticeSettingsProvider);
    final comparison = TypingComparison.compareInput(
      newTyped,
      arg.target,
      lenientPunctuation: settings.lenientPunctuation,
    );

    if (comparison.mistakeAtIndex != null) {
      final newWrongAtPos = state.wrongAtPosition + 1;
      final newAttempts = state.attemptsTotal + 1;
      final bool showHint = newWrongAtPos >= 3;

      state = state.copyWith(
        attemptsTotal: newAttempts,
        wrongAtPosition: newWrongAtPos,
        withHint: state.withHint || showHint,
      );
    } else {
      state = state.copyWith(
        typedSoFar: newTyped,
        wrongAtPosition: 0,
      );

      if (comparison.isComplete) {
        _onComplete();
      }
    }
  }

  void deleteLastChar() {
    if (state.phase != TypingPhase.typing || state.typedSoFar.isEmpty) return;
    state = state.copyWith(
      typedSoFar: state.typedSoFar.substring(0, state.typedSoFar.length - 1),
      wrongAtPosition: 0,
    );
  }

  void revealAndContinue() {
    if (state.phase != TypingPhase.typing) return;
    state = state.copyWith(
      typedSoFar: arg.target,
      withHint: true,
    );
    _onComplete();
  }

  void tryAgain() {
    state = state.copyWith(
      phase: TypingPhase.idle,
      typedSoFar: '',
      attemptsTotal: 0,
      wrongAtPosition: 0,
      withHint: false,
    );
  }

  void markCelebrationDone() {
    if (state.phase == TypingPhase.complete) {
      state = state.copyWith(phase: TypingPhase.done);
    }
  }

  void _onComplete() {
    state = state.copyWith(phase: TypingPhase.complete);

    if (!state.hasAwardedStars) {
      state = state.copyWith(hasAwardedStars: true);

      ref.read(userStatsProvider.notifier).recordPracticeCompletion(
            contentId: arg.itemKey,
            contentType: arg.contentType,
            practiceMode: 'typing',
            attempts: state.attemptsTotal,
            withHint: state.withHint,
            starsAwarded: PracticeScoringRules.starsPerTypingCompletion,
          );
    }
  }
}

final typingPracticeControllerProvider = NotifierProvider.family
    .autoDispose<TypingPracticeController, TypingPracticeState, TypingPracticeArgs>(
  TypingPracticeController.new,
);
