// Config-driven learning path catalog (spec §15).
//
// The three proficiency-based paths live here as data — NOT inside UI
// widgets — so the sequence can evolve without touching any screen.
// Screens read from LearningPathCatalog.pathFor / the provider layer.

import '../../../shared/providers/language_settings_providers.dart'
    show SantaliProficiency;

/// One stage in a learning path.
class LearningPathStep {
  /// Stable step id (never localized; safe to persist against).
  final String id;

  /// Human-facing label (English for now; localization via l10n later).
  final String label;

  /// Category backing this step, when the stage maps to an existing
  /// content category. Null means the step is served by a dedicated
  /// surface (tracing, typing, listening quiz, stories) rather than a
  /// category lesson list.
  final String? categoryId;

  const LearningPathStep({
    required this.id,
    required this.label,
    this.categoryId,
  });
}

enum LearningPathKind { santaliSpeaker, nonSantaliBeginner, partialSpeaker }

class LearningPath {
  final LearningPathKind kind;
  final String title;
  final String description;
  final List<LearningPathStep> steps;

  const LearningPath({
    required this.kind,
    required this.title,
    required this.description,
    required this.steps,
  });

  /// First step that is backed by a category the learner can open today.
  LearningPathStep? get firstOpenableStep {
    for (final step in steps) {
      if (step.categoryId != null) return step;
    }
    return null;
  }
}

/// The catalog. Spec §15, verbatim path orders:
/// - Santali speaker: alphabet → sounds → tracing → words → spelling →
///   dictation → reading → typing → stories.
/// - Non-Santali beginner: greetings → introductions → yes/no → family →
///   numbers → food → home → school → nature → verbs → questions →
///   conversations → gradual Ol Chiki.
/// - Partial speaker: audio diagnostic → vocabulary review → Ol Chiki
///   character mapping → reading/writing progression.
class LearningPathCatalog {
  const LearningPathCatalog._();

  static const santaliSpeakerSteps = [
    LearningPathStep(
      id: 'ol_chiki_alphabet',
      label: 'Ol Chiki alphabet',
      categoryId: 'cat_alphabets',
    ),
    LearningPathStep(
      id: 'letter_sounds',
      label: 'Letter sounds',
      categoryId: 'cat_alphabets',
    ),
    LearningPathStep(id: 'tracing', label: 'Tracing'),
    LearningPathStep(
      id: 'word_recognition',
      label: 'Word recognition',
      categoryId: 'cat_vocab',
    ),
    LearningPathStep(
      id: 'spelling',
      label: 'Spelling',
      categoryId: 'cat_vocab',
    ),
    LearningPathStep(id: 'dictation', label: 'Dictation'),
    LearningPathStep(
      id: 'reading',
      label: 'Reading',
      categoryId: 'cat_sentences',
    ),
    LearningPathStep(id: 'typing', label: 'Typing'),
    LearningPathStep(id: 'stories', label: 'Stories'),
  ];

  static const nonSantaliBeginnerSteps = [
    LearningPathStep(
      id: 'greetings',
      label: 'Greetings',
      categoryId: 'cat_phrases',
    ),
    LearningPathStep(
      id: 'introductions',
      label: 'Introductions',
      categoryId: 'cat_phrases',
    ),
    LearningPathStep(
      id: 'yes_no_responses',
      label: 'Yes / No & basic responses',
      categoryId: 'cat_phrases',
    ),
    LearningPathStep(id: 'family', label: 'Family', categoryId: 'cat_vocab'),
    LearningPathStep(
      id: 'numbers',
      label: 'Numbers',
      categoryId: 'cat_numbers',
    ),
    LearningPathStep(id: 'food', label: 'Food', categoryId: 'cat_vocab'),
    LearningPathStep(id: 'home', label: 'Home', categoryId: 'cat_vocab'),
    LearningPathStep(
      id: 'school',
      label: 'School',
      categoryId: 'cat_sentences',
    ),
    LearningPathStep(id: 'nature', label: 'Nature', categoryId: 'cat_vocab'),
    LearningPathStep(
      id: 'common_verbs',
      label: 'Common verbs',
      categoryId: 'cat_vocab',
    ),
    LearningPathStep(
      id: 'everyday_questions',
      label: 'Everyday questions',
      categoryId: 'cat_sentences',
    ),
    LearningPathStep(
      id: 'short_conversations',
      label: 'Short conversations',
      categoryId: 'cat_sentences',
    ),
    LearningPathStep(
      id: 'gradual_ol_chiki',
      label: 'Gradual Ol Chiki introduction',
      categoryId: 'cat_alphabets',
    ),
  ];

  static const partialSpeakerSteps = [
    LearningPathStep(id: 'audio_diagnostic', label: 'Audio diagnostic'),
    LearningPathStep(
      id: 'vocabulary_review',
      label: 'Basic vocabulary review',
      categoryId: 'cat_vocab',
    ),
    LearningPathStep(
      id: 'ol_chiki_mapping',
      label: 'Ol Chiki character mapping',
      categoryId: 'cat_alphabets',
    ),
    LearningPathStep(
      id: 'reading_writing',
      label: 'Reading and writing progression',
      categoryId: 'cat_sentences',
    ),
  ];

  static const santaliSpeakerPath = LearningPath(
    kind: LearningPathKind.santaliSpeaker,
    title: 'Santali Speaker Path',
    description:
        'You already speak Santali — master the Ol Chiki script, then read, '
        'type, and enjoy stories.',
    steps: santaliSpeakerSteps,
  );

  static const nonSantaliBeginnerPath = LearningPath(
    kind: LearningPathKind.nonSantaliBeginner,
    title: 'Santali for Beginners',
    description:
        'Start listening and speaking with everyday phrases, then ease '
        'into Ol Chiki.',
    steps: nonSantaliBeginnerSteps,
  );

  static const partialSpeakerPath = LearningPath(
    kind: LearningPathKind.partialSpeaker,
    title: 'Bridge Path',
    description:
        'Check your level with a listening diagnostic, then map the sounds '
        'you know onto Ol Chiki.',
    steps: partialSpeakerSteps,
  );

  /// Proficiency-based selection (spec §15 + Phase 7 progression):
  /// - fluent speakers/readers → the Santali speaker path,
  /// - total newcomers → the non-Santali beginner path,
  /// - everyone in between (understands some, beginner reader) → the
  ///   partial-speaker bridge path.
  static LearningPath pathFor(SantaliProficiency proficiency) {
    switch (proficiency) {
      case SantaliProficiency.fluentSpeaker:
      case SantaliProficiency.fluentReader:
        return santaliSpeakerPath;
      case SantaliProficiency.understandsSome:
      case SantaliProficiency.beginnerReader:
        return partialSpeakerPath;
      case SantaliProficiency.none:
        return nonSantaliBeginnerPath;
    }
  }
}

/// Convenience top-level selector: proficiency → recommended path.
LearningPath learningPathFor(SantaliProficiency proficiency) =>
    LearningPathCatalog.pathFor(proficiency);

/// Top-level path handles (mirror the catalog constants).
const LearningPath santaliSpeakerPath = LearningPathCatalog.santaliSpeakerPath;
const LearningPath nonSantaliBeginnerPath =
    LearningPathCatalog.nonSantaliBeginnerPath;
const LearningPath partialSpeakerPath = LearningPathCatalog.partialSpeakerPath;

/// All catalog paths, in display order (for iteration/tests).
const kLearningPathCatalog = <LearningPath>[
  LearningPathCatalog.santaliSpeakerPath,
  LearningPathCatalog.nonSantaliBeginnerPath,
  LearningPathCatalog.partialSpeakerPath,
];
