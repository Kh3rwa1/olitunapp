# Ol Chiki Typing Practice

This document outlines the architecture, pedagogical rationale, user flow, and technical implementation of the active recall typing practice system in Olitun.

---

## 🧠 1. Pedagogical Pedigree & Rationale

Olitun incorporates active recall practice for vocabulary and sentence acquisition to bridge the gap between passive recognition and active production.

### A. Active Recall vs. Passive Reading
In typical language learning applications, learners spend their time tapping multiple-choice options or listening passively to audio. While valuable for initial exposure, this does not build retrieval strength. 
The typing practice system enforces **active recall**:
1. The target Ol Chiki word/sentence **vanishes completely** from the screen.
2. The Latin transliteration and the semantic meaning **remain visible** as a scaffolding guide.
3. The learner must actively retrieve the correct Ol Chiki characters from memory and type them in sequence using the custom on-screen keyboard.

### B. Star Economy & Quiz Parity
To establish high value and motivate learners to engage in active recall rather than passive listening, typing practice awards **5 stars** upon successful completion. This is equivalent to completing a full quiz, reflecting the increased cognitive effort required for sequential character retrieval.
* **Toggle enabled (`typingPracticeEnabled == true`):** The legacy "Listen and Earn 25 Stars" button is hidden. It is replaced by the **"Practice Typing"** CTA. Completing the typing practice awards **5 stars**.
* **Toggle disabled (`typingPracticeEnabled == false`):** The legacy "Listen and Earn 25 Stars" button is restored, and the typing practice CTA is hidden.

---

## 🔒 2. Scope & Cultural Boundaries (Defensive Isolation)

A core tenet of Olitun is respect for the Santali language and culture. The typing practice feature is strictly scoped to prevent inappropriate exposure or cognitive friction.

| Content Type | Eligible? | Practice Mode | Rationale |
|---|---|---|---|
| **Vowel / Consonant (Letter)** | ❌ No | Tracing / Reading | Isolated letters require stroke-order muscle memory, not lexical retrieval. |
| **Number** | ❌ No | Tracing / Reading | Same as letters; tracing is more pedagogically appropriate. |
| **Word** |  Yes | Active Recall Typing | Words build orthographic retrieval and lexical mapping. |
| **Sentence** |  Yes | Active Recall Typing | Sentences reinforce syllable sequencing and syntax structure. |
| **Rhyme / Bakhed** | ❌ No | Listening-Only | **Sacred and traditional Santali invocations.** Forcing a user to type out sacred mantras on a keyboard is culturally inappropriate and ruins the contemplative listening flow. |

### 🛡️ Defensive Guarding
The eligibility check in `LessonBlockDetailScreen` is defensively guarded using a belt-and-suspenders combination:
```dart
final bool isEligible = settings.enabled &&
    (block.type == 'word' || block.type == 'sentence') &&
    block.type != 'rhyme' &&
    block.type != 'rhymes' &&
    block.textOlChiki != null &&
    block.textOlChiki!.isNotEmpty &&
    block.textOlChiki!.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F);
```
Even if future developers add new block types to lessons, the whitelist (`block.type == 'word' || block.type == 'sentence'`) and the explicit blacklist (`block.type != 'rhyme'`) prevent typing practice from ever leaking into sacred bakhed or rhyme-adjacent content.

---

## ⌨️ 3. Ol Chiki On-Screen Keyboard Design

Mobile system keyboards do not natively support the Ol Chiki Unicode range (`U+1C50` to `U+1C7F`) consistently across operating systems without custom layout installations. To provide a premium, zero-friction, cross-platform experience, Olitun implements a fully customized on-screen virtual keyboard (`OlChikiKeyboard`).

```mermaid
grid
    Row 1: [Vowels]  --> ᱚ  ᱮ  ᱤ  ᱩ  ᱳ  ᱳ
    Row 2: [Group 1] --> ᱛ  ᱜ  ᱞ  ᱟ  ᱠ  ᱡ
    Row 3: [Group 2] --> ᱢ  ᱣ  ᱧ  ᱦ  ᱧ  ᱨ
    Row 4: [Group 5] --> [Digits (Shown dynamically only if text contains numbers)]
```

### A. Layout Structure
* **Top Row (Vowels):** Vowels are highly frequent in Ol Chiki syllables and are grouped together on the first row for easy access.
* **Middle & Bottom Rows (Consonant Groups):** Arranged in standard groups of six characters corresponding to the traditional phonetic categorization of Ol Chiki.
* **Dynamic Digit Row (`᱐–᱙`):** Digits are dynamically displayed using an `AnimatedSize` or `AnimatedCrossFade` transition **only** if the target text contains digits. This preserves 60-80px of vertical viewport space for the 95% of vocabulary and sentences that do not require numbers.

### B. Suppressing System Keyboard
To present a natural input cursor without bringing up the native OS keyboard, we use a standard `TextField` but suppress keyboard instantiation:
```dart
TextField(
  readOnly: true,
  showCursor: true,
  enableInteractiveSelection: false,
  focusNode: FocusNode()..canRequestFocus = false,
)
```
Taps on virtual keys programmatically mutate the `TextEditingController` text and selection offset.

---

## 📊 4. Gamification & Streak-Idempotency Contract

Completed practice sessions are wired directly into progress systems to update stats and analytics.

### A. Streak Protection
To prevent gamification abuse (e.g., a user repeating the same simple word 10 times to inflate their streak), the streak calculation is **idempotent per calendar day**:
* Every completion triggers `recordPracticeCompletion()`.
* This updates the total stars and triggers `LearningAnalyticsEvents.practiceCompleted`.
* When updating user stats, the database logic verifies if `lastActiveDate == today` before incrementing the daily streak counter. Multiple completions in a single day reward stars but increment the streak exactly once.

### B. Dual-Entry-Point Integration
Words and sentences can be reached through two entry points:
1. **Lesson Explorer:** (`LessonBlockDetailScreen`) - Tapping a block inside a structured course lesson.
2. **Search / Category List:** (`ContentDetailScreen`) - Navigating directly to a vocabulary word or sentence from search or category browse grids.

Both screens leverage the identical `TypingPracticePanel` component, sharing the exact same Riverpod controller state, a11y announcements, and star rewards, ensuring a cohesive and unified user experience.

---

## ♿ 5. Accessibility (a11y) & Performance (perf) Guidelines

### A. Screen Reader (TalkBack & VoiceOver) Support
* Every virtual keyboard key features explicit `Semantics(label: 'Ol Chiki letter LA', hint: 'Double-tap to type')` utilizing the official Unicode character names (e.g., `LA`, `EL`, `OT`) instead of raw Unicode symbols.
* Digit keys are announced as `"Ol Chiki digit five"`.
* State changes and validation results are explicitly announced imperatively via `SemanticsService.announce`:
  * Correct character typed: `"Letter accepted"`
  * Incorrect character typed: `"Incorrect, try again"` (coinciding with the 8px horizontal shake)
  * Character deleted: `"Letter deleted"`
  * Completion: `"Practice complete, 5 stars earned"`

### B. Keystroke Performance Pass
To prevent keystroke lag and guarantee a solid 60fps on lower-end Android and iOS devices:
1. **Riverpod Selective Watching:** The parent keyboard does not watch `typedSoFar` or `attemptsTotal`. It uses `ref.watch(controller.select((s) => s.needsDigits))` to monitor layout shifts. Key presses only update the text controller, preventing massive rebuild cascades across 30+ virtual key widgets.
2. **Repaint Boundaries:** The `OlChikiKeyboard` is wrapped inside a `RepaintBoundary` to isolate the keyboard redraw layer from the active custom-paint confetti animations and input card shakes.
3. **Animation Disposal:** The peak confetti `_ConfettiPainter` disposes of its `AnimationController` within a strict 1500ms window to prevent frame budget leaks.
